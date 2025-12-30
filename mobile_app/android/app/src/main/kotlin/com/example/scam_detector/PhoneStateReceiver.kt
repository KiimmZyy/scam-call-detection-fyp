package com.example.scam_detector

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("PhoneStateReceiver", "Received intent: ${intent?.action}")
    }
}
