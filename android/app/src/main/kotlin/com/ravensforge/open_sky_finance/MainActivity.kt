package com.ravensforge.open_sky_finance

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var backupFolder: BackupFolderChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        NightModeChannel.register(applicationContext, messenger)
        backupFolder = BackupFolderChannel(this, messenger)
    }

    @Deprecated("FlutterActivity is not a ComponentActivity: no result API to register.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupFolder?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}
