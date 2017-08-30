using UnityEngine;
using System.Collections;
using Bypass;
using System.Collections.Generic;
using System;
using Bypass.SimpleJSON;

public static class SqlQueryManager
{
	private static Dictionary<BypassClient, int> clients;
	private static Dictionary<uint, Action<SqlResponse>> actions;
	private static uint queryId;

	static SqlQueryManager()
	{
		clients = new Dictionary<BypassClient, int>();
		actions = new Dictionary<uint, Action<SqlResponse>>();
		queryId = 0;
	}
	public static void SendQuery(string query, BypassClient client, Action<SqlResponse> action, string id="sql")
	{
		if(!clients.ContainsKey(client))
		{
			clients.Add(client, 0);
			client.OnDataEvent += OnData;
		}
		clients [client]++;
		client.SendData (queryId + "|" + query, "", id);
		actions.Add (queryId, action);
		queryId++;
	}

	private static void OnData(object sender, DataEventArgs e)
	{
		try
		{
			JSONNode node = JSON.Parse(e.data);
			if(node != null && node["queryId"] != null)
			{
				uint qid = uint.Parse(node["queryId"].Value);
				if(actions.ContainsKey(qid))
				{
					SqlResponse resp = new SqlResponse(node);
					actions[qid](resp);
					BypassClient c =((BypassClient)sender);
					actions.Remove(uint.Parse(node["queryId"].Value));
					clients[c]--;
					if(clients[c] == 0)
					{
						c.OnDataEvent-=OnData;
						clients.Remove(c);
					}
				}


			}
		}catch(Exception)
		{

		}
	}
	public class SqlResponse
	{
		public string result;
		public JSONNode[] data;
		public SqlResponse(JSONNode json)
		{
			result = json["result"].Value;
			JSONNode reg = JSON.Parse(json["data"].Value);
			data = new JSONNode[reg.Count];
			int i = 0;
			foreach (JSONNode item in reg.Children)
			{
				data[i] = item;
				i++;
			}

			
		}
	}

}
