package com.example.davidverweij.shareddisplay.fragments;

import android.app.Activity;
import android.app.Fragment;
import android.content.Context;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CompoundButton;
import android.widget.TextView;
import android.widget.ToggleButton;

import com.example.davidverweij.shareddisplay.MainActivity;
import com.example.davidverweij.shareddisplay.R;

/**
 * Created by davidverweij on 20/01/2017.
 */

public class DefaultFrag extends Fragment {
    private View view;
    private TextView mStatusText;
    ToggleButton toggle;
    onToggleListener mListener;


    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    public interface onToggleListener {
        public void onToggle(boolean _hand);
    }

    @Override
    public void onAttach(Context context) {
        super.onAttach(context);

        // This makes sure that the container activity has implemented
        // the callback interface. If not, it throws an exception
        try {
            mListener = (onToggleListener) context;
        } catch (ClassCastException e) {
            throw new ClassCastException(context.toString() + " must implement onToggleListener");
        }
    }

    @Override
    public void onDetach() {
        mListener = null; // => avoid leaking, thanks @Deepscorn
        super.onDetach();
    }


    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.default_page, container, false);


        mStatusText = (TextView) view.findViewById(R.id.status);
        toggle = (ToggleButton) view.findViewById(R.id.toggleButton);
        toggle.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if (isChecked) {            //right
                    mListener.onToggle(true);
                } else {
                    mListener.onToggle(false);//left
                    // The toggle is disabled
                }
            }
        });

        return view;
    }
}
