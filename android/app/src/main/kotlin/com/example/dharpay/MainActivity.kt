package com.example.dharpay   // ← your package name

import android.net.*
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "network/bind"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "bindToWifi") {
                    bindToWifiNetwork()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun bindToWifiNetwork() {
        val connectivityManager =
            getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager

        val networks = connectivityManager.allNetworks

        for (network in networks) {
            val caps = connectivityManager.getNetworkCapabilities(network)

            if (caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    connectivityManager.bindProcessToNetwork(network)
                } else {
                    ConnectivityManager.setProcessDefaultNetwork(network)
                }
                break
            }
        }
    }
}
