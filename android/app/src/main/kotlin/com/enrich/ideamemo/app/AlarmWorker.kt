package com.enrich.ideamemo.app

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.Data

class AlarmWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    
    companion object {
        private const val TAG = "AlarmWorker"
        const val KEY_ALARM_ID = "alarm_id"
        const val KEY_TITLE = "title"
        const val KEY_MESSAGE = "message"
    }

    override fun doWork(): Result {
        return try {
            val alarmId = inputData.getInt(KEY_ALARM_ID, -1)
            val title = inputData.getString(KEY_TITLE) ?: "TODO 알람"
            val message = inputData.getString(KEY_MESSAGE) ?: "알람이 울렸습니다!"

            // MainActivity 알람 화면 표시
            showAlarmScreen(alarmId, title, message)

            // 알람 실행 후 WorkManager 작업 즉시 삭제 (중복 방지)
            try {
                val workManager = androidx.work.WorkManager.getInstance(applicationContext)
                workManager.cancelAllWorkByTag("alarm_$alarmId")
                workManager.cancelUniqueWork("alarm_work_$alarmId")
                workManager.pruneWork()
                System.gc()
            } catch (e: Exception) {
                Log.e(TAG, "WorkManager 작업 삭제 실패: ${e.message}")
            }

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "WorkManager 알람 작업 실패: ${e.message}")
            Result.failure()
        }
    }

    private fun showAlarmScreen(alarmId: Int, title: String, message: String) {
        try {
            val intent = Intent(applicationContext, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT
                )
                putExtra("ALARM_MODE", true)
                putExtra("ALARM_ID", alarmId)
                putExtra("ALARM_TITLE", title)
                putExtra("ALARM_MESSAGE", message)
                putExtra("FROM_WORK_MANAGER", true)
            }

            applicationContext.startActivity(intent)

        } catch (e: Exception) {
            Log.e(TAG, "MainActivity 알람 모드 전환 실패: ${e.message}")
        }
    }
}
