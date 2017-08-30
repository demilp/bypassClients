package bypass
{
	public class SqlResponse
	{
		public var result : String;
		public var data : Array;
		public function SqlResponse(json : Object)
		{
			result = json["result"];
			var reg : Object = JSON.parse(json["data"]);
			data = new Array();
			for (var i:int = 0; i < reg.length; i++) 
			{
				data.push(reg[i]);
			}
			
			
		}
	}
}