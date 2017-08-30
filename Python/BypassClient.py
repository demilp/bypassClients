import json
import select
import socket
import threading
import time


class Event(object):
    """
    Generic event to use with EventDispatcher.
    """

    def __init__(self, event_type, data=None):
        """
        The constructor accepts an event type as string and a custom data
        """
        self._type = event_type
        self._data = data

    @property
    def type(self):
        """
        Returns the event type
        """
        return self._type

    @property
    def data(self):
        """
        Returns the data associated to the event
        """
        return self._data


class EventManager(object):
    """
    Generic event dispatcher which listen and dispatch events
    """

    def __init__(self):
        self._events = dict()

    def __del__(self):
        """
        Remove all listener references at destruction time
        """
        self._events = None

    def has_listener(self, event_type, listener):
        """
        Return true if listener is register to event_type
        """
        # Check for event type and for the listener
        if event_type in self._events.keys():
            return listener in self._events[event_type]
        else:
            return False

    def dispatch_event(self, event):
        """
        Dispatch an instance of Event class
        """
        # Dispatch the event to all the associated listeners
        if event.type in self._events.keys():
            listeners = self._events[event.type]

            for listener in listeners:
                listener(event)

    def add_event_listener(self, event_type, listener):
        """
        Add an event listener for an event type
        """
        # Add listener to the event type
        if not self.has_listener(event_type, listener):
            listeners = self._events.get(event_type, [])

            listeners.append(listener)

            self._events[event_type] = listeners

    def remove_event_listener(self, event_type, listener):
        """
        Remove event listener.
        """
        # Remove the listener from the event type
        if self.has_listener(event_type, listener):
            listeners = self._events[event_type]

            if len(listeners) == 1:
                # Only this listener remains so remove the key
                del self._events[event_type]

            else:
                # Update listeners chain
                listeners.remove(listener)

                self._events[event_type] = listeners


class TCPClientManager:
	ON_CONNECT = 'ON_CONNECT'
	ON_DISCONNECT = 'ON_DISCONNECT'
	ON_DATA = 'ON_DATA'

	def __init__(self):
		self._socket = None
		self._thread = None
		self._buffer = ''
		self.connected = False
		self._ip = ''
		self._port = 0
		self._command_separator = ''
		self._t_retry = 4
		self._run = False
		self._t = 0.0
		self._disconnect_test = ''
		self.ev_manager = EventManager()

	def __on_data(self, data):
		data = self._buffer + data
		commands = data.split(self._command_separator)
		self._buffer = commands[len(commands) - 1]
		for i in range(len(commands) - 1):
			if commands[i] == "":
				continue
			self.ev_manager.dispatch_event(Event(TCPClientManager.ON_DATA, commands[i]))

	def __client_loop(self):
		if self.connected:
			s = [self._socket]
			r, w, x = select.select(s, s, s)
			data = ''
			if self._socket in r:
				try:
					while self.connected and self._socket in r:
						part = self._socket.recv(1024).decode('UTF-8')
						data += part
						if part == '':
							self.connected = False
							self.ev_manager.dispatch_event(Event(TCPClientManager.ON_DISCONNECT))
							threading.Timer(self._t_retry, self.__retry_connection).start()
						r, w, x = select.select(s, s, s)
				except Exception as e:
					pass
				finally:
					if data:
						self.__on_data(data)

	def __update(self):
		self._t = time.time()
		while self._run:
			self.__client_loop()

	def __retry_connection(self):
		if not self.connected:
			self.initialize(self._ip, self._port)

	def initialize(self, ip, port, command_separator=';'):
		self._run = True
		if self._thread is None:
			self._thread = threading.Thread(target=self.__update)
			self._thread.start()
		self._disconnect_test = '0' + command_separator
		self._ip = ip
		self._port = port
		self._command_separator = command_separator
		self.connected = False
		try:
			self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
			self._socket.setblocking(1)
			self._socket.connect((self._ip, self._port))
			self._socket.setblocking(0)
			self.connected = True
			self.ev_manager.dispatch_event(Event(TCPClientManager.ON_CONNECT))
		except Exception as e:
			threading.Timer(self._t_retry, self.__retry_connection).start()

	def send_command(self, command):
		s = [self._socket]
		r, w, x = select.select(s, s, s)
		if self.connected and self._socket in w:
			command = command.replace(self._command_separator, ' ') + self._command_separator
			try:
				self._socket.send(command.encode())
			except Exception as e:
				print(e)

	def close(self):
		self._run = False
		self._socket.shutdown(socket.SHUT_RDWR)
		self._socket.close()
		self._socket = None
		self.ev_manager.dispatch_event(Event(TCPClientManager.ON_DISCONNECT))


class BypassClient(TCPClientManager):
	def register(self, id, tag='', need_sender_delimiter=''):
		self._id = id
		self._tag = tag
		data = {'type': 'register', 'data': id, 'tag': tag}
		self.send_command(json.dumps(data))
		if need_sender_delimiter != '':
			data = {'type': 'needSender', 'data': need_sender_delimiter, 'tag': ''}
			self.send_command(json.dumps(data))

	def _auto_register(self, ev):
		self.register(self._id, self._tag)

	def __init__(self, ip='', port=0, command_separator=';', id='', tag='', need_sender_delimiter=''):
		super(BypassClient, self).__init__()
		self._id = id
		self._tag = tag
		self._need_sender_delimiter = need_sender_delimiter
		self.ev_manager.add_event_listener(TCPClientManager.ON_CONNECT, self._auto_register)
		if ip != '' and port != 0:
			self.initialize(ip, port, command_separator)

	def send_data(self, data, tag, *ids):
		command = {"type": "send", "data": data, "tag": tag, "ids": list(ids)}
		self.send_command(json.dumps(command))

	def broadcast(self, data):
		command = {"type": "broadcast", "data": data, "tag": "", "ids": []}
		self.send_command(json.dumps(command))

	def broadcast_all(self, data):
		command = {"type": "broadcastAll", "data": data, "tag": "", "ids": []}
		self.send_command(json.dumps(command))
