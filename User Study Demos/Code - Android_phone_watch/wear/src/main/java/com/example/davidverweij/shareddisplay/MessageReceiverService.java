package com.example.davidverweij.shareddisplay;

import android.content.Intent;
import android.util.Log;

import com.google.android.gms.wearable.MessageEvent;
import com.google.android.gms.wearable.WearableListenerService;

public class MessageReceiverService extends WearableListenerService {
    private static final String TAG = "MessageService";
    private static final String START_WATCH = "/wavetrace_start_watch";
    private static final String STOP_WATCH = "/wavetrace_stop_watch";
    private static final String START_ACTIVITY_PATH = "/wavetrace_start_shared_display";
    private static final String STOP_ACTIVITY_PATH = "/wavetrace_stop_shared_display";
    private static final String BUTTON = "/wavetrace_show_button";
    private static final String SELECTION = "/wavetrace_selection_true";
    private static final String HAND_RIGHT = "/wavetrace_hand_right";
    private static final String HAND_LEFT = "/wavetrace_hand_left";

    private DeviceClient deviceClient;

    @Override
    public void onCreate() {
        super.onCreate();
        deviceClient = DeviceClient.getInstance(this);
    }

    // https://developer.android.com/wear/preview/features/gestures.html


    @Override
    public void onMessageReceived(MessageEvent messageEvent) {
        String messageRaw = messageEvent.getPath();
        if (messageRaw.equals(START_WATCH)) {

            Log.d(TAG, "Activate Watch !");
            String node = messageEvent.getSourceNodeId();
            deviceClient.startWatch(0, node);
            startService(new Intent(this, SensorService.class));

        } else if (messageRaw.equals(STOP_WATCH)) {

            Log.d(TAG, "Stop Watch!");
            String node = messageEvent.getSourceNodeId();
            deviceClient.startWatch(-1, node);
            stopService(new Intent(this, SensorService.class));

        }  else if (messageRaw.equals(START_ACTIVITY_PATH)) {

            Log.d(TAG, "Start Sensorchannel !");
            String node = messageEvent.getSourceNodeId();
            deviceClient.startWatch(1, node);

        }  else if (messageRaw.equals(STOP_ACTIVITY_PATH)) {

            Log.d(TAG, "Stop SensorChannel !");
            String node = messageEvent.getSourceNodeId();
            deviceClient.startWatch(0, node);

        } else if (messageRaw.equals(SELECTION)) {
            Log.d(TAG, "Selection");
            deviceClient.selection();
        } else if (messageRaw.startsWith(BUTTON)) {
            int button_nr = Integer.parseInt(messageRaw.substring(23));
            Log.d(TAG, "Button_"+button_nr);
            deviceClient.goToPage(button_nr);
        } else if (messageRaw.equals(HAND_RIGHT)) {
            deviceClient.setHand(true);
        }else if (messageRaw.equals(HAND_LEFT)) {
            deviceClient.setHand(false);
        }else {
            Log.wtf(TAG,"Error, default in message receive watch");
        }

    }


}
