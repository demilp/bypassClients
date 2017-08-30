using System;
using UnityEngine;
using System.Collections;
using System.Reflection;
using Bypass;

public class BypassClientManager : MonoBehaviour
{
    private static BypassClient bypassClient = null;

    public void Awake()
    {
        getBypassClient();
    }
	public static BypassClient Instance
	{
		get
		{
			return getBypassClient();
		}
	}
    private static BypassClient getBypassClient()
    {
        if (bypassClient == null)
        {
			bypassClient = new BypassClient(Config.instance().serverIp, Config.instance().serverPort, ";","game");
        }       

        return bypassClient;
    }

    private void OnApplicationQuit()
    {
        if (bypassClient != null) bypassClient.Close();
    }

    void Update()
    {
        bypassClient.Update();
    }


    


    
}
