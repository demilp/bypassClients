import json.JsonArray;
import json.JsonObject;

public class BypassClient extends TCPClientManager, IConnectListener
{
	private String id;
	private String tag;
	private Boolean autoRegister = false;
	
	public BypassClient(String ip, int port, String separadorDeComandos, String id, String tag)
	{
		super();
		this.id = id;
		this.tag = tag;
		autoRegister = true;
		AddConnectedListener(this);
		Initialize(ip, port, separadorDeComandos);
	}
	
	public BypassClient()
	{
		super();
	}
	private void OnConnect()
	{
		Register(id, tag);
	}
	public void Register(String id, String tag)
	{
		SendCommand("{\"type\":\"register\", \"data\":\""+id+"\", \"tag\":\""+tag+"\"}");
	}
	public void SendData(String data, String tag, params String[] ids)
	{
		
		JSONClass n = new JSONClass ();
		n["type"] = "send";
		n["data"] = data;
		n["tag"] = tag;
		n["ids"] = ConcatIds(ids);
		SendCommand (n.ToString());
		//SendCommand("{\"type\":\"send\", \"data\":\"" + data + "\", \"tag\":\""+tag+"\", \"ids\":["+ConcatIds(ids)+"]}");
		
	}
	public void SendData(String data, String tag)
	{
		JsonObject n = new JsonObject ();
		n.add("type", "send");
		n.add("data", data);
		n.add("tag", tag);
		n.add("ids", new JsonArray());
		SendCommand (n.toString());
		//SendCommand("{\"type\":\"send\", \"data\":\"" + data + "\", \"tag\":\""+tag+"\", \"ids\":[]}");
	}
	public void Broadcast(String data)
	{
		JsonObject n = new JsonObject ();
		n.add("type", "broadcast");
		n.add("data", data);
		n.add("tag", "");
		n.add("ids", new JsonArray());
		SendCommand (n.toString());
		//SendCommand("{\"type\":\"broadcast\", \"data\":\"" + data + "\", \"tag\":\"\", \"ids\":[]}");
	}
	public void BroadcastAll(String data)
	{
		JsonObject n = new JsonObject();
		n.add("type", "broadcastAll");
		n.add("data", data);
		n.add("tag", "");
		n.add("ids", new JsonArray());
		SendCommand (n.toString());
		//SendCommand("{\"type\":\"broadcastAll\", \"data\":\"" + data + "\", \"tag\":\"\", \"ids\":[]}");
	}
	private JsonArray ConcatIds(String[] ids)
	{
		JsonArray s = new JsonArray();
		for (int i = 0; i < ids.length; i++)
		{
			s.add(ids[i]);
		}
		return s;
	}
}