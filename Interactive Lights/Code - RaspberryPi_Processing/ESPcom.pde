// import UDP library //<>// //<>// //<>//
import hypermedia.net.*;
import java.nio.ByteBuffer;

public class NetworkDevice
{
  public String ip;
  public int ledCount;
  public PVector positionOffset;
  public PVector positionIncrement;

  public NetworkDevice(String ip)
  {
    this.ip = ip;
  }
}

ArrayList<NetworkDevice> deviceList = new ArrayList<NetworkDevice>();

UDP udp_esp;
int esp_port        = 8266;    // the destination port

void loadConfig()
{
  deviceList.add(new NetworkDevice("192.168.1.201"));    // WALL ESP
  deviceList.add(new NetworkDevice("192.168.1.202"));    // STANDING ESP
  deviceList.add(new NetworkDevice("192.168.1.203"));    // CEILING ESP
}


void udpInit()
{
  udp_esp = new UDP(this, esp_port);
  //udp_esp.setReceiveHandler("ESPreceiver");
  //udp_esp.listen(true);
  //udp_esp.loopback(false);

  udpWATCH_running = true;
  new Thread(new WATCHcom()).start();


  println("UDP ready");

  loadConfig();
}

void sendData(NetworkDevice device, float[][] dataPixels)
{
  byte header[] = new byte[] {0x01, (byte)77};

  // RGB array
  byte data[] = new byte[dataPixels.length * 4];

  for (int i = 0; i < dataPixels.length; i++)
  {
    for (int q = 0; q < 4; q++)
      data[i*4 + q] = (byte)(dataPixels[i][q]);
  }

  byte[] byteSend = new byte[header.length + data.length];
  System.arraycopy(header, 0, byteSend, 0, header.length);
  System.arraycopy(data, 0, byteSend, header.length, data.length);
  //println(byteSend.length);
  udp_esp.send( byteSend, device.ip, esp_port );      
}

void ESPreceiver( byte[] data, String ip, int port ) {  // <-- extended handler

  // get the "real" message =
  // forget the ";\n" at the end <-- !!! only for a communication with Pd !!!
  //data = subset(data, 0, data.length-2);
  String message = new String(data);

  // print the result
  println( "receive: \""+message+"\" from "+ip+" on port "+port );
}

void timeout(){
 println("timeout"); 
}

public static byte [] float2ByteArray (float value)
{  
  return ByteBuffer.allocate(4).putFloat(value).array();
}