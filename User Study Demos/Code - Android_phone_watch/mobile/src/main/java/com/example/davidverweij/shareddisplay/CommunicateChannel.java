package com.example.davidverweij.shareddisplay;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

import com.google.android.gms.appindexing.AppIndex;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.wearable.Channel;
import com.google.android.gms.wearable.ChannelApi;
import com.google.android.gms.wearable.Wearable;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static android.text.TextUtils.split;
import static java.lang.Thread.sleep;

/**
 * Created by davidverweij on 06/02/2017.
 */

public class CommunicateChannel extends Thread implements ChannelApi.ChannelListener {
    private final String TAG = "CommunicateChannel";
    private Context context;
    private ExecutorService ThreadPoolExecutor;
    private Future LongRunningTask;
    public boolean mChannel_Open = false;
    public initiator_communication Ini = new initiator_communication();
    private GoogleApiClient mGoogleApiClient;
    private InputStream mChannelReceive;
    private OutputStream mChannelSend;
    public boolean socketRunning = true;
    //public String ipAdres = "10.0.0.100";
    public String ipAdres = "192.168.1.100";

    private Handler parentHandler;

    public CommunicateChannel(Context context, Handler _Handler) {           //constructor
        this.context = context;
        ThreadPoolExecutor = Executors.newSingleThreadExecutor();

        // ATTENTION: This "addApi(AppIndex.API)"was auto-generated to implement the App Indexing API.
        // See https://g.co/AppIndexing/AndroidStudio for more information.
        mGoogleApiClient = new GoogleApiClient.Builder(this.context).addApi(Wearable.API).build();
        mGoogleApiClient.connect();

        parentHandler = _Handler;
    }

    private Handler myThreadHandler = new Handler() {
        public void handleMessage(Message msg) {

            switch(msg.what) {

                case 4:
                    Log.i("myThread", "Handled message. msg.what = " + msg.what);
                    break;

                case 6:
                    Log.i("myThread", "Handled message. msg.what = " + msg.what);
                    break;

                default:
                    Log.i("myThread", "Unhandled message. msg.what = " + msg.what);
                    break;
            }
        }
    };

    public Handler getHandler() {
        return myThreadHandler;
    }

    @Override
    public void onChannelClosed(Channel channel, int closeReason, int appSpecificErrorCode) {
        mChannel_Open = false;
        Log.v(TAG, "Channel closed...");
        socketRunning = false;
        //LongRunningTask.cancel(true);

        Message messageToParent = Message.obtain();
        messageToParent.what = 11;
        messageToParent.obj = "channel_closed";
        parentHandler.sendMessage(messageToParent);
    }

    @Override
    public void onOutputClosed(Channel channel, int closeReason, int appSpecificErrorCode) {
        mChannel_Open = false;
        socketRunning = false;
        Log.v(TAG, "Output channel closed...");
    }

    @Override
    public void onInputClosed(Channel channel, int closeReason, int appSpecificErrorCode) {
        mChannel_Open = false;
        socketRunning = false;
        Log.v(TAG, "input channel closed...");
    }

    @Override
    public void onChannelOpened(final Channel channel) {

        if (channel.getPath().equals(MainActivity.DataMapKeys.CHANNEL)) {
            mChannel_Open = true;
            socketRunning = true;
            Log.d(TAG, "channel opened!!");
            channel.getInputStream(mGoogleApiClient).setResultCallback(
                    new ResultCallback<Channel.GetInputStreamResult>() {
                        @Override
                        public void onResult(Channel.GetInputStreamResult is_result) {
                            // Use result
                            mChannelReceive = is_result.getInputStream();

                            // When finished, also open an outputstream

                            channel.getOutputStream(mGoogleApiClient).setResultCallback(
                                    new ResultCallback<Channel.GetOutputStreamResult>() {
                                        @Override
                                        public void onResult(Channel.GetOutputStreamResult os_result) {
                                            // Use result
                                            mChannelSend = os_result.getOutputStream();
                                            // When finished, start latency test
                                            Ini.function_a();
                                        }
                                    });
                        }
                    });



        }
    }

    public class initiator_communication {
        public boolean a = false;
        public boolean b = false;

        public void function_a(){
            if (b){
                LongRunningTask = ThreadPoolExecutor.submit(new ChannelThread());
            } else {
                a = true;
            }
        }

        public void function_b(){
            if (a){
                LongRunningTask = ThreadPoolExecutor.submit(new ChannelThread());
            } else {
                b = true;
            }
        }

    }

    public class ChannelThread implements Runnable {
        private final String TAG = "ChannelThread";
        private long start_time;
        private long latency_results = 0;
        private long latency_start_android_times = 0;
        private long latency_smartwatch_times = 0;
        boolean skip_latency = false;

        private long latency_timer;
        private long latency_frequency = 5000;

        int i = 0;
        int i_old = -1;
        int i_return = -1;

        /* for Socket */
        private Socket clientSocket;
        private PrintWriter socket_writer;
        boolean wifi_connection = false;

        public void run() {
            try {

                sleep(1000L);            //give a little room before sending calibration.
            } catch (Exception e) {
                Log.d(TAG, "error in CalibrateTask sleep");
            }

            BufferedReader br = new BufferedReader(new InputStreamReader(mChannelReceive));
            Log.d(TAG, "Connected to Channel");
            PrintWriter printWriter = new PrintWriter(mChannelSend, true);
            String Buffer;

            while (socketRunning) {
                while (!wifi_connection) {
                    try {
                        //Log.d(TAG, "Waiting for socket on port 1766");
                        clientSocket = new Socket(ipAdres, 1789);
                        socket_writer = new PrintWriter(clientSocket.getOutputStream(), true);
                        Log.v(TAG, "connected to server");
                        wifi_connection = true;
                    } catch (IOException e) {
                        try {
                            sleep(50);
                        } catch (Exception ex) {
                            Log.e(TAG, "CLIENT: error in sleep");
                        }
                    }
                }

                while (mChannel_Open && wifi_connection) {
                    if (!skip_latency) {
                        latency_timer = System.currentTimeMillis();
                        i = 0;
                        i_old = -1;
                        i_return = -1;

                        start_time = System.currentTimeMillis();
                        printWriter.println("LATENCY;" + i);
                        skip_latency = true;
                    }

                    // LISTEN FOR RESPONSE
                    try {
                        if ((Buffer = br.readLine()) != null) {
                            long temp_latency_time = System.currentTimeMillis();
                            String[] terms = split(Buffer, ";");
                            if (terms[0].equals("RESPONSE")) {
                                long watchtime_return = 0;
                                try {
                                    i_return = Integer.parseInt(terms[1]);
                                    watchtime_return = Long.parseLong(terms[2]);
                                    //Log.v("TAG", "got Latency Respons" + i_return);
                                } catch (NumberFormatException nfe) {
                                    Log.e(TAG, "Could not parse " + nfe);
                                }
                                //Log.v(TAG, "LATENCY TEST " + i_return + Buffer);
                                if (i_return == i) {
                                    latency_results = (temp_latency_time - start_time);
                                    latency_start_android_times = start_time;
                                    latency_smartwatch_times = watchtime_return;
                                } else {
                                    Log.e(TAG, "Got wrong latency test response");
                                }

                                try {
                                    socket_writer.println(TAG
                                            + "###"
                                            + "LATENCY"
                                            + ";" + System.currentTimeMillis()
                                            + ";" + latency_start_android_times
                                            + ";" + latency_smartwatch_times
                                            + ";" + latency_results
                                    );
                                    Log.v(TAG,"send latency");
                                } catch (Exception e) {
                                    wifi_connection = false;
                                    Log.v(TAG, "Error in sending Latency, assume broken connection");
                                }

                            } else {
                                socket_writer.println(TAG
                                        + "###"
                                        + Long.toString(System.currentTimeMillis())
                                        + ";" + Buffer);
                                //Log.v(TAG, Buffer);
                            }
                        }
                    } catch (IOException e) {
                        Log.e(TAG, "Error in reading and parsing sensor data, assume  socket is gone");
                        wifi_connection = false;
                    }

                    /*if (System.currentTimeMillis() - latency_timer > latency_frequency) {
                        skip_latency = false;
                    }*/
                }
            }
            try {
                Log.v(TAG,"Closing ChannelSocketServer......");
                clientSocket.close();
                socket_writer.close();
            } catch (Exception e){
                Log.e(TAG, e.toString());
            }
        }
    }
}
