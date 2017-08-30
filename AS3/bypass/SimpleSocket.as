package bypass
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	
	public class SimpleSocket 
	{
		//------------------------------------------------------------------------------------------------------------------------------------------------------------------
        //--------------------------------------------------------PUBLIC_MEMBERS--------------------------------------------------------------------------------------------
        //------------------------------------------------------------------------------------------------------------------------------------------------------------------

        //------------------------------------------------------------------------------------
        //PUBLIC_CLASS
        //------------------------------------------------------------------------------------

        //------------------------------------------------------------------------------------
        //PUBLIC_EVENTS
        //------------------------------------------------------------------------------------

        //------------------------------------------------------------------------------------
        //PUBLIC_VARS
        //------------------------------------------------------------------------------------
		
		public function get ip():String 
		{
			return _ip;
		}
		
		public function get port():int 
		{
			return _port;
		}
		
		public function get onData():Function 
		{
			return _onData;
		}
		
		/**
		 * onData , es la funcion que recibira los datos del socket. Debe ser del formato { function f( o:Object):void };
		 */
		public function set onData(value:Function):void 
		{
			_onData = value;
		}
		
		public function get onDisconnect():Function 
		{
			return _onDisconnect;
		}
		
		public function set onDisconnect(value:Function):void 
		{
			_onDisconnect = value;
		}
		
		public function get onConnect():Function 
		{
			return _onConnect;
		}
		
		public function set onConnect(value:Function):void 
		{
			_onConnect = value;
		}
		
		public function get connected():Boolean 
		{
			return _connected;
		}
		
        //------------------------------------------------------------------------------------
        //CONSTRUCTOR
        //------------------------------------------------------------------------------------

        public function SimpleSocket(pIp:String = "127.0.0.1", pPort:int=9000)
        {
			this._initialized = true;
			
            this._ip = pIp;
			this._port = pPort;
			this._startPort = pPort;
			
			this._socket = new Socket();
			//this._socket.addEventListener(Event.DEACTIVATE, close);
			//this._socket.addEventListener(Event.ACTIVATE, init);
			
			//init();
		}
		
		public function sendString( b:String ):void
		{
			if ( !_socket.connected ) return;
			
			try
			{
				_socket.writeUTFBytes( b );
				_socket.flush();
			}
			catch (e:Error)
			{
				trace( "SimpleSocket sendByte(int) b=" + b.toString() + " error=" + e.message);
			}
		}
		
		public function sendByte( b:int ):void
		{
			if ( !_socket.connected ) return;
			
			try
			{
				_socket.writeByte( b );
				_socket.flush();
			}
			catch (e:Error)
			{
				trace( "SimpleSocket sendByte(int) b=" + b.toString() + " error=" + e.message);
			}
		}
		
		public function sendByteArray( b:ByteArray ):void
		{
			if ( !_socket.connected ) return;
			
			try
			{
				_socket.writeBytes( b );
				_socket.flush();
			}
			catch (e:Error)
			{
				trace( "SimpleSocket sendByteArray(ByteArray) b=" + b.toString() + " error=" + e.message);
			}
		}
		
		public function init(param:*=null):void
		{
			if ( !this._socket.hasEventListener(Event.CONNECT) ) this._socket.addEventListener(Event.CONNECT, onSocketEventHandler);
			if ( !this._socket.hasEventListener(IOErrorEvent.IO_ERROR) ) this._socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			if ( !this._socket.hasEventListener(SecurityErrorEvent.SECURITY_ERROR) ) this._socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketEventHandler);
			if ( !this._socket.hasEventListener(Event.CLOSE) ) this._socket.addEventListener(Event.CLOSE, onSocketEventHandler);
			if ( !this._socket.hasEventListener(ProgressEvent.SOCKET_DATA) ) this._socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			_initialized = true;
			
			if ( !_socket.connected) 
				_socket.connect(_ip, _port);	
		}
		
		public function close(param:*=null):void
		{
			if ( this._socket.hasEventListener(Event.CONNECT) ) this._socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
			if ( this._socket.hasEventListener(IOErrorEvent.IO_ERROR) ) this._socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
			if ( this._socket.hasEventListener(SecurityErrorEvent.SECURITY_ERROR) ) this._socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketEventHandler);
			if ( this._socket.hasEventListener(Event.CLOSE) ) this._socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
			if ( this._socket.hasEventListener(ProgressEvent.SOCKET_DATA) ) this._socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
			
			if ( _socket.connected) 
				this._socket.close();
				
			_initialized = false;
		}
		
        //------------------------------------------------------------------------------------
        //PUBLIC_METHODS
        //------------------------------------------------------------------------------------

        //------------------------------------------------------------------------------------------------------------------------------------------------------------------
        //-------------------------------------------------------PRIVATE_MEMBERS--------------------------------------------------------------------------------------------
        //------------------------------------------------------------------------------------------------------------------------------------------------------------------

        //------------------------------------------------------------------------------------
        //PRIVATE_VARS
        //------------------------------------------------------------------------------------
		
		//seteable_vars
        private var _ip:String = "127.0.0.1";
        private var _port:int = 9000;
		private var _startPort:int = 9000;
		private var _onData:Function = null;
		private var _onConnect:Function = null;
		private var _onDisconnect:Function = null;
		private var _connected:Boolean = false;
		
		//internal_vars
		private var _socket:Socket = null;
		private var _initialized:Boolean = false;
		private var _reconnectTime:int = 200;
		private var _reconnectTimer:Timer = null;
		
		static private var _isDebug:Boolean = true;
		
		private var _ping_interval:uint = 5000;
		private var _ping_handler:uint = 0;
		
        //------------------------------------------------------------------------------------
        //PRIVATE_METHODS
        //------------------------------------------------------------------------------------
		
		private function onSocketEventHandler(e:Event):void
		{
			switch(e.type)
			{
				case( Event.CONNECT ):
					
					//if ( _isDebug ) trace( "( "+this+" : onSocketEventHandler() : Event.CONNECT  ) " );
					if ( !_initialized ) return;
					
					this._socket.removeEventListener(Event.CONNECT, onSocketEventHandler);
					this._socket.removeEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
					this._socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketEventHandler);
					
					this._socket.addEventListener(Event.CLOSE, onSocketEventHandler);
					this._socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
					
					clearInterval(_ping_interval);
					//_ping_interval = setInterval( function():void { sendString("ping"); } , _ping_interval );
					
					_connected = true;
					if ( _onConnect != null ) _onConnect.call();

					break;
				case( IOErrorEvent.IO_ERROR ):
					
					if ( _isDebug ) trace( "( "+this+" : onSocketEventHandler() : IOErrorEvent.IO_ERROR  ) " + (e as IOErrorEvent).toString() );
					setTimeout( reconnect , _reconnectTime);

					break;
				case( ProgressEvent.SOCKET_DATA ):
					
					if ( _onData != null )
					{
						var b:ByteArray = new ByteArray();
						(e.target as Socket).readBytes(b, 0, 0);
						var o:Object = processData(b)
						if ( o != null )_onData.call(this, o);
					}
					
					break;
				case( SecurityErrorEvent.SECURITY_ERROR ):
					
					if ( _isDebug ) trace( "( "+this+" : onSocketEventHandler() : SecurityErrorEvent.SECURITY_ERROR  ) " + (e as SecurityErrorEvent).toString() );
					
					break;
				case( Event.CLOSE ):
					
					this._socket.addEventListener(Event.CONNECT, onSocketEventHandler);
					this._socket.addEventListener(IOErrorEvent.IO_ERROR, onSocketEventHandler);
					this._socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketEventHandler);
					
					this._socket.removeEventListener(Event.CLOSE, onSocketEventHandler);
					this._socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketEventHandler);
					setTimeout( reconnect , _reconnectTime);
					
					clearInterval(_ping_interval);
					
					_connected = false;
					if ( _onDisconnect != null ) {
						_onDisconnect.call();
						_port = _startPort;
					}
					
					break;
			}
		}
		
		private function reconnect():void
		{
			_socket.connect(_ip , _port++);
			if(_port > _startPort+15)
			{
				_port = _startPort;
			}
		}
		
		protected function processData( b:ByteArray ):Object
		{
			return b;
		}
		
        //------------------------------------------------------------------------------------------------------------------------------------------------------------------
        //------------------------------------------------------------------------------------------------------------------------------------------------------------------
	}

}