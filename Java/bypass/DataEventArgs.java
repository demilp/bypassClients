package bypass;

import java.util.EventObject;

public class DataEventArgs extends EventObject
{
	private String data;
	public DataEventArgs(Object source, String data)
	{
		super(source);
		this.data = data;
	}
	public String getData()
	{
		return data;
	}
}
