package com.enrich.ideamemo.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat

class LockScreenService : Service() {
    companion object {
        private const val TAG = "LockScreenService"
        private const val CHANNEL_ID = "lockscreen_service_channel"
        private const val NOTIFICATION_ID = 1001
    }
    
    private var screenStateReceiver: ScreenStateReceiver? = null

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "LockScreenService created")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        registerScreenStateReceiver()
        setupWatchdog() // 백업 시스템 설정
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "LockScreenService started")
        
        // 더 강력한 재시작 정책
        return START_STICKY or START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.d(TAG, "🚨 LockScreenService destroyed - attempting restart!")
        unregisterScreenStateReceiver()
        
        // 서비스가 죽을 때 즉시 재시작 시도
        restartService()
        
        super.onDestroy()
    }
    
    private fun restartService() {
        try {
            val restartIntent = Intent(this, LockScreenService::class.java)
            startForegroundService(restartIntent)
            Log.d(TAG, "🔄 Service restart attempted")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to restart service: ${e.message}")
            
            // 백업 재시작 방법: AlarmManager 사용
            scheduleServiceRestart()
        }
    }
    
    private fun scheduleServiceRestart() {
        try {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(this, BootReceiver::class.java).apply {
                action = "RESTART_SERVICE"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this, 999, intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 10초 후 재시작
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.ELAPSED_REALTIME_WAKEUP,
                SystemClock.elapsedRealtime() + 10000,
                pendingIntent
            )
            
            Log.d(TAG, "🚨 Emergency restart scheduled in 10 seconds")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to schedule restart: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "잠금 화면 감지 서비스",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "백그라운드에서 화면 상태를 감지합니다"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("TODO 알람 앱")
            .setContentText("백그라운드에서 실행 중")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }

    private fun registerScreenStateReceiver() {
        if (screenStateReceiver == null) {
            screenStateReceiver = ScreenStateReceiver()
            val filter = IntentFilter().apply {
                priority = 1000 // 최고 우선순위
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            }
            registerReceiver(screenStateReceiver, filter)
            Log.d(TAG, "🔥 Screen state receiver registered with MAXIMUM priority!")
        }
    }

    private fun unregisterScreenStateReceiver() {
        screenStateReceiver?.let {
            unregisterReceiver(it)
            screenStateReceiver = null
            Log.d(TAG, "Screen state receiver unregistered")
        }
    }

    // 내부 브로드캐스트 리시버 클래스
    private inner class ScreenStateReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (Intent.ACTION_SCREEN_ON == intent?.action) {
                showOverlayImmediately()
            }
        }
    }

    private fun showOverlayImmediately() {
        try {
            // 잠금화면 모드로 MainActivity 실행
            val mainAppIntent = Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT
                )
                putExtra("LOCK_SCREEN_MODE", true)
                putExtra("PRIORITY", "MAXIMUM")
                putExtra("INSTANT_LAUNCH", true)
            }
            startActivity(mainAppIntent)
        } catch (e: Exception) {
            Log.e(TAG, "MainActivity 실행 실패: ${e.message}")
        }
    }
    
    // 백업 시스템: 주기적으로 서비스 상태 확인
    private fun setupWatchdog() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, BootReceiver::class.java).apply {
            action = "WATCHDOG_CHECK"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 5분마다 서비스 상태 확인
        alarmManager.setRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 5 * 60 * 1000, // 5분 후 시작
            5 * 60 * 1000, // 5분 간격
            pendingIntent
        )
        
        Log.d(TAG, "🐕 Watchdog alarm set up - checking every 5 minutes")
    }
}
