package com.dinamik.see_price.see_price

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.barcode_scanner"
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    private val barcodeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if ("nlscan.action.SCANNER_RESULT" == action) {
                val barcodeData = intent.getStringExtra("SCAN_BARCODE1")

                if (barcodeData != null && barcodeData.isNotEmpty()) {
                    channel.invokeMethod("onBarcodeScanned", barcodeData)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter()
        filter.addAction("nlscan.action.SCANNER_RESULT")
        registerReceiver(barcodeReceiver, filter)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(barcodeReceiver)
    }
}