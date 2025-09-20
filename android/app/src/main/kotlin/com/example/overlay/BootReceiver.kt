package com.enrich.ideamemo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        val action = intent?.action
        Log.d(TAG, "Boot event received: $action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d(TAG, "Starting LockScreenService automatically")
                startLockScreenService(context)
            }
            "WATCHDOG_CHECK" -> {
                Log.d(TAG, "🐕 Watchdog check - ensuring service is running")
                startLockScreenService(context)
            }
            "RESTART_SERVICE" -> {
                Log.d(TAG, "🚨 Emergency restart triggered")
                startLockScreenService(context)
            }
        }
    }
    
    private fun startLockScreenService(context: Context?) {
        context?.let {
            try {
                val serviceIntent = Intent(it, LockScreenService::class.java)
                it.startForegroundService(serviceIntent)
                Log.d(TAG, "✅ LockScreenService started/restarted")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to start LockScreenService: ${e.message}")
            }
        }
    }
}
