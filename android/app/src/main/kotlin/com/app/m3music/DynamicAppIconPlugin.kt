package com.app.m3music

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object DynamicAppIconPlugin {
    private const val CHANNEL = "com.app.m3music/dynamic_icon"

    private val launcherAliases = listOf(
        "com.app.m3music.MainActivityDefault",
        "com.app.m3music.MainActivityIcon1",
        "com.app.m3music.MainActivityIcon2",
        "com.app.m3music.MainActivityIcon3",
        "com.app.m3music.MainActivityIcon4",
        "com.app.m3music.MainActivityIcon5",
        "com.app.m3music.MainActivityIcon6",
        "com.app.m3music.MainActivityIcon7",
        "com.app.m3music.MainActivityIcon8",
        "com.app.m3music.MainActivityIcon9",
    )

    fun register(flutterEngine: FlutterEngine, context: Context) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "applyAlias" -> {
                        val aliasClass = call.argument<String>("aliasClass")
                        if (aliasClass.isNullOrEmpty()) {
                            result.error("INVALID", "aliasClass is required", null)
                            return@setMethodCallHandler
                        }
                        if (aliasClass !in launcherAliases) {
                            result.error("INVALID", "unknown alias: $aliasClass", null)
                            return@setMethodCallHandler
                        }
                        try {
                            applyAlias(context, aliasClass)
                            result.success(aliasClass)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    "getCurrentAlias" -> {
                        result.success(getCurrentAlias(context))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyAlias(context: Context, targetAliasClass: String) {
        val pm = context.packageManager
        val pkg = context.packageName
        for (alias in launcherAliases) {
            val enabled = alias == targetAliasClass
            pm.setComponentEnabledSetting(
                ComponentName(pkg, alias),
                if (enabled) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                },
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun getCurrentAlias(context: Context): String? {
        val pm = context.packageManager
        val pkg = context.packageName
        for (alias in launcherAliases) {
            if (isAliasEnabled(pm, pkg, alias)) {
                return alias
            }
        }
        return launcherAliases.firstOrNull()
    }

    private fun isAliasEnabled(
        pm: PackageManager,
        pkg: String,
        alias: String,
    ): Boolean {
        return when (pm.getComponentEnabledSetting(ComponentName(pkg, alias))) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> alias == "com.app.m3music.MainActivityDefault"
        }
    }
}
