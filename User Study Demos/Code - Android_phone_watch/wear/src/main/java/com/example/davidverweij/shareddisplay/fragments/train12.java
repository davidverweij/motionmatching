package com.example.davidverweij.shareddisplay.fragments;

import android.app.Fragment;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.example.davidverweij.shareddisplay.R;

import java.util.Calendar;

/**
 * Created by davidverweij on 20/01/2017.
 */

public class train12 extends Fragment {
    private View view;
    private TextView[] times = new TextView[25];
    private TextView currentTime;
    private TextView mStatusText;

    @Override
    public void onCreate(Bundle savedInstanceState) {

        super.onCreate(savedInstanceState);
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.train2, container, false);

        currentTime = (TextView)view.findViewById(R.id.currentTime);

        Calendar rightNow = Calendar.getInstance();
        int currentHour = rightNow.get(Calendar.HOUR_OF_DAY); // return the hour in 24 hrs format (ranging from 0-23)
        int currentMinute = rightNow.get(Calendar.MINUTE);

        currentTime.setText(currentHour + ":" + currentMinute);

        int startHour = -13;
        if (currentMinute > 32)              // if later then the minute, the minute takes place in the next hour
            currentHour++;

        String thisHour = String.format("%02d",currentHour);
        String nextHour = String.format("%02d",currentHour+1);
        String nextnextHour = String.format("%02d",currentHour+2);

        String[][] traintimes = {
                {thisHour,"32"},
                {thisHour,"51"},
                {thisHour,"53"},
                {nextHour,"21"},
                {nextHour,"23"},
                {nextHour,"42"},
                {nextHour,"42"},
                {nextHour,"50"},
                {nextHour,"54"},
                {nextHour,"59"},
                {nextnextHour,"00"},
                {nextnextHour,"06"},
                {nextnextHour,"06"},
                {nextnextHour,"19"},
                {nextnextHour,"19"},
                {nextnextHour,"28"},
                {nextnextHour,"36"},
                {nextnextHour,"39"},
                {nextnextHour,"39"},
                {nextnextHour,"43"},
                {nextnextHour,"44"},
                {nextnextHour,"53"},

        };

        ViewGroup ad = (ViewGroup)view.findViewById(R.id.adjustables);
        ViewGroup time =(ViewGroup)view.findViewById(R.id.times);
        int ads = ad.getChildCount();
        int tim = time.getChildCount();
        times = new TextView[tim];

        for(int index=0; index<tim && index<traintimes.length; ++index) {
            times[index] = (TextView) time.getChildAt(index);
            times[index].setText(traintimes[index][0] + ":" + traintimes[index][1]);
        }

        return view;
    }

}
