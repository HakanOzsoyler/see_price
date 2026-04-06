package com.dinamik.see_price.see_price

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.barcode_scanner"
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    private val barcodeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action
            if ("nlscan.action.SCANNER_RESULT" == action) {
                val barcodeData = intent.getStringExtra("SCAN_BARCODE1")

                if (!barcodeData.isNullOrEmpty()) {
                    channel?.invokeMethod("onBarcodeScanned", barcodeData)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter("nlscan.action.SCANNER_RESULT")
        
        // Android 14 (API 34) ve sonrası için receiver'ın export edilmesi gerekir
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(barcodeReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(barcodeReceiver, filter)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            unregisterReceiver(barcodeReceiver)
        } catch (e: Exception) {
            // Receiver zaten kayıtlı değilse hata vermemesi için
        }
    }
}