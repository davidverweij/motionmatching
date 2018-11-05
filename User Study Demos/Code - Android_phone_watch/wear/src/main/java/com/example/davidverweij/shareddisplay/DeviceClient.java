// TODO: an introduction into BLE : http://www.eetimes.com/document.asp?doc_id=1278927
// The Channel API saves disk space unlike the DataApi class, which creates a copy of the assets on the local device before synchronizing with connected devices.
// https://developer.android.com/training/wearables/data-layer/index.html
// You can read and write simultaniously to the channel: http://stackoverflow.com/questions/6265731/do-java-sockets-support-full-duplex


package com.example.davidverweij.shareddisplay;

import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Vibrator;
import android.util.Log;
import android.view.KeyEvent;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.wearable.Channel;
import com.google.android.gms.wearable.ChannelApi;
import com.google.android.gms.wearable.MessageApi;
import com.google.android.gms.wearable.Wearable;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import static android.content.Context.VIBRATOR_SERVICE;
import static android.text.TextUtils.split;
import static java.lang.Math.round;

public class DeviceClient {
    private static final String TAG = "DeviceClient";
    private static final String WATCH_FLICK = "/wavetrace_watch_flick";
    private static final int CLIENT_CONNECTION_TIMEOUT = 15000;

    private Channel mChannel;
    private OutputStream mChannelSend;
    private InputStream mChannelReceive;
    private boolean mChannel_Open = false;
    private boolean data_transfer = false;
    private PrintWriter printWriter;
    private ExecutorService threadPoolExecutor = Executors.newSingleThreadExecutor();
    private Future ShortRunningTask;
    private Vibrator mVibrator;
    private long[] vibratePage = {0, 50, 50,50};            // wait, on, wait, on, wait, on
    private long[] vibrateApp = {0, 500};            // wait, on, wait, on, wait, on
    private long[] vibrateSelect = {0,30,30,30,30,30};
    final int noRepeat = -1;       //-1 - don't repeat
    private int systemState = -1;                       // keep track of which demo we are doing (set at start)
    private String watchNode;
    private boolean watchHand = false;


    public static DeviceClient instance;

    public static DeviceClient getInstance(Context context) {
        if (instance == null) {
            instance = new DeviceClient(context.getApplicationContext());
        }

        return instance;
    }

    private Context context;
    private GoogleApiClient googleApiClient;
    private ExecutorService executorService;
    Intent intent_MainActivity;

    private DeviceClient(Context context) {
        this.context = context;
        googleApiClient = new GoogleApiClient.Builder(context).addApi(Wearable.API).build();
        executorService = Executors.newSingleThreadExecutor();      // ensures execution FIFO

        mVibrator = (Vibrator) context.getSystemService(VIBRATOR_SERVICE);


    }

    public void startWatch(int activate, String node){;
        //Log.v(TAG,"SystemState:" + systemState + " activate: " + activate);
        watchNode = node;   // take on the node who started the watch
        switch(activate){
            case -1:                // watch off
                switch(systemState){
                    case -1:
                        // was off already, do nothing
                        break;
                    case 0:
                        //close activity, but no need to close channel
                        StopMainActivity();
                        break;
                    case 1:
                        //close activity, and close channel
                        stopChannel();
                        StopMainActivity();
                        break;
                    default:
                        break;
                }
                systemState = activate;    // take on new system state
                break;
            case 0:                 // watch on, no data
                switch(systemState){
                    case -1:
                        // was off, thus turn on app, not channel
                        StartMainActivity();
                        break;
                    case 0:
                        // was already in this state, do nothing
                        break;
                    case 1:
                        // channel was on, so stop channel
                        stopChannel();
                        goToPage(99);
                        break;
                    default:
                        break;
                }
                systemState = activate;    // take on new system state
                break;
            case 1:                 // watch on, data

                switch(systemState){
                    case -1:
                        // was off, thus turn on app, AND channel
                        StartMainActivity();
                        startChannel();
                        break;
                    case 0:
                        // was on, so only start channel
                        startChannel();
                        break;
                    case 1:
                        // was already in this state, do nothing
                        stopChannel();
                        break;
                    default:
                        break;
                }
                systemState = activate;    // take on new system state
                break;
            default:
                Log.wtf(TAG, "This should never happen! Switch in startWatch");
                break;
        }
    }

    public void selection (){                           // if  is selected
        Log.v(TAG,"selection vibrate!");
        mVibrator.vibrate(vibrateSelect, noRepeat);
    }

    public void setHand (boolean _hand){ watchHand = _hand;}

    public void StartMainActivity() {
        Bundle b = new Bundle();
        b.putBoolean("boolean", true);
        b.putString("node",watchNode);
        intent_MainActivity = new Intent(context, MainActivity.class);
        intent_MainActivity.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        intent_MainActivity.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent_MainActivity.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent_MainActivity.putExtras(b);
        context.startActivity(intent_MainActivity);
        Log.v(TAG,"started Main Activity");
    }

    public void StopMainActivity(){
        Bundle b = new Bundle();
        b.putBoolean("boolean", false);
        intent_MainActivity.putExtras(b);
        context.startActivity(intent_MainActivity);
    }

    public void goToPage(int page) {
        intent_MainActivity.putExtra("keep", true);
        intent_MainActivity.putExtra("page", page);
        context.startActivity(intent_MainActivity);
        if (page != 99) {
            mVibrator.vibrate(vibratePage, noRepeat);
        }
    }

    public void sendSensorData(final int sensorType, final int accuracy, final long timestamp, final float[] values) {
        if (data_transfer) {
            //Log.v(TAG, Long.toString(timestamp));
            executorService.submit(new Runnable() {
                @Override
                public void run() {
                    sendSensorDataInBackground(sensorType, accuracy, timestamp, values, watchHand);
                }
            });
        }
    }

    public void sendSensorData(final String text) {
        if (text.equals("/FLICK")) {
            new flickMessage().execute();
        } else  if (data_transfer) {
            executorService.submit(new Runnable() {
                @Override
                public void run() {
                    sendSensorDataInBackground(text);
                }
            });
        }
    }

    public void startChannel() {
        if (watchNode!=null && !mChannel_Open) {
            final String inner_node = watchNode;
            if (validateConnection()) {
                Log.d(TAG, "StartChannel" + inner_node);
                Wearable.ChannelApi.openChannel(googleApiClient, inner_node, DataMapKeys.CHANNEL).setResultCallback(
                        new ResultCallback<ChannelApi.OpenChannelResult>() {
                            @Override
                            public void onResult(ChannelApi.OpenChannelResult result) {
                                // use result
                                mChannel = result.getChannel();
                                Log.d(TAG, "SuccesChannel!");
                                mChannel.getOutputStream(googleApiClient).setResultCallback(
                                        new ResultCallback<Channel.GetOutputStreamResult>() {
                                            @Override
                                            public void onResult(Channel.GetOutputStreamResult os_result) {
                                                // Use result

                                                Log.d(TAG, "SuccessOutputstream!");
                                                mChannelSend = os_result.getOutputStream();
                                                printWriter = new PrintWriter(mChannelSend, true); // the writer for sending sensordata

                                                mChannel.getInputStream(googleApiClient).setResultCallback(
                                                        new ResultCallback<Channel.GetInputStreamResult>() {
                                                            @Override
                                                            public void onResult(Channel.GetInputStreamResult os_result) {
                                                                // Use result
                                                                mChannelReceive = os_result.getInputStream();

                                                                // When finished, start latency test
                                                                mChannel_Open = true;
                                                                ShortRunningTask = threadPoolExecutor.submit(new LatencyTest());            // will wait for incoming messages on channel

                                                                Log.d(TAG, "SuccessInputstream!");
                                                                String MessagePath = "/enable_latencyTest";             // start latency test from phone
                                                                Wearable.MessageApi.sendMessage(
                                                                        googleApiClient, inner_node, MessagePath, new byte[0]).setResultCallback(
                                                                        new ResultCallback<MessageApi.SendMessageResult>() {
                                                                            @Override
                                                                            public void onResult(MessageApi.SendMessageResult sendMessageResult) {
                                                                                if (!sendMessageResult.getStatus().isSuccess()) {
                                                                                    Log.e(TAG, "Failed to send message with status code: "
                                                                                            + sendMessageResult.getStatus().getStatusCode());
                                                                                } else {
                                                                                    mVibrator.vibrate(vibrateApp, noRepeat);  // succes!
                                                                                }
                                                                            }
                                                                        }
                                                                );

                                                            }
                                                        });


                                            }
                                        });
                            }
                        });
            } else {
                Log.d(TAG, "no googleApi Connection!");
            }
        }
    }

    public void stopChannel(){
        data_transfer = false;
        mChannel_Open = false;
        try {
            printWriter.close();
            ShortRunningTask.cancel(true);
        } catch (Exception e) {
            Log.d(TAG, "ErrorClosing Printwriter and ShortRunningTask");
        }
        try {
            mChannelSend.close();
            mChannel.close(googleApiClient);
            mChannel = null;
        } catch (Exception e) {
            Log.d(TAG, "ErrorClosing Channel");
        }

    }


    private boolean validateConnection() {
        if (googleApiClient.isConnected()) {
            return true;
        }
        ConnectionResult result = googleApiClient.blockingConnect(CLIENT_CONNECTION_TIMEOUT, TimeUnit.MILLISECONDS);
        return result.isSuccess();
    }

    private void sendSensorDataInBackground(int sensorType, int accuracy, long timestamp, float[] values, boolean _watchHand) {
        //  yaw, roll, pitch
        String message = Long.toString(timestamp)
                + ";" + sensorType
                + ";" + accuracy;
        if (_watchHand) {                                   //righthanded
            message= message
                    + ";" + roundFloat(values[0], 3)
                    + ";" + roundFloat(values[1], 3)
                    + ";" + roundFloat(-1*values[2], 3);
        } else {
            message= message
                    + ";" + roundFloat(values[0], 3)
                    + ";" + roundFloat(values[1], 3)
                    + ";" + roundFloat(values[2], 3);
        }
        printWriter.println(message);
    }

    public static String roundFloat(float value, int decimalPlace) {
        BigDecimal bd = new BigDecimal(Float.toString(value));
        bd = bd.setScale(decimalPlace, BigDecimal.ROUND_HALF_UP);
        return bd.toString();
    }

    private void sendSensorDataInBackground(String text) {
        String message = text;

            printWriter.println(message);

    }

    public class LatencyTest implements Runnable {

        public void run() {
            BufferedReader br = new BufferedReader(new InputStreamReader(mChannelReceive));
            String Buffer;
            Log.d(TAG, "Latencytest: got reader");

            while(mChannel_Open) {
                try {
                    if ((Buffer = br.readLine()) != null) {
                        long temp_time = System.currentTimeMillis();
                        String[] terms = split(Buffer, ";");
                        if (terms[0].equals("LATENCY")) {
                            printWriter.println("RESPONSE" + ";" + terms[1] + ";" + temp_time);
                            data_transfer = true;
                        }
                    }
                } catch (IOException e) {
                    Log.e(TAG, "Error in reading channel!!");
                }
            }
            Log.v(TAG, "Finished Latency Check");
        }
    }

    private class flickMessage extends AsyncTask<Void, Void, Void> {

        @Override
        protected Void doInBackground(Void... args) {
            flick_msg(watchNode);
            return null;
        }
    }

    private void flick_msg(String node) {
        String MessagePath;
        MessagePath = WATCH_FLICK;
        Wearable.MessageApi.sendMessage(
                googleApiClient, node, MessagePath, new byte[0]).setResultCallback(
                new ResultCallback<MessageApi.SendMessageResult>() {
                    @Override
                    public void onResult(MessageApi.SendMessageResult sendMessageResult) {
                        if (!sendMessageResult.getStatus().isSuccess()) {
                            Log.e(TAG, "Failed to send message with status code: "
                                    + sendMessageResult.getStatus().getStatusCode());
                        } else {
                            Log.d(TAG,"send message to phone");
                        }
                    }
                }
        );
    }



}