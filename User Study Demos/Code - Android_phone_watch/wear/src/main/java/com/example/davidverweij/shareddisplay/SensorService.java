package com.example.davidverweij.shareddisplay;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;

import java.util.Collections;
import java.util.List;

public class SensorService extends Service implements SensorEventListener {

    private static final String TAG = "SensorService";
    private final static int SENS_ROTATION_VECTOR = Sensor.TYPE_ROTATION_VECTOR;
    private final static float yaw_boundary = 3.05432619f;
    private boolean flipped_orientation;
    private final int roll_window = 75;
    private float[] rollValues = new float[roll_window];
    private int rollValues_i = 0;
    private float rollThreshold = 1f;

    SensorManager mSensorManager;


    private DeviceClient client;

    @Override
    public void onCreate() {
        super.onCreate();

        client = DeviceClient.getInstance(this);
        flipped_orientation = false;
        startMeasurement();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        stopMeasurement();
    }


    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    protected void startMeasurement() {
        mSensorManager = ((SensorManager) getSystemService(SENSOR_SERVICE));
        Sensor rotationVectorSensor = mSensorManager.getDefaultSensor(SENS_ROTATION_VECTOR);

        // Register the listener
        if (mSensorManager != null) {
            if (rotationVectorSensor != null) {
                mSensorManager.registerListener(this, rotationVectorSensor, SensorManager.SENSOR_DELAY_FASTEST);
            } else {
                LOGD(TAG, "NoRotationVector");
            }
        }
    }

    private void stopMeasurement() {
        if (mSensorManager != null) {
            mSensorManager.unregisterListener(this);
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        long current_time = System.currentTimeMillis();
        long elapsed_real_time = SystemClock.elapsedRealtimeNanos();
        long sensor_timestamp = current_time+((event.timestamp-elapsed_real_time)/1000000);               // see https://code.google.com/p/android/issues/detail?id=7981

        // this code potentially slows down the program
        float[] rotationV = new float[16];
        float[] remappedRotationV = new float[16];
        float[] orientationValuesV = new float[3];

        SensorManager.getRotationMatrixFromVector(rotationV, event.values);

        if (flipped_orientation){
            SensorManager.remapCoordinateSystem(rotationV, SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y, remappedRotationV);
            SensorManager.getOrientation(remappedRotationV, orientationValuesV);        // 3 values: yaw,roll,pitch (in that order)
        } else {
            SensorManager.getOrientation(rotationV, orientationValuesV);        // 3 values: yaw,roll,pitch (in that order)
            orientationValuesV[1] = -1*orientationValuesV[1];                   // adjust for negative relation roll
            orientationValuesV[2] = -1*orientationValuesV[2];                   // adjust for negative relation pitch
        }


        client.sendSensorData(event.sensor.getType(), event.accuracy, sensor_timestamp, orientationValuesV);
/*
        rollValues[rollValues_i%roll_window] = orientationValuesV[1];

        float small = Float.MAX_VALUE;
        for (int i = 0; i < rollValues.length; i++) {
            if (rollValues[i] < small) {
                small = rollValues[i];
            }
        }

        if (rollValues_i > 2*roll_window) {

            if (orientationValuesV[1] - small > rollThreshold) {
                client.sendSensorData("/FLICK");
                rollValues = new float[roll_window];
                rollValues_i = 0;
            }
        }
        rollValues_i++;
*/

        // here we account for the -180/180 flip moment, by remapping the coordinate system
        // our boundary is -175 and 175. this is -3.05432619 rad and 3.05432619 rad
        // this has effect on the next sensor reading, not this one
        if (orientationValuesV[0]>yaw_boundary || orientationValuesV[0]<-yaw_boundary){
            flipped_orientation = !flipped_orientation;
            rollValues = new float[roll_window];
            client.sendSensorData("/FLIPPED");        // send message
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }
    public static void LOGD(final String tag, String message) {
        if (Log.isLoggable(tag, Log.DEBUG)) {
            Log.d(tag, message);
        }
    }
}
