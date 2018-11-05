package com.example.davidverweij.shareddisplay;

import android.app.Activity;
import android.app.Fragment;
import android.app.FragmentManager;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.wearable.view.FragmentGridPagerAdapter;
import android.support.wearable.view.GridViewPager;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Window;
import android.view.WindowManager;

import com.example.davidverweij.shareddisplay.fragments.DefaultFrag;
import com.example.davidverweij.shareddisplay.fragments.answer_correct;
import com.example.davidverweij.shareddisplay.fragments.answer_wrong;
import com.example.davidverweij.shareddisplay.fragments.colour_blue;
import com.example.davidverweij.shareddisplay.fragments.colour_green;
import com.example.davidverweij.shareddisplay.fragments.colour_purple;
import com.example.davidverweij.shareddisplay.fragments.colour_yellow;
import com.example.davidverweij.shareddisplay.fragments.political1;
import com.example.davidverweij.shareddisplay.fragments.political2;
import com.example.davidverweij.shareddisplay.fragments.political3;
import com.example.davidverweij.shareddisplay.fragments.political4;
import com.example.davidverweij.shareddisplay.fragments.political5;
import com.example.davidverweij.shareddisplay.fragments.political6;
import com.example.davidverweij.shareddisplay.fragments.train1;
import com.example.davidverweij.shareddisplay.fragments.train10;
import com.example.davidverweij.shareddisplay.fragments.train11;
import com.example.davidverweij.shareddisplay.fragments.train12;
import com.example.davidverweij.shareddisplay.fragments.train13;
import com.example.davidverweij.shareddisplay.fragments.train14;
import com.example.davidverweij.shareddisplay.fragments.train15;
import com.example.davidverweij.shareddisplay.fragments.train16;
import com.example.davidverweij.shareddisplay.fragments.train17;
import com.example.davidverweij.shareddisplay.fragments.train18;
import com.example.davidverweij.shareddisplay.fragments.train19;
import com.example.davidverweij.shareddisplay.fragments.train2;
import com.example.davidverweij.shareddisplay.fragments.train20;
import com.example.davidverweij.shareddisplay.fragments.train3;
import com.example.davidverweij.shareddisplay.fragments.train4;
import com.example.davidverweij.shareddisplay.fragments.train5;
import com.example.davidverweij.shareddisplay.fragments.train6;
import com.example.davidverweij.shareddisplay.fragments.train7;
import com.example.davidverweij.shareddisplay.fragments.train8;
import com.example.davidverweij.shareddisplay.fragments.train9;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.wearable.MessageApi;
import com.google.android.gms.wearable.Wearable;

import java.util.ArrayList;
import java.util.List;


/**
 * Created by davidverweij on 20/01/2017.
 */

public class MainActivity extends Activity implements KeyEvent.Callback, DefaultFrag.onToggleListener {

    private static final String TAG = "ScreenSharedDisplay";
    private static final String WATCH_FLICK = "/wavetrace_watch_flick";
    private static final String HAND_RIGHT = "/wavetrace_hand_right";
    private static final String HAND_LEFT = "/wavetrace_hand_left";
    private GridViewPager mPager;
    private MyPagerAdapter adapter;
    private ArrayList<Fragment> Frags = new ArrayList<Fragment>();
    private ArrayList<Fragment> addFrags = new ArrayList<Fragment>();

    private boolean keep;
    private int page;
    private String watchNode;
    PowerManager.WakeLock wakeLock;
    PowerManager powerManager;
    private GoogleApiClient mGoogleApiClient;

    private boolean channel_started = false;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent intent = this.getIntent();
        Bundle b = intent.getExtras();
        keep = b.getBoolean("boolean");

        if(keep==true)
        {
            watchNode = b.getString("node");
            setContentView(R.layout.main_activity);
            powerManager = (PowerManager) getSystemService(Context.POWER_SERVICE);
            wakeLock = powerManager.newWakeLock(PowerManager.FULL_WAKE_LOCK,
                    "MyWakelockTag");
            wakeLock.acquire();
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

            Window window = this.getWindow();
            if(window != null) {
                WindowManager.LayoutParams lp = window.getAttributes();
                lp.screenBrightness = 1;
                window.setAttributes(lp);
            }

            mGoogleApiClient = new GoogleApiClient.Builder(this)
                    .addApi(Wearable.API)
                    .build();

            mGoogleApiClient.connect();



            setupViews();
            Log.v(TAG,"Acitivity Started");
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        Intent intent = this.getIntent();
        Bundle b = intent.getExtras();
        boolean temp_keep = b.getBoolean("boolean");
        if(!temp_keep)
        {
            this.finish();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
    }

    @Override
    protected void onStop() {
        wakeLock.release();
        Log.v(TAG,"WakeLock Closed");
        super.onStop();
    }


    private void setupViews() {
        mPager = (GridViewPager) findViewById(R.id.pager);      // refers to screen view
        mPager.setOffscreenPageCount(0);                        // amount of pages outside screen
        mPager.setSlideAnimationDuration(0);
        //DotsPageIndicator dotsPageIndicator = (DotsPageIndicator) findViewById(R.id.page_indicator);
        //dotsPageIndicator.setDotSpacing((int) getResources().getDimension(R.dimen.dots_spacing));
        //dotsPageIndicator.setPager(mPager);
        Frags.add(new DefaultFrag());
        addFrags.add(new answer_wrong());           //button 0
        addFrags.add(new answer_correct());         //button 1
        addFrags.add(new colour_blue());            // ...
        addFrags.add(new colour_green());
        addFrags.add(new colour_purple());
        addFrags.add(new colour_yellow());
        addFrags.add(new political1());
        addFrags.add(new political2());
        addFrags.add(new political3());
        addFrags.add(new political4());
        addFrags.add(new political5());
        addFrags.add(new political6());
        addFrags.add(new train1());
        addFrags.add(new train2());
        addFrags.add(new train3());
        addFrags.add(new train4());
        addFrags.add(new train5());
        addFrags.add(new train6());
        addFrags.add(new train7());
        addFrags.add(new train8());
        addFrags.add(new train9());
        addFrags.add(new train10());
        addFrags.add(new train11());
        addFrags.add(new train12());
        addFrags.add(new train13());
        addFrags.add(new train14());
        addFrags.add(new train15());
        addFrags.add(new train16());
        addFrags.add(new train17());
        addFrags.add(new train18());
        addFrags.add(new train19());
        addFrags.add(new train20());


        adapter = new MyPagerAdapter(getFragmentManager(), Frags);
        mPager.setAdapter(adapter);
        mPager.requestFocus();
    }

    /**
     * Switches to the page {@code index}. The first page has index 0.
     */
    private void moveToPage(int index) {
        if (Frags.size()>1) Frags.remove(1);
        if (index != 99) {
            Frags.add(addFrags.get(index));
            adapter.notifyChangeInPosition(1);
            adapter.notifyDataSetChanged();
            mPager.setCurrentItem(0, 1, true);
        } else {
            adapter.notifyChangeInPosition(1);
            adapter.notifyDataSetChanged();
            mPager.setCurrentItem(0, 0, true);

        }
    }

    private class MyPagerAdapter extends FragmentGridPagerAdapter {

        private List<Fragment> mFragments;
        private long baseId = 0;

        public MyPagerAdapter(FragmentManager fm, List<Fragment> fragments) {
            super(fm);
            mFragments = fragments;
        }

        public int getCount() {
            return mFragments.size();
        }

        @Override
        public int getRowCount() {
            return 1;
        }

        @Override
        public int getColumnCount(int row) {
            return mFragments == null ? 0 : mFragments.size();
        }

        @Override
        public Fragment getFragment(int row, int column) {
            return mFragments.get(column);
        }

        public void notifyChangeInPosition(int n) {
            // shift the ID returned by getItemId outside the range of all previous fragments
            baseId += getCount() + n;
        }


    }


    @Override
    protected void onNewIntent(Intent intent)
    {
        super.onNewIntent(intent);

        Bundle b = intent.getExtras();
        boolean temp_keep = b.getBoolean("boolean");
        if(!temp_keep)
        {
            this.finish();
        }
        page = intent.getExtras().getInt("page");
        moveToPage(page);
    }

    @Override
    public void onToggle(boolean _hand){
     new handMessage().execute(_hand);
    }

    public class handMessage extends AsyncTask<Boolean, Void, Void> {

        @Override
        protected Void doInBackground(Boolean ...hand) {
            hand_msg(watchNode, hand[0]);
            return null;
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
                mGoogleApiClient, node, MessagePath, new byte[0]).setResultCallback(
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

    private void hand_msg(String node, Boolean hand) {
        String MessagePath;
        if (hand) MessagePath = HAND_RIGHT;
        else MessagePath = HAND_LEFT;
        Wearable.MessageApi.sendMessage(
                mGoogleApiClient, node, MessagePath, new byte[0]).setResultCallback(
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

    public void sendFlick(){
        new flickMessage().execute();
    }

    @Override /* KeyEvent.Callback */
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_NAVIGATE_NEXT:
                Log.d(TAG, "UP/NEXT");
                new flickMessage().execute();
                break;
            case KeyEvent.KEYCODE_NAVIGATE_PREVIOUS:
                Log.d(TAG, "DOWN/PREV");
                new flickMessage().execute();
                break;
        }
        // If you did not handle, then let it be handled by the next possible element as deemed by
        // Activity.
        return super.onKeyDown(keyCode, event);
    }


}
