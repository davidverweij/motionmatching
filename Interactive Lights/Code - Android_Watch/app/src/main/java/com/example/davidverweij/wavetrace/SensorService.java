package com.example.davidverweij.wavetrace;

/**
 * Created by davidverweij on 05/08/2017.
 */

import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.IBinder;
import android.os.SystemClock;
import android.util.Log;
import android.widget.TextView;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

public class SensorService extends Service implements SensorEventListener {

  /*
     This class is the primary program. It records movement and sends it of Wi-Fi to a static IP adress on the network over UDP.
     The other MainActivity class shows the wearable app, and a button to switch from left to right hand.

  */

    private static final String TAG = "SensorService";
    private final static int SENS_ROTATION_VECTOR = Sensor.TYPE_ROTATION_VECTOR;
    private final static float yaw_boundary = 3.05432619f;
    private boolean flipped_orientation;
    private final int roll_window = 75;
    private float[] rollValues = new float[roll_window];
    private int rollValues_i = 0;
    private float rollThreshold = 1f;
    private Context context;



    SensorManager mSensorManager;

    private static final String host = "192.168.0.150";   // Change this IP adress to your Raspberry PI/Laptop endpoint
    private int port = 6628;
    DatagramSocket client_socket;
    InetAddress IPAddress;
    byte[] send_data = new byte[2048];
    byte[] receiveData = new byte[2048];
    String modifiedSentence;


    private MainActivity client;

    @Override
    public void onCreate() {
        super.onCreate();

        this.context = context;
        Log.v("TAG","STARTED SENSOR SERVICE");

        client = MainActivity.getInstance(this);
        flipped_orientation = false;

        try {
            client_socket = new DatagramSocket(port);
            IPAddress =  InetAddress.getByName(host);
        } catch (IOException e) {
            client.updateStatus(2);
            //System.out.println("ERROR NETWORK:" + e);
        }



        startMeasurement();
    }

    @Override
    public void onDestroy() {
        stopMeasurement();
        client_socket.close();
        super.onDestroy();
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
                mSensorManager.registerListener(this, rotationVectorSensor, SensorManager.SENSOR_DELAY_FASTEST);    //retreived sensor changes very fast!
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

        try {
            udp(event.sensor.getType(), event.accuracy, sensor_timestamp, orientationValuesV);
            client.updateStatus(0);

        } catch (IOException e) {
            //System.out.println("ERROR UDP:" + e);
            client.updateStatus(1);

        }

        // here we account for the -180/180 flip moment, by remapping the coordinate system
        // our boundary is -175 and 175. this is -3.05432619 rad and 3.05432619 rad
        // this has effect on the next sensor reading, not this one
        if (orientationValuesV[0]>yaw_boundary || orientationValuesV[0]<-yaw_boundary){
            flipped_orientation = !flipped_orientation;
            rollValues = new float[roll_window];
            //client.sendSensorData("/FLIPPED");        // send message
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

    public void udp(int sensorType, int accuracy, long timestamp, float[] values) throws IOException {

        //  yaw, roll, pitch
       /* String message = Long.toString(timestamp)
                + ";" + sensorType
                + ";" + accuracy;
*/
            String message= roundFloat(values[0])            //allow for 2 decimals. However, data will be multiplied to make integers
                    + ";" + roundFloat(values[1])
                    + ";" + roundFloat(values[2]);


        send_data = message.getBytes();
        //Log.v("TAG",message);
        DatagramPacket send_packet = new DatagramPacket(send_data,message.length(), IPAddress, port);
        client_socket.send(send_packet);
        //DatagramPacket receivePacket = new DatagramPacket(receiveData, receiveData.length);
        //client_socket.receive(receivePacket);
        //modifiedSentence = new String(receivePacket.getData());
        //System.out.println("FROM SERVER:" + modifiedSentence);
        //modifiedSentence=null;
        //Log.v("TAG","SEND MESSAGE TO" + IPAddress);
    }

    public static String roundFloat(float value) {
        BigDecimal bd = new BigDecimal(Float.toString(value*100));  // should provide us with no decimals, and values*100 to ignore small movements
        bd = bd.setScale(0, BigDecimal.ROUND_HALF_UP);
        return bd.toString();
    }
}
