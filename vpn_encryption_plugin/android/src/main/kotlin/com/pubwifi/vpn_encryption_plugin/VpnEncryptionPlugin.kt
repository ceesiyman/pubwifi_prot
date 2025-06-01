package com.pubwifi.vpn_encryption_plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** VpnEncryptionPlugin */
class VpnEncryptionPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var eventChannel: EventChannel
  private var activity: Activity? = null
  private var pendingResult: Result? = null
  private val VPN_REQUEST_CODE = 1
  private lateinit var context: Context
  private var eventSink: EventChannel.EventSink? = null
  private val scope = CoroutineScope(Dispatchers.Main)
  
  val _vpnState = MutableStateFlow(0) // 0 = disconnected
  val vpnState: StateFlow<Int> = _vpnState.asStateFlow()

  companion object {
    private const val CHANNEL = "vpn_encryption_plugin"
    private const val EVENT_CHANNEL = "vpn_encryption_plugin/state"
    private const val TAG = "VpnEncryptionPlugin"
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
    
    channel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)
    
    // Set this plugin instance in the VPN service
    PubWifiVpnService.setPlugin(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    Log.d(TAG, "Method call received: ${call.method}")
    when (call.method) {
      "startVpn" -> {
        Log.d(TAG, "Starting VPN...")
        pendingResult = result
        prepareVpn()
      }
      "stopVpn" -> {
        Log.d(TAG, "Stopping VPN...")
        stopVpn(result)
      }
      "isVpnActive" -> {
        val isRunning = context.getSharedPreferences("vpn_prefs", Context.MODE_PRIVATE)
          .getBoolean("vpn_active", false)
        Log.d(TAG, "Checking VPN status: $isRunning")
        result.success(isRunning)
      }
      "requestVpnPermission" -> {
        Log.d(TAG, "Requesting VPN permission...")
        val vpnIntent = VpnService.prepare(context)
        if (vpnIntent != null) {
          Log.d(TAG, "VPN permission needed, starting permission activity")
          vpnIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          context.startActivity(vpnIntent)
          result.success(false)
        } else {
          Log.d(TAG, "VPN permission already granted")
          result.success(true)
        }
      }
      else -> {
        Log.d(TAG, "Method not implemented: ${call.method}")
        result.notImplemented()
      }
    }
  }

  private fun prepareVpn() {
    Log.d(TAG, "Preparing VPN...")
    val intent = VpnService.prepare(activity)
    if (intent != null) {
      Log.d(TAG, "VPN permission needed, starting activity for result")
      activity?.startActivityForResult(intent, VPN_REQUEST_CODE)
    } else {
      Log.d(TAG, "VPN permission already granted, starting service")
      onActivityResult(VPN_REQUEST_CODE, Activity.RESULT_OK, null)
    }
  }

  private fun startVpnService() {
    Log.d(TAG, "Starting VPN service...")
    try {
      val intent = Intent(context, PubWifiVpnService::class.java)
      ContextCompat.startForegroundService(context, intent)
      Log.d(TAG, "VPN service started successfully")
      pendingResult?.success(true)
      pendingResult = null
    } catch (e: Exception) {
      Log.e(TAG, "Failed to start VPN service", e)
      pendingResult?.error("VPN_SERVICE_ERROR", "Failed to start VPN service: ${e.message}", null)
      pendingResult = null
    }
  }

  private fun stopVpn(result: Result) {
    Log.d(TAG, "Stopping VPN service...")
    try {
      val intent = Intent(context, PubWifiVpnService::class.java)
      intent.action = "STOP_VPN"  // Add action to identify stop request
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(intent)
      } else {
        context.startService(intent)
      }
      Log.d(TAG, "VPN service stop request sent successfully")
      result.success(true)
    } catch (e: Exception) {
      Log.e(TAG, "Failed to stop VPN service", e)
      result.error("VPN_SERVICE_ERROR", "Failed to stop VPN service: ${e.message}", null)
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    Log.d(TAG, "Activity result received: requestCode=$requestCode, resultCode=$resultCode")
    if (requestCode == VPN_REQUEST_CODE) {
      if (resultCode == Activity.RESULT_OK) {
        Log.d(TAG, "VPN permission granted, starting service")
        startVpnService()
      } else {
        Log.d(TAG, "VPN permission denied by user")
        pendingResult?.error("VPN_PERMISSION_DENIED", "User denied VPN permission", null)
        pendingResult = null
      }
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    PubWifiVpnService.setPlugin(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    scope.launch {
      vpnState.collect { state ->
        eventSink?.success(state)
      }
    }
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }
}
