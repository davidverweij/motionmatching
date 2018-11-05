package com.example.davidverweij.wavetrace;

import com.example.davidverweij.wavetrace.R;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.support.wearable.activity.WearableActivity;
import android.widget.TextView;
import android.view.View;
import android.support.wearable.view.BoxInsetLayout;
import android.util.Log;
import android.view.View;


public class MainActivity extends WearableActivity {


    private TextView subtitleView;

    public static MainActivity instance;

    public static MainActivity getInstance(Context context) {
        if (instance == null) {
            instance = new MainActivity();
        }
        return instance;
    }

    public void updateStatus(int i){
      /*
        Shows program status on the watch.
        This is not implemented yet
      */
        if (subtitleView!=null) {
            switch (i) {
                case 0:
                    subtitleView.setText("@strings/running");
                    break;
                case 1:
                    subtitleView.setText("@strings/noUDP");
                    break;
                case 2:
                    subtitleView.setText("@strings/noWIFI");
                    break;

            }
        }

    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        setAmbientEnabled();

        //subtitleView = (TextView) findViewById(R.id.subtitle);
    }

    @Override
    protected void onStart(){
        startService(new Intent(this, SensorService.class));
        super.onStart();

    }

    @Override
    protected void onStop(){
        stopService(new Intent(this, SensorService.class));
        super.onStop();

    }

    @Override
    public void onEnterAmbient(Bundle ambientDetails) {
        super.onEnterAmbient(ambientDetails);

    }

    @Override
    public void onUpdateAmbient() {
        super.onUpdateAmbient();

    }

    @Override
    public void onExitAmbient() {
        super.onExitAmbient();
    }


}
