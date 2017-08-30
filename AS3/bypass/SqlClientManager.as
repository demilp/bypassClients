package bypass
{	
	
	public class SqlClientManager
	{
		
		private var actions: Dictionary;
		private var queryId : uint;
		private var client : BypassClient;
		public function SqlClientManager(client : BypassClient)
		{
			actions = new Dictionary();
			queryId = 0;
			this.client = client;
			client.addOnDataFunction(OnData);
		}
		
		public function SendQuery(query : String, callback : Function, id : String = "sql") : void
		{
			client.sendData(queryId+"|"+query, [id], "");
			actions.SetValue(queryId, callback);
			queryId++;
		}
		
		private function OnData(command:String) : void
		{
			try
			{
				var node : Object = JSON.parse(command);
				if(node != null && node["queryId"] != null)
				{
					var qid : uint = (uint)(node["queryId"]);
					if(actions.ContainsKey(qid))
					{
						var resp : SqlResponse = new SqlResponse(node);
						actions.GetValue(qid)(resp);
						actions.Remove(qid);
					}
				}
			}
			catch(e : Error)
			{
				
			}
		}
	}

}
internal class Dictionary
{
	private var keys : Array;
	private var values : Array;
	public function Dictionary()
	{
		keys = new Array();
		values = new Array();
	}
	
	private function Add(key : Object, value : Object) : void
	{
		keys.push(key);
		values.push(value);
	}
	public function Remove(key : Object) : void
	{
		for (var i:int = keys.length-1; i >= 0; i--) 
		{
			if(keys[i] == key)
			{
				keys = keys.splice(i, 1);
				values = values.splice(i, 1);
			}
		}
	}
	public function ContainsKey(key : Object) : Boolean
	{
		for (var i:int = 0; i < keys.length; i++) 
		{
			if(keys[i] == key)
			{
				return true;
			}
		}
		return false;
	}
	
	public function ContainsValue(value : Object) : Boolean
	{
		for (var i:int = 0; i < values.length; i++) 
		{
			if(values[i] == value)
			{
				return true;
			}
		}
		return false;
	}
	
	public function GetValue(key : Object) : Object
	{
		for (var i:int = 0; i < keys.length; i++) 
		{
			if(keys[i] == key)
			{
				return values[i];
			}
		}
		return null;
	}
	
	public function SetValue(key : Object, value : Object) : void
	{
		for (var i:int = 0; i < keys.length; i++) 
		{
			if(key[i] == key)
			{
				values[i] = value
				return;
			}
		}
		Add(key, value);
	}
	
	
}