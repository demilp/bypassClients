package bypass
{
	public class BypassClient extends SimpleSocket
	{
		private var onConnects : Array;
		private var onDatas : Array;
		private var onDisconnects : Array;
		private var id : String;
		private var tag : String;
		private var delimiter : String;
		public function BypassClient(id:String, tag:String, pIp:String="127.0.0.1", pPort:int=9000, delimiter:String=";")
		{
			this.id = id;
			this.tag = tag;
			this.delimiter = delimiter;
			super(pIp, pPort);
			onData = _onData;
			onConnect = _onConnect;
			onDisconnect = _onDisconnect;
			onConnects = new Array();
			onDatas = new Array();
			onDisconnects = new Array();
			init();
		}
		public function addOnDataFunction(funct:Function):void
		{
			if(onDatas.indexOf(funct) == -1)
			{
				onDatas.push(funct);
			}
		}
		public function removeOnDataFunction(funct:Function):void
		{var ind : int = onDatas.indexOf(funct);
			if(ind != -1)
			{
				onDatas.splice(ind, 1);
			}
		}
		
		public function addOnConnectFunction(funct:Function):void
		{
			if(onConnects.indexOf(funct) == -1)
			{
				onConnects.push(funct);
			}
		}
		public function removeOnConnectFunction(funct:Function):void
		{var ind : int = onConnects.indexOf(funct);
			if(ind != -1)
			{
				onConnects.splice(ind, 1);
			}
		}
		
		public function addOnDisconnectFunction(funct:Function):void
		{
			if(onDisconnects.indexOf(funct) == -1)
			{
				onDisconnects.push(funct);
			}
		}
		public function removeOnDisconnectFunction(funct:Function):void
		{var ind : int = onDisconnects.indexOf(funct);
			if(ind != -1)
			{
				onDisconnects.splice(ind, 1);
			}
		}
		
		
		private var buffer : String = "";
		private function _onData(message : String) : void
		{
			message += buffer;
			var commands : Array = message.split(delimiter);
			buffer = commands[length-1];
			for(var i : int; i < commands.length-1; i++)
			{
				if(commands[i] == "")
				{
					continue;
				}
				for each (var v:Function in onDatas) 
				{
					v(commands[i]);
				}				
			}	
		}
		public function sendData(data : String, ids: Array, tag : String) : void
		{
			var json : Object = new Object();
			json["data"] = data;
			json["ids"] = ids;
			json["tag"] = tag;
			json["type"] = "send";
			sendCommand(JSON.stringify(json));
		}
		public function register(id: String, tag : String) : void
		{
			var json : Object = new Object();
			json["data"] = id;
			json["ids"] = new Array();
			json["tag"] = tag;
			json["type"] = "register";
			sendCommand(JSON.stringify(json));
		}
		public function sendCommand(command : String) : void
		{
			sendString(command+delimiter);
		}
		private function _onConnect() : void
		{
			register(id, tag);
			for each (var v:Function in onConnects) 
			{
				v();
			}
		}
		private function _onDisconnect() : void
		{
			for each (var v:Function in onDisconnects) 
			{
				v();
			}	
		}
	}
}