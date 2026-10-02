package com.ravensforge.open_sky_finance

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Tells Android the theme picked in the app (`system`, `light` or `dark`), so the
 * system splash screen of the next launch draws in it. Android 12 and later only.
 */
object NightModeChannel {
    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "open_sky_finance/night_mode").setMethodCallHandler { call, result ->
            if (call.method != "set") return@setMethodCallHandler result.notImplemented()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val mode = when (call.arguments as? String) {
                    "light" -> UiModeManager.MODE_NIGHT_NO
                    "dark" -> UiModeManager.MODE_NIGHT_YES
                    else -> UiModeManager.MODE_NIGHT_AUTO
                }
                context.getSystemService(UiModeManager::class.java).setApplicationNightMode(mode)
            }
            result.success(null)
        }
    }
}
