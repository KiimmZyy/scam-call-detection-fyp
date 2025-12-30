package com.example.scam_detector

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class CallMonitorService : Service() {

    override fun onCreate() {
        super.onCreate()
        Log.d("CallMonitorService", "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("CallMonitorService", "Service started")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "call_monitor_channel"
            val channelName = "Call Monitor"
            val nm = getSystemService(NotificationManager::class.java)
            nm?.createNotificationChannel(
                NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            )
            val notification = Notification.Builder(this, channelId)
                .setContentTitle("Call Monitoring")
                .setContentText("Service is running")
                .setSmallIcon(android.R.drawable.stat_sys_phone_call)
                .build()
            startForeground(1001, notification)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        Log.d("CallMonitorService", "Service destroyed")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
