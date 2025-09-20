package com.enrich.ideamemo

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.RingtoneManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.provider.Settings
import android.util.Log
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "auto_lockscreen_channel"
        private const val REQUEST_OVERLAY_PERMISSION = 1001
        
        // SharedPreferences 상수들
        private const val PREFS_NAME = "processed_alarms"
        private const val PROCESSED_ALARMS_KEY = "processed_alarm_ids"
    }

    private var alarmRingtone: android.media.Ringtone? = null
    private var alarmVibrator: Vibrator? = null
    private var isAlarmPlaying = false

    // 알람 중복 방지를 위한 처리된 알람 ID 관리
    private fun loadProcessedAlarmIds(): Set<Int> {
        return try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stringSet = prefs.getStringSet(PROCESSED_ALARMS_KEY, emptySet()) ?: emptySet()
            stringSet.map { it.toInt() }.toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun saveProcessedAlarmIds(alarmIds: Set<Int>) {
        try {
            val prefs: SharedPreferences = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val stringSet = alarmIds.map { it.toString() }.toSet()
            prefs.edit().putStringSet(PROCESSED_ALARMS_KEY, stringSet).apply()
        } catch (e: Exception) {
            Log.e(TAG, "알람 ID 저장 실패: ${e.message}")
        }
    }

    private fun addProcessedAlarmId(alarmId: Int) {
        val processedIds = loadProcessedAlarmIds().toMutableSet()
        processedIds.add(alarmId)
        
        if (processedIds.size > 100) {
            val sortedIds = processedIds.sorted()
            val recentIds = sortedIds.takeLast(50).toSet()
            saveProcessedAlarmIds(recentIds)
        } else {
            saveProcessedAlarmIds(processedIds)
        }
    }

    private fun isAlarmProcessed(alarmId: Int): Boolean {
        return loadProcessedAlarmIds().contains(alarmId)
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        val isLockScreenMode = intent.getBooleanExtra("LOCK_SCREEN_MODE", false)
        val isAlarmMode = intent.getBooleanExtra("ALARM_MODE", false)
        
        // 잠금화면 또는 알람 모드에서 화면 위에 표시
        if (isLockScreenMode || isAlarmMode) {
            window.addFlags(
                android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                android.view.WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
            )
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
        }
        
        super.onCreate(savedInstanceState)
        
        if (isAlarmMode) {
            handleAlarmIntentImmediate(intent)
        }
        // 자동 권한 체크 제거 - Flutter에서 사용자 동의 후에만 권한 요청
    }

    private var currentLockScreenMode = false
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAndStartService" -> {
                        checkPermissionsAndStartService()
                        result.success("Service check completed")
                    }
                    "isServiceRunning" -> {
                        // 서비스 실행 상태 확인 로직
                        result.success(true)
                    }
                    "getLockScreenMode" -> {
                        // 현재 모드 상태 반환
                        result.success(currentLockScreenMode)
                    }
                    "exitLockScreenMode" -> {
                        // 잠금화면 모드 종료 - 앱 종료
                        finish()
                        result.success("Lock screen mode exited")
                    }
                    "showFullScreenAlarm" -> {
                        // 더 이상 사용하지 않음 (WorkManager로 대체됨)
                        result.success("Deprecated - Use WorkManager instead")
                    }
                    "stopAlarmSound" -> {
                        // 알람 사운드 정지
                        stopAlarmSound()
                        result.success("Alarm sound stopped")
                    }
                    "requestBatteryOptimizationExemption" -> {
                        // 배터리 최적화 예외 요청 (사용자 선택 시)
                        requestBatteryOptimizationExemption()
                        result.success("Battery optimization exemption requested")
                    }
                    "requestOverlayPermission" -> {
                        // 사용자가 동의 버튼을 눌렀을 때만 권한 요청
                        Log.d(TAG, "사용자가 동의함 - 오버레이 권한 요청")
                        requestOverlayPermission()
                        result.success("Overlay permission requested")
                    }
                    "scheduleWorkManagerAlarm" -> {
                        // WorkManager로 알람 스케줄링
                        val alarmId = call.argument<Int>("alarmId") ?: -1
                        val delaySeconds = call.argument<Int>("delaySeconds") ?: 60
                        val title = call.argument<String>("title") ?: "TODO 알람"
                        val message = call.argument<String>("message") ?: "알람이 울렸습니다!"
                        
                        scheduleWorkManagerAlarm(alarmId, delaySeconds, title, message)
                        result.success("WorkManager alarm scheduled")
                    }
                    "cancelWorkManagerAlarm" -> {
                        // WorkManager 알람 취소
                        val alarmId = call.argument<Int>("alarmId") ?: -1
                        cancelWorkManagerAlarm(alarmId)
                        result.success("WorkManager alarm cancelled")
                    }
                    "checkOverlayPermission" -> {
                        // 오버레이 권한 상태 확인
                        val hasPermission = Settings.canDrawOverlays(this)
                        Log.d(TAG, "🔍 오버레이 권한 상태: $hasPermission")
                        result.success(hasPermission)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkPermissionsAndStartService() {
        Log.d(TAG, "Checking permissions and starting service")
        
        // 오버레이 권한 확인
        if (!Settings.canDrawOverlays(this)) {
            Log.d(TAG, "Overlay permission not granted - requesting permission")
            requestOverlayPermission()
        } else {
            Log.d(TAG, "Overlay permission already granted - starting service")
            startLockScreenService()
        }
    }

    private fun requestOverlayPermission() {
        val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_OVERLAY_PERMISSION) {
            if (Settings.canDrawOverlays(this)) {
                Log.d(TAG, "Overlay permission granted - starting service")
                startLockScreenService()
            } else {
                Log.d(TAG, "Overlay permission denied")
            }
        }
    }
    
    private fun requestBatteryOptimizationExemption() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                if (!powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    Log.d(TAG, "🔋 Requesting battery optimization exemption")
                    val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                } else {
                    Log.d(TAG, "✅ Battery optimization already disabled")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to request battery optimization exemption: ${e.message}")
        }
    }

    private fun startLockScreenService() {
        try {
            val serviceIntent = Intent(this, LockScreenService::class.java)
            startForegroundService(serviceIntent)
            Log.d(TAG, "✅ LockScreenService started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting LockScreenService: ${e.message}")
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent) // 새로운 Intent로 업데이트
        
        val isLockScreenMode = intent.getBooleanExtra("LOCK_SCREEN_MODE", false)
        val isAlarmMode = intent.getBooleanExtra("ALARM_MODE", false)
        
        Log.d(TAG, "🔄 onNewIntent - LockScreenMode: $isLockScreenMode, AlarmMode: $isAlarmMode")
        
        // 알람 모드일 때 즉시 처리
        if (isAlarmMode) {
            handleAlarmIntentImmediate(intent)
        }
        
        updateLockScreenMode()
        
        // WorkManager에서 온 알람 처리 (백업)
        handleAlarmIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        
        // 🚨 중요: ||| 버튼으로 앱 복귀 시 Intent 정리
        // 최근 앱 목록에서 복귀하는 경우 기존 Intent가 그대로 남아있을 수 있음
        clearStaleIntentFlags()
        
        updateLockScreenMode()
        
        // 자동 권한 체크 제거 - Flutter에서 관리
    }
    
    // 실제 잠금화면 상태 확인
    private fun isDeviceLocked(): Boolean {
        return try {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
            // 키가드가 잠겨있는 상태만 잠금화면으로 판단
            val isLocked = keyguardManager.isKeyguardLocked
            Log.d(TAG, "🔒 [LOCK_CHECK] Device locked: $isLocked")
            isLocked
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking device lock status: ${e.message}")
            false
        }
    }

    // 오래된 Intent 플래그 정리
    private fun clearStaleIntentFlags() {
        try {
            // 현재 디바이스가 실제로 잠겨있는지 확인
            val isActuallyLocked = isDeviceLocked()
            val intentLockMode = intent?.getBooleanExtra("LOCK_SCREEN_MODE", false) ?: false
            val hasLockScreenFlags = intent?.getBooleanExtra("INSTANT_LAUNCH", false) ?: false
            
            Log.d(TAG, "🧹 [INTENT_CLEANUP] Device locked: $isActuallyLocked, Intent lock mode: $intentLockMode, Has flags: $hasLockScreenFlags")
            
            // 디바이스가 잠겨있지 않은데 Intent에 LOCK_SCREEN_MODE가 설정되어 있으면 정리
            if (!isActuallyLocked && intentLockMode) {
                Log.d(TAG, "🧹 [INTENT_CLEANUP] Clearing stale lock screen intent flags")
                
                // 새로운 Intent 생성 (일반 모드용)
                val cleanIntent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    // LOCK_SCREEN_MODE 관련 플래그들 제거
                    removeExtra("LOCK_SCREEN_MODE")
                    removeExtra("INSTANT_LAUNCH") 
                    removeExtra("PRIORITY")
                }
                setIntent(cleanIntent)
                Log.d(TAG, "🧹 [INTENT_CLEANUP] Intent cleaned - removed stale lock screen flags")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error cleaning intent flags: ${e.message}")
        }
    }
    
    override fun onPause() {
        super.onPause()
        // 알람이 재생 중이 아닐 때만 정지 (알람 중에는 계속 재생)
        if (!isAlarmPlaying) {
            stopAlarmSound()
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // 앱 종료 시 알람 사운드 정지
        stopAlarmSound()
        
        // SharedPreferences를 사용하므로 별도 정리 불필요
        // 정리는 addProcessedAlarmId에서 자동으로 처리됨
    }
    
    private fun updateLockScreenMode() {
        // 실제 디바이스 상태와 Intent 정보를 종합해서 판별
        val isActuallyLocked = isDeviceLocked()
        val intentLockMode = intent?.getBooleanExtra("LOCK_SCREEN_MODE", false) ?: false
        val hasLockScreenFlags = intent?.getBooleanExtra("INSTANT_LAUNCH", false) ?: false || 
                                intent?.getStringExtra("PRIORITY") == "MAXIMUM"
        
        // 잠금화면 모드 판별:
        // 1. 디바이스가 실제로 잠겨있고 Intent에 LOCK_SCREEN_MODE가 있는 경우
        // 2. LockScreenService에서 실행된 특징이 있는 경우 (INSTANT_LAUNCH 또는 PRIORITY=MAXIMUM)
        val newLockScreenMode = (isActuallyLocked && intentLockMode) || 
                               (intentLockMode && hasLockScreenFlags)
        
        Log.d(TAG, "🔄 [MODE_CHECK] Device locked: $isActuallyLocked, Intent lock: $intentLockMode, Has flags: $hasLockScreenFlags → Result: $newLockScreenMode")
        
        if (currentLockScreenMode != newLockScreenMode) {
            val previousMode = currentLockScreenMode
            currentLockScreenMode = newLockScreenMode
            Log.d(TAG, "🔄 [MODE_UPDATE] Lock screen mode changed: $previousMode → $newLockScreenMode")
            
            // Flutter에 모드 변경 알림
            notifyFlutterModeChange()
        } else {
            Log.d(TAG, "🔄 [MODE_UPDATE] Lock screen mode unchanged: $currentLockScreenMode")
        }
    }
    
    private fun notifyFlutterModeChange() {
        // Flutter 엔진이 준비되면 모드 변경 알림
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            try {
                val channel = MethodChannel(messenger, CHANNEL)
                channel.invokeMethod("onLockScreenModeChanged", currentLockScreenMode)
                Log.d(TAG, "📱 Flutter notified of mode change: $currentLockScreenMode")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Failed to notify Flutter: ${e.message}")
            }
        }
    }
    
    // 🚫 사용하지 않는 메서드 (제거됨)
    
    private fun playAlarmSound() {
        try {
            // 기존 사운드가 있으면 먼저 정지
            stopAlarmSound()
            
            // 알람 재생 상태 설정
            isAlarmPlaying = true
            
            // 시스템 알람 사운드 재생
            val notification = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            Log.d(TAG, "🔊 알람 URI: $notification")
            
            alarmRingtone = RingtoneManager.getRingtone(applicationContext, notification)
            if (alarmRingtone != null) {
                alarmRingtone!!.play()
                Log.d(TAG, "🔊 Ringtone 재생 시작")
            } else {
                Log.e(TAG, "❌ Ringtone이 null입니다!")
            }
            
            // 진동도 함께
            alarmVibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            Log.d(TAG, "🔊 진동 시작")
            
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val pattern = longArrayOf(0, 1000, 500, 1000)
                val effect = VibrationEffect.createWaveform(pattern, 0)
                alarmVibrator?.vibrate(effect)
                Log.d(TAG, "🔊 API 26+ 진동 실행")
            } else {
                @Suppress("DEPRECATION")
                alarmVibrator?.vibrate(longArrayOf(0, 1000, 500, 1000), 0)
                Log.d(TAG, "🔊 API 25- 진동 실행")
            }
            
            Log.d(TAG, "🔊 Native alarm sound and vibration started")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error playing alarm sound: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun stopAlarmSound() {
        try {
            // 알람 재생 상태 해제
            isAlarmPlaying = false
            
            // Ringtone 정지
            alarmRingtone?.let {
                if (it.isPlaying) {
                    it.stop()
                    Log.d(TAG, "🔇 Ringtone 정지됨")
                }
            }
            alarmRingtone = null
            
            // 진동 정지
            alarmVibrator?.cancel()
            alarmVibrator = null
            
            Log.d(TAG, "🔇 알람 사운드 및 진동 정지 완료")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error stopping alarm sound: ${e.message}")
        }
    }
    
    // 🚫 사용하지 않는 메서드 (제거됨)

    // WorkManager로 알람 스케줄링 (고유 작업으로 등록)
    private fun scheduleWorkManagerAlarm(alarmId: Int, delaySeconds: Int, title: String, message: String) {
        try {
            // 기존 같은 알람이 있으면 먼저 취소
            val workManager = WorkManager.getInstance(this)
            workManager.cancelAllWorkByTag("alarm_$alarmId")
            workManager.cancelUniqueWork("alarm_work_$alarmId")
            
            val inputData = Data.Builder()
                .putInt(AlarmWorker.KEY_ALARM_ID, alarmId)
                .putString(AlarmWorker.KEY_TITLE, title)
                .putString(AlarmWorker.KEY_MESSAGE, message)
                .build()

            val workRequest = OneTimeWorkRequestBuilder<AlarmWorker>()
                .setInitialDelay(delaySeconds.toLong(), TimeUnit.SECONDS)
                .setInputData(inputData)
                .addTag("alarm_$alarmId") // 취소를 위한 태그
                .build()

            // 🚨 중요: 고유 작업으로 등록 (중복 방지)
            workManager.enqueueUniqueWork(
                "alarm_work_$alarmId", // 고유 작업명
                androidx.work.ExistingWorkPolicy.REPLACE, // 기존 작업 교체
                workRequest
            )
            
            Log.d(TAG, "✅ [WORK_SCHEDULE] WorkManager 고유 알람 등록: alarm_work_$alarmId, Delay=${delaySeconds}초")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [WORK_SCHEDULE_ERROR] WorkManager 알람 스케줄링 실패: ${e.message}")
        }
    }

    // WorkManager 알람 취소 (강화된 삭제)
    private fun cancelWorkManagerAlarm(alarmId: Int) {
        try {
            val workManager = WorkManager.getInstance(this)
            
            // 1. 태그로 취소
            workManager.cancelAllWorkByTag("alarm_$alarmId")
            Log.d(TAG, "🗑️ [WORK_CANCEL_1] 태그별 취소: alarm_$alarmId")
            
            // 2. 고유 작업명으로 취소
            workManager.cancelUniqueWork("alarm_work_$alarmId")
            Log.d(TAG, "🗑️ [WORK_CANCEL_2] 고유 작업 취소: alarm_work_$alarmId")
            
            // 3. 완료된 작업 정리
            workManager.pruneWork()
            Log.d(TAG, "🧹 [WORK_CANCEL_3] 완료된 작업들 정리")
            
            Log.d(TAG, "✅ [WORK_CANCEL_COMPLETE] WorkManager 알람 완전 취소: ID=$alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [WORK_CANCEL_ERROR] WorkManager 알람 취소 실패: ${e.message}")
        }
    }

    // WorkManager에서 온 알람 Intent 처리 (중복 방지)
    private var isAlarmProcessing = false
    
        // 알람 모드 즉시 처리 (onCreate에서 호출)
    private fun handleAlarmIntentImmediate(intent: Intent?) {

        
        if (intent?.getBooleanExtra("ALARM_MODE", false) == true && !isAlarmProcessing) {
            val alarmId = intent.getIntExtra("ALARM_ID", -1)
            
            // 알람 중복 실행 방지
            if (isAlarmProcessed(alarmId)) {
                return
            }
            
            addProcessedAlarmId(alarmId)
            isAlarmProcessing = true
            
            val title = intent.getStringExtra("ALARM_TITLE") ?: "TODO 알람"
            val message = intent.getStringExtra("ALARM_MESSAGE") ?: "알람이 울렸습니다!"
            
            playAlarmSound()
            
            // Flutter 알람 화면 즉시 표시 (잠자기 모드에서는 더 긴 지연)
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    val messenger = flutterEngine?.dartExecutor?.binaryMessenger
                    if (messenger != null) {
                        val channel = MethodChannel(messenger, CHANNEL)
                        channel.invokeMethod("showAlarmScreen", mapOf(
                            "title" to title,
                            "message" to message,
                            "alarmId" to alarmId
                        ))

                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Flutter 알람 화면 표시 실패: ${e.message}")
                }
            }, 1500)
            
            // 알람 처리 플래그 리셋
            Handler(Looper.getMainLooper()).postDelayed({
                isAlarmProcessing = false
            }, 5000)
        }
    }
    
        // onNewIntent에서 알람 처리 (앱이 포그라운드에 있을 때)
    private fun handleAlarmIntent(intent: Intent?) {
        Log.d(TAG, "🔍 [DEBUG] handleAlarmIntent 호출됨")
        Log.d(TAG, "🔍 [DEBUG] ALARM_MODE=${intent?.getBooleanExtra("ALARM_MODE", false)}")
        Log.d(TAG, "🔍 [DEBUG] isAlarmProcessing=$isAlarmProcessing")
        
        if (intent?.getBooleanExtra("ALARM_MODE", false) == true && !isAlarmProcessing) {
            val alarmId = intent.getIntExtra("ALARM_ID", -1)
            
            // 🚨 중요: 이미 처리된 알람인지 확인 (SharedPreferences에서)
            if (isAlarmProcessed(alarmId)) {
                Log.d(TAG, "🚫 [NATIVE_SKIP] 이미 처리된 알람 ID: $alarmId - 건너뛰기")
                return
            }
            
            // 처리된 알람 ID 목록에 추가 (SharedPreferences에 저장)
            addProcessedAlarmId(alarmId)
            val processedCount = loadProcessedAlarmIds().size
            Log.d(TAG, "📝 [NATIVE_REGISTER] 알람 ID 처리 목록에 영구 저장: $alarmId")
            Log.d(TAG, "📊 [NATIVE_STATS] 현재 처리된 알람 개수: $processedCount")
            
            isAlarmProcessing = true
            
            val title = intent.getStringExtra("ALARM_TITLE") ?: "TODO 알람"
            val message = intent.getStringExtra("ALARM_MESSAGE") ?: "알람이 울렸습니다!"
            val fromWorkManager = intent.getBooleanExtra("FROM_WORK_MANAGER", false)
            
            Log.d(TAG, "🔔 [ALARM_PROCESS] onNewIntent에서 알람 처리: ID=$alarmId, Title=$title, FromWorkManager=$fromWorkManager")
            
            // 포그라운드 상태에서도 알람 처리 (원래 방식)
            playAlarmSound()
            
            // Flutter 알람 화면 표시
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    val messenger = flutterEngine?.dartExecutor?.binaryMessenger
                    if (messenger != null) {
                        val channel = MethodChannel(messenger, CHANNEL)
                        channel.invokeMethod("showAlarmScreen", mapOf(
                            "title" to title,
                            "message" to message,
                            "alarmId" to alarmId
                        ))
                        Log.d(TAG, "📱 Flutter 알람 화면 표시 완료")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Flutter 알람 화면 표시 실패: ${e.message}")
                }
            }, 500)
            
            // 처리 완료 후 플래그 리셋
            Handler(Looper.getMainLooper()).postDelayed({
                isAlarmProcessing = false
            }, 5000)
        } else {
            Log.d(TAG, "🔄 handleAlarmIntent 호출 - 알람 모드 아님 또는 이미 처리 중")
        }
    }

}
