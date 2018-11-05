/*
 * Copyright (C) 2014 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/*
 * learned a lot from https://github.com/pocmo/SensorDashboard
 */

/*
 * Channel API will be turned off on October 31, 2017. Now using FireBase Realtime Database
 */

/* http://stackoverflow.com/questions/32190749/communication-between-java-server-and-android-client-using-network-service-disco
 * helped me create the discovery
 */

package com.example.davidverweij.shareddisplay;

import android.app.Activity;
import android.content.Context;
import android.content.IntentSender;
import android.net.Uri;
import android.net.nsd.NsdManager;
import android.net.nsd.NsdServiceInfo;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewParent;
import android.widget.RadioButton;
import android.widget.TextView;

import com.google.android.gms.appindexing.Action;
import com.google.android.gms.appindexing.AppIndex;
import com.google.android.gms.appindexing.Thing;
import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.GoogleApiClient.ConnectionCallbacks;
import com.google.android.gms.common.api.GoogleApiClient.OnConnectionFailedListener;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.wearable.MessageApi;
import com.google.android.gms.wearable.MessageApi.SendMessageResult;
import com.google.android.gms.wearable.MessageEvent;
import com.google.android.gms.wearable.Node;
import com.google.android.gms.wearable.NodeApi;
import com.google.android.gms.wearable.Wearable;

import java.net.Socket;
import java.util.Collection;
import java.util.HashSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;


public class MainActivity extends Activity implements
        MessageApi.MessageListener,
        ConnectionCallbacks,
        OnConnectionFailedListener {

    private static final String TAG = "MainActivity";

    //Request code for launching the Intent to resolve Google Play services errors.
    private static final int REQUEST_RESOLVE_ERROR = 1000;

    private static final String START_WATCH = "/wavetrace_start_watch";
    private static final String STOP_WATCH = "/wavetrace_stop_watch";
    private static final String START_ACTIVITY_PATH = "/wavetrace_start_shared_display";
    private static final String STOP_ACTIVITY_PATH = "/wavetrace_stop_shared_display";
    private static final  String ButtonPath = "/wavetrace_show_button_";
    private static final String HAND_RIGHT = "/wavetrace_hand_right";
    private static final String HAND_LEFT = "/wavetrace_hand_left";
    private static final String SELECTION_PATH = "/wavetrace_selection_true";

    private static final String WATCH_FLICK = "/wavetrace_watch_flick";
    static final int SERVER_INT = 22;
    static final int CHANNEL_INT = 11;
    static final int BUTTON_INT = 33;

    private GoogleApiClient mGoogleApiClient;
    private boolean mResolvingError = false;
    private int systemStage = -1;           // to keep track of communications

    // BUTTONS
    private View mActivateBtn, mStopBtn , mStartActivityBtn, mStopActivityBtn, mToggleMenu;
    private TextView mSTATE;
    private View[] selectButtons = new View[32];

    // WEARABLE COMMUNICATION
    private Collection<String> nodes;
    private CommunicateChannel ChannelComms;
    private CommunicateSocket SocketComms;
    // An object that manages Messages in a Thread
    private Handler mHandler;
    private Handler channelHandler;
    private Handler socketHandler;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.v(TAG, "onCreate");
        setContentView(R.layout.main_activity);

        setupViews();

        // Defines a Handler object that's attached to the UI thread
        mHandler = new Handler(Looper.getMainLooper()) {

            @Override
            public void handleMessage(Message inputMessage) {
                //Log.v(TAG, "Handler Called!!");

                String message = (String) inputMessage.obj;
                //Log.v(TAG, "got message via Handler:" + message);
                switch (inputMessage.what) {
                    case CHANNEL_INT:                 // from channel thread
                        if (message.equals("channel_closed")){
                            Log.v(TAG,"Channel says:" + message);
                            Message messageToSocket = Message.obtain();
                            messageToSocket.what = 1;
                            messageToSocket.obj = "channel_closed";
                            socketHandler.sendMessage(messageToSocket);

                        }
                        break;
                    case BUTTON_INT:
                        int buttonNr = Integer.parseInt(message);
                        if (buttonNr >= 0) {
                            sendMessageWatch(ButtonPath + buttonNr);
                        }
                        break;
                    case SERVER_INT:                 // from server thread
                        if (message.equals("activate_watch")) {
                            Log.v(TAG, "Activate Watch");
                            setStage(1);
                            new sendToWatch().execute(START_WATCH);
                        }else if (message.equals("stop_watch")) {
                            Log.v(TAG, "Stop Watch");
                            setStage(0);
                            new sendToWatch().execute(STOP_WATCH);
                        } else if (message.equals("start_sensordata")) {
                            Log.v(TAG, "Start Sensor Data");
                            setStage(2);
                            new sendToWatch().execute(START_ACTIVITY_PATH);
                        } else if (message.equals("stop_sensordata")) {
                            Log.v(TAG, "Stop Sensor Data");
                            setStage(1);
                            new sendToWatch().execute(STOP_ACTIVITY_PATH);
                        } else if (message.equals("selection")){
                            Log.v(TAG, "Selection");
                            new sendToWatch().execute(SELECTION_PATH);
                        } else if (message.equals("/movie_start")) {
                            Log.v(TAG, "Start movie menu");
                            if (systemStage == 1) setStage(4);
                            else setStage(3);
                        } else if (message.equals("/movie_stop")) {
                            Log.v(TAG, "Stop movie menu");
                            if (systemStage == 4) setStage(1);
                            else setStage(2);
                        } else if (message.equals("/classroom_start")) {
                            Log.v(TAG, "startClassroom");
                            setStage(5);
                        } else if (message.equals("/classroom_question")) {
                            Log.v(TAG, "questionStart");
                            if (systemStage != 6) {
                                setStage(6);
                                new sendToWatch().execute(START_ACTIVITY_PATH);
                            }
                        } else if (message.equals("/classroom_break")) {
                            Log.v(TAG, "questionBreak");
                            if (systemStage != 5) {
                                setStage(5);
                                new sendToWatch().execute(STOP_ACTIVITY_PATH);
                            }
                        }
                        break;
                    default:
                        super.handleMessage(inputMessage);
                }
            }
        };

        // ATTENTION: This "addApi(AppIndex.API)"was auto-generated to implement the App Indexing API.
        // See https://g.co/AppIndexing/AndroidStudio for more information.
        mGoogleApiClient = new GoogleApiClient.Builder(this)
                .addApi(Wearable.API)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .addApi(AppIndex.API).build();
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (!mResolvingError) {
            mGoogleApiClient.connect();
        }
        // ATTENTION: This was auto-generated to implement the App Indexing API.
        // See https://g.co/AppIndexing/AndroidStudio for more information.
        AppIndex.AppIndexApi.start(mGoogleApiClient, getIndexApiAction());
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        if (!mResolvingError && (mGoogleApiClient != null) && (mGoogleApiClient.isConnected())) {
            Wearable.ChannelApi.removeListener(mGoogleApiClient, ChannelComms);
            Wearable.MessageApi.removeListener(mGoogleApiClient, this);

            mGoogleApiClient.disconnect();
        }
        //new sendToWatch().execute(STOP_WATCH);

        super.onStop();// ATTENTION: This was auto-generated to implement the App Indexing API.
// See https://g.co/AppIndexing/AndroidStudio for more information.
        AppIndex.AppIndexApi.end(mGoogleApiClient, getIndexApiAction());
    }

    @Override
    public void onConnected(Bundle connectionHint) {
        Log.v(TAG, "Google API Client was connected");
        new findWatches().execute();
        mResolvingError = false;
        setStage(0);

        iniThreads();

        Wearable.ChannelApi.addListener(mGoogleApiClient, ChannelComms);
        Wearable.MessageApi.addListener(mGoogleApiClient, this);


    }

    @Override
    public void onConnectionSuspended(int cause) {
        Log.v(TAG, "Connection to Google API client was suspended");
        setStage(-1);
    }

    @Override
    public void onConnectionFailed(ConnectionResult result) {
        if (!mResolvingError) {

            if (result.hasResolution()) {
                try {
                    mResolvingError = true;
                    result.startResolutionForResult(this, REQUEST_RESOLVE_ERROR);
                } catch (IntentSender.SendIntentException e) {
                    // There was an error with the resolution intent. Try again.
                    mGoogleApiClient.connect();
                }
            } else {
                Log.e(TAG, "Connection to Google API client has failed");
                mResolvingError = false;
                setStage(-1);

                Wearable.MessageApi.removeListener(mGoogleApiClient, this);
                Wearable.ChannelApi.removeListener(mGoogleApiClient,ChannelComms);
            }
        }
    }

    public void iniThreads(){
        SocketComms = new CommunicateSocket(mHandler);
        SocketComms.start();
        socketHandler = SocketComms.getHandler();
        ChannelComms = new CommunicateChannel(this, mHandler);
        ChannelComms.start();
        channelHandler = ChannelComms.getHandler();
    }

    public void setStage(int stage){
        systemStage = stage;
        mSTATE.setText("STATE = "+systemStage);
        switch (stage){
            case -1:                             // no connection to watch
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(false);
                mStartActivityBtn.setEnabled(false);
                mStopActivityBtn.setEnabled(false);
                setSelectButtons(false);
                break;
            case 0:                             // no active watch
                mActivateBtn.setEnabled(true);
                mStopBtn.setEnabled(false);
                mStartActivityBtn.setEnabled(false);
                mStopActivityBtn.setEnabled(false);
                setSelectButtons(false);
                break;
            case 1:                             // active watch, no data
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(true);
                mStopActivityBtn.setEnabled(false);
                setSelectButtons(false);
                break;
            case 2:                             // active watch, with data
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(false);
                mStopActivityBtn.setEnabled(true);
                setSelectButtons(true);
                break;
            case 3:                             // active watch, with data, within movie
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(false);
                mStopActivityBtn.setEnabled(true);
                setSelectButtons(true);
                break;
            case 4:                             // active watch, no data, within movie
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(true);
                mStopActivityBtn.setEnabled(false);
                setSelectButtons(false);
                break;
            case 5:                             // active watch, no data, within Classroom
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(true);
                mStopActivityBtn.setEnabled(false);
                setSelectButtons(false);
                break;
            case 6:                             // active watch, with data, within Classroom (Question Time)
                mActivateBtn.setEnabled(false);
                mStopBtn.setEnabled(true);
                mStartActivityBtn.setEnabled(false);
                mStopActivityBtn.setEnabled(true);
                setSelectButtons(true);
                break;
            default:
                Log.wtf(TAG, "Should never occur! Default in Stage");
                break;
        }

    }

    @Override
    public void onMessageReceived(final MessageEvent messageEvent) {
        if (messageEvent.getPath().equals("/enable_latencyTest")) {
            Log.d(TAG, "Latency test enabled!");
            ChannelComms.Ini.function_b();
        } else if (messageEvent.getPath().equals(WATCH_FLICK)) {
            Log.d(TAG, "Watch flick!");
            if (systemStage == 1) { // watch wants to start sending data
                sendSelect(2);
                setStage(2);
            } else if (systemStage == 2) {      // watch is already sending data, so stop
                sendSelect(3);
                setStage(1);
            } else if (systemStage == 3) {
                Message messageToSocket = Message.obtain();
                messageToSocket.what = 6;
                messageToSocket.obj = "toggle menu";
                socketHandler.sendMessage(messageToSocket);
            } else if (systemStage == 4) {      // watch is not sending data, so start, though within movie!
                sendSelect(2);
                setStage(3);
            } else if (systemStage == 5 || systemStage == 6) {    // the application controlls whether data is send
                // do not respond to FLICK
            } else {
                Log.wtf(TAG, "received FLICK during impossible stage!");
            }
        } else if (messageEvent.getPath().equals(HAND_RIGHT)){
            sendSelect(4);
        } else if (messageEvent.getPath().equals(HAND_LEFT)){
            sendSelect(5);
        } else {
            Log.v(TAG, "onMessageReceived() A message from watch was received:"
                    + messageEvent.getRequestId() + " " + messageEvent.getPath());
        }
    }


    /**
     * Sets up UI components and their callback handlers.
     */
    private void setupViews() {
        mActivateBtn = findViewById(R.id.activate_watch);
        mStopBtn = findViewById(R.id.stop_watch);
        mStartActivityBtn = findViewById(R.id.start_sensordata);
        mStopActivityBtn = findViewById(R.id.stop_sensordata);
        mToggleMenu = findViewById(R.id.togglemenu);
        mSTATE = (TextView) findViewById(R.id.stateVIEW);

        ViewGroup row = (ViewGroup) findViewById(R.id.row3);
        int buttonIndex = 0;
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);
        row = (ViewGroup) findViewById(R.id.row4);
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);
        row = (ViewGroup) findViewById(R.id.row6);
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);
        row = (ViewGroup) findViewById(R.id.row7);
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);
        row = (ViewGroup) findViewById(R.id.row8);
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);
        row = (ViewGroup) findViewById(R.id.row9);
        for (int index = 0; index<row.getChildCount();index++, buttonIndex++)
            selectButtons[buttonIndex] = row.getChildAt(index);

        mToggleMenu.setEnabled(true);
    }

    /**
     * Sends an RPC to start a fullscreen Activity on the wearable.
     */
    public void onStartWearableActivityClick(View view) {
        Log.v(TAG, "Start Wearable");
        mStartActivityBtn.setEnabled(false);
        new sendToWatch().execute(START_ACTIVITY_PATH);
    }

    public void onStopWearableActivityClick(View view) {
        Log.v(TAG, "Stop Wearable");
        ChannelComms.mChannel_Open = false;
        mStopActivityBtn.setEnabled(false);

        //TODO: prevent buttons being press if smartwatch is not ready yet for initiation (channel mixup). Handshake method.

        // Trigger an AsyncTask that will query for a list of connected nodes and send a
        // "start-activity" message to each connected node.
        new sendToWatch().execute(STOP_ACTIVITY_PATH);
    }

    public void onSelectStart(View view) {sendSelect(0); setStage(1);}
    public void onSelectStop(View view) {sendSelect(1); setStage(0);}
    public void onSelectStartData(View view) {sendSelect(2); setStage(2);}
    public void onSelectStopData(View view) {sendSelect(3); setStage(1);}
    public void toggleMenu(View view) {
        Message messageToSocket = Message.obtain();
        messageToSocket.what = 6;
        messageToSocket.obj = "toggle menu";
        socketHandler.sendMessage(messageToSocket);
    }
    public void onSelect1(View view) {sendSelect(10);}
    public void onSelect2(View view) {sendSelect(11);}
    public void onSelect3(View view) {sendSelect(12);}
    public void onSelect4(View view) {sendSelect(13);}
    public void onSelect5(View view) {sendSelect(14);}
    public void onSelect6(View view) {sendSelect(15);}
    public void onSelect7(View view) {sendSelect(16);}
    public void onSelect8(View view) {sendSelect(17);}
    public void onSelect9(View view) {sendSelect(18);}
    public void onSelect10(View view) {sendSelect(19);}
    public void onSelect11(View view) {sendSelect(20);}
    public void onSelect12(View view) {sendSelect(21);}
    public void onSelect13(View view) {sendSelect(22);}
    public void onSelect14(View view) {sendSelect(23);}
    public void onSelect15(View view) {sendSelect(24);}
    public void onSelect16(View view) {sendSelect(25);}
    public void onSelect17(View view) {sendSelect(26);}
    public void onSelect18(View view) {sendSelect(27);}
    public void onSelect19(View view) {sendSelect(28);}
    public void onSelect20(View view) {sendSelect(29);}
    public void onSelect21(View view) {sendSelect(30);}
    public void onSelect22(View view) {sendSelect(31);}
    public void onSelect23(View view) {sendSelect(32);}
    public void onSelect24(View view) {sendSelect(33);}
    public void onSelect25(View view) {sendSelect(34);}
    public void onSelect26(View view) {sendSelect(35);}
    public void onSelect27(View view) {sendSelect(36);}
    public void onSelect28(View view) {sendSelect(37);}
    public void onSelect29(View view) {sendSelect(38);}
    public void onSelect30(View view) {sendSelect(39);}
    public void onSelect31(View view) {sendSelect(40);}
    public void onSelect32(View view) {sendSelect(41);}

    private void sendSelect(int nr_button) {
        String[] MessagePath = {
                START_WATCH,
                STOP_WATCH,
                START_ACTIVITY_PATH,
                STOP_ACTIVITY_PATH,
                HAND_RIGHT,
                HAND_LEFT
        };
        if (nr_button < 10) new sendToWatch().execute(MessagePath[nr_button]);
        else new sendToWatch().execute(ButtonPath+String.valueOf(nr_button-10));
    }

    /**
     * ATTENTION: This was auto-generated to implement the App Indexing API.
     * See https://g.co/AppIndexing/AndroidStudio for more information.
     */
    public Action getIndexApiAction() {
        Thing object = new Thing.Builder()
                .setName("Main Page") // TODO: Define a title for the content shown.
                // TODO: Make sure this auto-generated URL is correct.
                .setUrl(Uri.parse("http://[ENTER-YOUR-URL-HERE]"))
                .build();
        return new Action.Builder(Action.TYPE_VIEW)
                .setObject(object)
                .setActionStatus(Action.STATUS_TYPE_COMPLETED)
                .build();
    }


    private class findWatches extends AsyncTask<Void, Void, Void> {
        @Override
        protected Void doInBackground(Void... args) {
            nodes = getNodes();
            return null;
        }
    }

    private Collection<String> getNodes() {
        HashSet<String> results = new HashSet<>();
        NodeApi.GetConnectedNodesResult nodes =
                Wearable.NodeApi.getConnectedNodes(mGoogleApiClient).await();

        for (Node node : nodes.getNodes()) {
            results.add(node.getId());
        }

        return results;
    }

    private class sendToWatch extends AsyncTask<String, Void, Void> {
        @Override
        protected Void doInBackground(String ...message) {
            sendMessageWatch(message[0]);
            return null;
        }
    }

    public class DataMapKeys {
        public static final String ACCURACY = "accuracy";
        public static final String TIMESTAMP = "timestamp";
        public static final String VALUES = "values";
        public static final String FILTER = "filter";
        public static final String ARRAY = "array";
        public static final String CHANNEL = "channel";
    }


    public void sendMessageWatch(final String mMessage) {
        for (String node : nodes) {
            Wearable.MessageApi.sendMessage(
                    mGoogleApiClient, node, mMessage, new byte[0]).setResultCallback(
                    new ResultCallback<SendMessageResult>() {
                        @Override
                        public void onResult(SendMessageResult sendMessageResult) {
                            if (!sendMessageResult.getStatus().isSuccess()) {
                                Log.e(TAG, "Failed to send message with status code: "
                                        + sendMessageResult.getStatus().getStatusCode());
                            } else {
                                Log.d(TAG, "send to watch: " + mMessage);
                            }
                        }
                    }
            );
        }
    }

    public void setSelectButtons(boolean onoff){
        for (int i=0; i<selectButtons.length;i++){
            selectButtons[i].setEnabled(onoff);
        }
    }
}