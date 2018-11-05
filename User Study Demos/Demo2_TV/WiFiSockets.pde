public class Server extends Thread {
  private int serverMAX = 2*Watches;
  private ArrayList<ServerSocket> mServerSockets = new ArrayList<ServerSocket>();
  ArrayList<PrintWriter> socketWriters = new ArrayList<PrintWriter>();
  ArrayList<Boolean> wifi_connecteds = new ArrayList<Boolean>();
  ArrayList<Boolean> server_running = new ArrayList<Boolean>();

  public void start() {
    println("SERVER: start");
    try {
      mServerSockets.add(new ServerSocket(SERVER_PORT_1_1));
      mServerSockets.add(new ServerSocket(SERVER_PORT_1_2));
      mServerSockets.add(new ServerSocket(SERVER_PORT_2_1));
      mServerSockets.add(new ServerSocket(SERVER_PORT_2_2));
    } 
    catch (IOException e) {
      println("SERVER: Socket ini FAILED");
    }
    for (int i = 0; i < serverMAX; i++)
      socketWriters.add(null);

    for (int i = 0; i < serverMAX; i++)
      wifi_connecteds.add(false);

    for (int i = 0; i < serverMAX; i++)
      server_running.add(false);

    startServer(0);
    startADB(1);
    startServer(2);
    startADB(3);
  }

  public void startServer (int _num) { 
    new Thread(new ReceiveMessage(mServerSockets.get(_num), _num)).start();
  }
  public void startADB (int _num) {
    new Thread(new adbThread(1, "adbThread" + _num + "", _num, tagName, mServerSockets.get(_num))).start();
  }

  public void quit() {
    for (int i = 0; i < serverMAX; i++)
      server_running.set(i,false);
      
    for (ServerSocket Socket : mServerSockets) {
      try {
        Socket.close();
      } 
      catch (IOException e) {
        println("Error in closing ServerSocket");
      }
    }
  }

  public void sendMessage(String message, int _server) {
    if (wifi_connecteds.get(_server)) {
      socketWriters.get(_server).println(message);
      println("SERVER nr " + _server + " ---- send message to device: " + message);
    } else {
      println("SERVER nr " + _server + " ---- no devices connected to the service");
    }
  }

  public class ReceiveMessage implements Runnable {
    private final String WIFI_STRING = "wifi-poll";
    private static final String STOP_ADB = "stop_adb"; 
    private static final String TOGGLE_MENU = "toggle_menu";

    protected ServerSocket serverSocket = null;
    protected Socket clientSocket = null;
    private int server_num;
    InputStreamReader inputStreamReader;
    BufferedReader bufferedReader;
    int error_counter = 0;
    long socket_check_timer = 1500;   // send poll message each ... times. If after ... times not receveived back. Connection presumed lost. 
    long last_poll = 0;              // last poll;
    int poll = 0;                   // count if poll is received
    boolean ADBquit = false;

    public ReceiveMessage (ServerSocket _serverSocket, int _server_num) {
      this.serverSocket = _serverSocket;
      server_num = _server_num;
      server_running.set(server_num,true);
    }

    public void run() {
      while (server.server_running.get(server_num)) {
        if (!wifi_connecteds.get(server_num)) {

          try {
            println("SERVER " + server_num + " : waiting for connection");
            clientSocket = serverSocket.accept();
            inputStreamReader = new InputStreamReader(clientSocket.getInputStream());
            bufferedReader = new BufferedReader(inputStreamReader);
            last_poll = System.currentTimeMillis();
            socketWriters.set(server_num, new PrintWriter(clientSocket.getOutputStream(), true));
            println("SERVER thread = CONNECTED");
            wifi_connecteds.set(server_num, true);
          } 
          catch (IOException ex) {
            println("SERVER: Problem in establishing connection");
          }
        } else {
          if (ADBquit){
           ADBquit = false;
           server.startADB(server_num+1);
          }
          try {
            String message;
            if (bufferedReader.ready()) {
              message = bufferedReader.readLine();
              if (message != null) {
                if (message.equals(WIFI_STRING)) {
                  poll = 0;        // reset poll missed counter
                  last_poll = System.currentTimeMillis();
                  //println("POLL");
                } else if (message.equals(STOP_ADB)) {
                  server.server_running.set(server_num+1,false);
                  ADBquit = true;        //corresponding ADB is shut down
                  //println("Message phone: " + message);
                } else if (message.equals(TOGGLE_MENU)) { 
                  menuToggle = !menuToggle;
                } else {
                  println("Message phone: " + message);
                }
              }
            }
            sleep(300);    // check every 100 ms
          } 
          catch (Exception ex) {
            println("SERVER thread " + server_num + " = connection lost");
            wifi_connecteds.set(server_num, false);      // prevents endless loop
          }


          if (((System.currentTimeMillis()-last_poll) > socket_check_timer)) {      // send poll every ...socket_check_timer ... 
            if (poll > 1) {// max of 2 non-received polls
              wifi_connecteds.set(server_num, false); 
              println("SERVER thread " + server_num + " =  client connection lost (by poll)");
            } else {
              socketWriters.get(server_num).println(WIFI_STRING);
              //println("poll send");
              poll++;
            }
            last_poll = System.currentTimeMillis();
          }
        }
      }

      try {
        bufferedReader.close();
        inputStreamReader.close();
        clientSocket.close();
      } 
      catch (Exception ex) {
        println("Problem in SERVER close nr  " + server_num );
      }
      println("SERVER nr " + server_num + " closed");
    }
  }
}