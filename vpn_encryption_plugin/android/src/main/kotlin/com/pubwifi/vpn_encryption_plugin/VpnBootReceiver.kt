package com.pubwifi.vpn_encryption_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.VpnService
import android.util.Log

class VpnBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == "com.htc.intent.action.QUICKBOOT_POWERON") {
            
            val prefs = context.getSharedPreferences("vpn_prefs", Context.MODE_PRIVATE)
            val wasVpnActive = prefs.getBoolean("vpn_active", false)
            
            if (wasVpnActive) {
                Log.d("VpnBootReceiver", "VPN was active before reboot, attempting to restart")
                val vpnIntent = VpnService.prepare(context)
                if (vpnIntent != null) {
                    // VPN permission needed, start the permission activity
                    vpnIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(vpnIntent)
                } else {
                    // VPN permission already granted, start the service
                    val serviceIntent = Intent(context, VpnService::class.java)
                    serviceIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startService(serviceIntent)
                }
            }
        }
    }
} 