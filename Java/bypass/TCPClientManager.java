package bypass;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Timer;
import java.util.TimerTask;
import java.util.logging.Logger;

public class TCPClientManager {

	Socket clientSocket;
	DataOutputStream outToServer;
	DataInputStream input;
    private Thread runThread;
    private String buffer = "";
    boolean run = true;
    byte[] disconnectTest;
    private String serverIp;
    private int serverPort;
    private String commandSeparator;
    private boolean _connected = false;
    private Date time;
    private Timer timer;
    public boolean getConnected()
    {
    	return _connected;
    }
    public void initialize(String ip, int port, String commandSeparator)
    {
    	run = true;
    	if(runThread == null)
    	{
    		runThread = GetUpdateThread();
    		runThread.start();
    	}
    	try {
			disconnectTest = (commandSeparator).getBytes("UTF-8");
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    	serverIp = ip;
    	serverPort = port;
    	this.commandSeparator = commandSeparator;
    	_connected = false;
    	
    	try {
			clientSocket = new Socket(ip, port);
			outToServer = new DataOutputStream(clientSocket.getOutputStream());
	    	input = new DataInputStream(clientSocket.getInputStream());
	    	_connected = true;
	    	onConnect();
		} catch (IOException e) {
			timer = new Timer();
			timer.schedule(new TimerTask(){public void run(){Reconnect();}}, 3000);
		}
    	
    }
    Thread GetUpdateThread()
    {
    	Thread t = new Thread()
    	{
    	     public void run()
    	     {
    	    	 time = new Date();
    	    	 while(run)
    	    	 {
    	    		 clientLoop();
    	    	 }
    	     }
    	};
    	return t;
    }
    private float tRetry = 4;
    private void clientLoop()
    {
    	if(_connected)
    	{
    		byte[] myReadBuffer = new byte[1024];
    		StringBuilder myCompleteMessage = new StringBuilder();
    		int numberOfBytesRead = 0;
    		int total = 0;
    		try {
				while(input != null && input.available() > 0)
				{
					numberOfBytesRead = input.read(myReadBuffer, 0, myReadBuffer.length);
					total += numberOfBytesRead;
					myCompleteMessage.append(new String(myReadBuffer, 0, numberOfBytesRead, "UTF-8"));
				}
				String completeMessage = myCompleteMessage.toString();
				if(total > 0)
					onPartialData(completeMessage);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
    		if(_connected)
    		{
    			//long l = new Date().getTime() - time.getTime();
    			if((new Date().getTime() - time.getTime()) > (tRetry*1000))
    			{
    				time = new Date();
    				if(!isConnected())
    				{
    					_connected = false;
    					onDisconnect();
    					Reconnect();
    				}
    			}
    		}
    	}
    }
    private void Reconnect()
    {
    	if(!_connected)
    		initialize(serverIp, serverPort, commandSeparator);
    }
    private boolean isConnected()
    {

		try
		{
			outToServer.write(disconnectTest);
			outToServer.flush();
			return true;
		}catch(Exception e)
		{
			return false;
		}
    	
    }
    private void onPartialData(String data)
    {
    	data = buffer+data;
    	String[] commands = data.split(commandSeparator, -1);
    	buffer = commands[commands.length-1];
    	for (int i = 0; i < commands.length - 1; i++) {
			if(commands[i] == "")
				continue;
			onData(commands[i]);
		}
    }
    public void SendCommand(String data)
    {
        if (isConnected())
        {
            byte[] d;
			try {
				d = (data + commandSeparator).getBytes("UTF-8");
				outToServer.write(d);
    			outToServer.flush();
			} catch (UnsupportedEncodingException e1) {
				// TODO Auto-generated catch block
				//e1.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				//e.printStackTrace();
			}
        }
    }
    public void Close()
    {
    	if(clientSocket != null)
    	{
    		run = false;
    		try {
				clientSocket.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
    	}
    	
    }
    private List<DataListener> onDataListener = new ArrayList<DataListener>();
    public void addOnDataListener(DataListener l)
    {
    	onDataListener.add(l);
    }
    private List<ConnectListener> onConnectListener = new ArrayList<ConnectListener>();
    public void addOnConnectListener(ConnectListener l)
    {
    	onConnectListener.add(l);
    }
    private List<DisconnectListener> onDisconnectListener = new ArrayList<DisconnectListener>();
    public void addOnDisconnectListener(DisconnectListener l)
    {
    	onDisconnectListener.add(l);
    }
    private void onData(String data)
    {
    	for (DataListener hl : onDataListener)
    	{
			if(hl == null)
			{
				onDataListener.remove(hl);
			}
    	}
    	for (DataListener hl : onDataListener)
    	{
    		hl.onData(data);
    	}
    }
    private void onConnect()
    {
    	System.out.println("Connected");
    	for (ConnectListener hl : onConnectListener)
    	{
			if(hl == null)
			{
				onConnectListener.remove(hl);
			}
    	}
    	for (ConnectListener hl : onConnectListener)
    	{
    		hl.onConnect();
    	}
    }
    
    private void onDisconnect()
    {
    	System.out.println("Disconnected");
    	for (DisconnectListener hl : onDisconnectListener)
    	{
			if(hl == null)
			{
				onDisconnectListener.remove(hl);
			}
    	}
    	for (DisconnectListener hl : onDisconnectListener)
    	{
    		hl.onDisconnect();
    	}
    }
}
interface DataListener
{
	void onData(String data);
}
interface ConnectListener
{
	void onConnect();
}
interface DisconnectListener
{
	void onDisconnect();
}
