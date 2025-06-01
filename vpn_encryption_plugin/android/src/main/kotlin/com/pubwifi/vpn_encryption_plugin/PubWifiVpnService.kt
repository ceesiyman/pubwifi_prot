package com.pubwifi.vpn_encryption_plugin

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.channels.DatagramChannel
import java.util.concurrent.atomic.AtomicBoolean

class PubWifiVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val isRunning = AtomicBoolean(false)
    private var vpnJob: Job? = null
    private lateinit var prefs: SharedPreferences
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "vpn_service_channel"
        private const val CHANNEL_NAME = "VPN Service"
        private const val TAG = "PubWifiVpnService"
        
        private var plugin: VpnEncryptionPlugin? = null

        fun setPlugin(pluginInstance: VpnEncryptionPlugin?) {
            plugin = pluginInstance
        }

        private fun updateVpnState(state: Int) {
            Log.d(TAG, "Updating VPN state to: $state")
            plugin?._vpnState?.value = state
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "VPN service onCreate")
        prefs = getSharedPreferences("vpn_prefs", Context.MODE_PRIVATE)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "VPN service onStartCommand")
        
        // Handle stop request
        if (intent?.action == "STOP_VPN") {
            Log.d(TAG, "Received stop request")
            stopVpn()
            return START_NOT_STICKY
        }

        if (isRunning.get()) {
            Log.d(TAG, "VPN service already running")
            return START_STICKY
        }

        try {
            Log.d(TAG, "Starting VPN service foreground")
            startForeground(NOTIFICATION_ID, createNotification())
            isRunning.set(true)
            prefs.edit().putBoolean("vpn_active", true).apply()
            updateVpnState(2) // connected

            vpnJob = scope.launch {
                try {
                    Log.d(TAG, "Setting up VPN interface")
                    setupVpn()
                    Log.d(TAG, "Starting VPN traffic processing")
                    processVpnTraffic()
                } catch (e: Exception) {
                    Log.e(TAG, "VPN service error: ${e.message}", e)
                    updateVpnState(4) // error
                    stopVpn()
                }
            }

            Log.d(TAG, "VPN service started successfully")
            return START_STICKY
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN service", e)
            updateVpnState(4) // error
            stopSelf()
            return START_NOT_STICKY
        }
    }

    private fun createNotificationChannel() {
        Log.d(TAG, "Creating notification channel")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "VPN Service Notification"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "Notification channel created")
        }
    }

    private fun createNotification(): Notification {
        Log.d(TAG, "Creating notification")
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PubWIFI VPN Active")
            .setContentText("Your connection is being protected")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun setupVpn() {
        Log.d(TAG, "Setting up VPN interface")
        val builder = Builder()
            .addAddress("10.0.0.2", 32)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("8.8.8.8")
            .addDnsServer("8.8.4.4") // Add backup DNS
            .setSession("PubWIFI VPN")
            .setMtu(1500)
            .allowBypass() // Allow apps to bypass VPN if needed
            .setBlocking(true) // Enable blocking mode for proper packet handling

        // Add common DNS servers
        builder.addDnsServer("1.1.1.1") // Cloudflare
        builder.addDnsServer("1.0.0.1") // Cloudflare backup

        vpnInterface = builder.establish()
        if (vpnInterface == null) {
            Log.e(TAG, "Failed to establish VPN interface")
            throw Exception("Failed to establish VPN interface")
        }
        Log.d(TAG, "VPN interface established successfully")
    }

    private suspend fun processVpnTraffic() {
        Log.d(TAG, "Starting VPN traffic processing")
        val buffer = ByteArray(32767)
        val inputStream = FileInputStream(vpnInterface!!.fileDescriptor)
        val outputStream = FileOutputStream(vpnInterface!!.fileDescriptor)

        try {
            Log.d(TAG, "Starting direct VPN traffic processing")
            while (isRunning.get()) {
                try {
                    val length = inputStream.read(buffer)
                    if (length > 0) {
                        // Process the packet
                        val processedPacket = processPacket(buffer.copyOfRange(0, length))
                        if (processedPacket != null) {
                            outputStream.write(processedPacket)
                            outputStream.flush()
                        }
                    }
                } catch (e: Exception) {
                    if (isRunning.get()) {
                        Log.e(TAG, "Error processing packet: ${e.message}")
                        // Continue processing even if one packet fails
                        continue
                    }
                    break
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in VPN traffic processing", e)
            throw e
        } finally {
            Log.d(TAG, "Cleaning up VPN resources")
            try {
                inputStream.close()
                outputStream.close()
            } catch (e: Exception) {
                Log.e(TAG, "Error closing streams", e)
            }
        }
    }

    private fun processPacket(packet: ByteArray): ByteArray? {
        try {
            // For now, just pass through the packet
            // TODO: Add encryption/decryption here
            return packet
        } catch (e: Exception) {
            Log.e(TAG, "Error processing packet: ${e.message}")
            return null
        }
    }

    fun stopVpn() {
        Log.d(TAG, "Stopping VPN service")
        try {
            isRunning.set(false)
            vpnJob?.cancel()
            
            // Close VPN interface
            try {
                vpnInterface?.close()
                vpnInterface = null
            } catch (e: Exception) {
                Log.e(TAG, "Error closing VPN interface", e)
            }

            // Update state and preferences
            prefs.edit().putBoolean("vpn_active", false).apply()
            updateVpnState(0) // disconnected
            
            // Stop foreground service
            try {
                stopForeground(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping foreground service", e)
            }

            // Stop the service
            try {
                stopSelf()
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping service", e)
            }

            Log.d(TAG, "VPN service stopped successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN service", e)
            // Force stop the service even if there's an error
            try {
                stopSelf()
            } catch (e: Exception) {
                Log.e(TAG, "Error force stopping service", e)
            }
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "VPN service onDestroy")
        try {
            isRunning.set(false)
            vpnJob?.cancel()
            vpnInterface?.close()
            vpnInterface = null
            prefs.edit().putBoolean("vpn_active", false).apply()
            updateVpnState(0) // disconnected
            scope.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroy", e)
        }
        super.onDestroy()
    }

    override fun onRevoke() {
        Log.d(TAG, "VPN service onRevoke")
        try {
            isRunning.set(false)
            vpnJob?.cancel()
            vpnInterface?.close()
            vpnInterface = null
            prefs.edit().putBoolean("vpn_active", false).apply()
            updateVpnState(0) // disconnected
            scope.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onRevoke", e)
        }
        super.onRevoke()
    }
} 