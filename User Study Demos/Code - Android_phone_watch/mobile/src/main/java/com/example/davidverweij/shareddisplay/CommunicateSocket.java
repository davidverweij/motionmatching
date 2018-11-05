package com.example.davidverweij.shareddisplay;

import android.os.Handler;
import android.os.Message;
import android.util.Log;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

import static java.lang.Thread.sleep;

/**
 * Created by davidverweij on 06/02/2017.
 */

public class CommunicateSocket extends Thread {
    private boolean wifi_connection = false;
    public boolean socketRunning = true;
    private Socket clientSocket;
    private PrintWriter socket_writer;
    private InputStreamReader socket_inputstream;
    private BufferedReader socket_reader;
    private String buffer;

    private static final String TAG = "CommunicateSocket";
    private static final String WIFI_STRING = "wifi-poll";
    private static final String STOP_ADB = "stop_adb";
    private static final String TOGGLE_MENU = "toggle_menu";
    private static final  String ButtonPath = "/wavetrace_show_button_";
    private boolean SendSTOP = false;
    private boolean SendTOGGLE = false;
    private Handler parentHandler;


    //public String ipAdres = "10.0.0.100";
    public String ipAdres = "192.168.1.100";

    public CommunicateSocket(Handler _Handler)  {
        parentHandler = _Handler;

    }

    private Handler myThreadHandler = new Handler() {
        public void handleMessage(Message msg) {

            switch(msg.what) {

                case 1:
                    if (socketRunning && wifi_connection){
                        SendSTOP = true;
                       Log.v(TAG, "send stop message to laptop via Socket");
                    }
                    break;

                case 6:
                    SendTOGGLE = true;
                    Log.v(TAG, "send togglemenu message to laptop via Socket");

                default:
                    Log.i("myThread", "Unhandled message. msg.what = " + msg.what);
                    break;
            }
        }
    };

    public Handler getHandler() {
        return myThreadHandler;
    }


    public void run() {
        long last_poll = 0;
        long poll_timer = 5000;

        Log.v(TAG, "CLIENT: socket ini");
        while (socketRunning) {
            if (!wifi_connection) {
                try {
                    clientSocket = new Socket(ipAdres, 1788);
                    socket_writer = new PrintWriter(clientSocket.getOutputStream(), true);
                    socket_inputstream = new InputStreamReader(clientSocket.getInputStream());
                    socket_reader = new BufferedReader(socket_inputstream);
                    socket_writer.println(WIFI_STRING);
                    Log.v(TAG, "CLIENT: connected to server");
                    Message messageToParent = Message.obtain();
                    messageToParent.what = 22;
                    messageToParent.obj = "activate_watch";
                    //Log.i("myThread", "About to send message to parent ...");
                    parentHandler.sendMessage(messageToParent);
                    wifi_connection = true;
                    last_poll = System.currentTimeMillis();
                } catch (IOException e) {

                }
            }
            if (wifi_connection) {
                // LISTEN FOR RESPONSE
                if (SendSTOP){
                    socket_writer.println(STOP_ADB);
                    SendSTOP = false;
                }
                if (SendTOGGLE){
                    socket_writer.println(TOGGLE_MENU);
                    SendTOGGLE = false;
                }
                try {
                    if (socket_reader.ready()) {
                        buffer = socket_reader.readLine();
                        if (buffer!=null) {
                            if (buffer.equals(WIFI_STRING)) {
                                last_poll = System.currentTimeMillis();
                                socket_writer.println(WIFI_STRING);
                            } else if (buffer.startsWith(ButtonPath)) {
                                Message messageToParent = Message.obtain();
                                messageToParent.what = 33;
                                messageToParent.obj = buffer.substring(23);
                                //Log.i("myThread", "About to send message to parent ...");
                                parentHandler.sendMessage(messageToParent);
                            } else {
                                Message messageToParent = Message.obtain();
                                messageToParent.what = 22;
                                messageToParent.obj = buffer;
                                //Log.i("myThread", "About to send message to parent ...");
                                parentHandler.sendMessage(messageToParent);
                            }
                        }
                    }  else {
                        try {
                            sleep(2L);
                        } catch (Exception e) {
                            Log.d(TAG, "error in wifiCommunicate sleep");
                        }
                    }
                } catch (Exception e) {
                    Log.v(TAG, "CLIENT: connection lost");
                    wifi_connection = false;
                }

               if (System.currentTimeMillis()-last_poll > poll_timer) {
                   Log.v(TAG, "CLIENT: connection lost by poll");
                   wifi_connection = false;
                   try {
                       socket_writer.close();
                       clientSocket.close();
                       socket_inputstream.close();
                       socket_reader.close();
                   } catch (IOException e) {
                       e.printStackTrace();
                   }
               }
            }
        }
        try {
            socket_writer.close();
            clientSocket.close();
            socket_inputstream.close();
            socket_reader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}