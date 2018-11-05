package com.example.davidverweij.shareddisplay.fragments;

import android.app.Fragment;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.example.davidverweij.shareddisplay.R;

/**
 * Created by davidverweij on 20/01/2017.
 */

public class political6 extends Fragment {
    private View view;
    private TextView mStatusText;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        view = inflater.inflate(R.layout.political6, container, false);

        return view;
    }
}
