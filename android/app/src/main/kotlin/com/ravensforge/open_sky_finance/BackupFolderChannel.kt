package com.ravensforge.open_sky_finance

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * The folder automatic backups go to, through the Storage Access Framework: the user
 * picks it once (ACTION_OPEN_DOCUMENT_TREE) and the permission is persisted. The app
 * only creates, lists and deletes its own backup files in it.
 *
 * Errors: `unreachable` when the permission was revoked or the provider is gone.
 */
class BackupFolderChannel(private val activity: Activity, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "open_sky_finance/backup_folder")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var pending: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pick" -> pick(result)
            "write" -> background(result) {
                val folder = folder(call)
                val file = DocumentsContract.createDocument(
                    activity.contentResolver,
                    root(folder),
                    "application/json",
                    call.argument<String>("name")!!,
                ) ?: throw IllegalStateException("not created")
                activity.contentResolver.openOutputStream(file, "wt")!!.use {
                    it.write(call.argument<ByteArray>("bytes")!!)
                }
                null
            }
            "list" -> background(result) { children(folder(call)).keys.toList() }
            "delete" -> background(result) {
                val folder = folder(call)
                children(folder)[call.argument<String>("name")!!]?.let {
                    DocumentsContract.deleteDocument(
                        activity.contentResolver,
                        DocumentsContract.buildDocumentUriUsingTree(folder, it),
                    )
                }
                null
            }
            "release" -> {
                try {
                    activity.contentResolver.releasePersistableUriPermission(
                        Uri.parse(call.argument<String>("folder")!!),
                        FLAGS,
                    )
                } catch (_: SecurityException) {
                    // Already gone.
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        pending?.success(null)
        pending = result
        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), REQUEST)
    }

    /** Forwarded from the activity. Returns whether the result was the picker's. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
            return true
        }
        background(result) {
            activity.contentResolver.takePersistableUriPermission(tree, FLAGS)
            mapOf("ref" to tree.toString(), "name" to folderName(tree))
        }
        return true
    }

    /** The granted tree, or `unreachable` when its permission is gone. */
    private fun folder(call: MethodCall): Uri {
        val folder = Uri.parse(call.argument<String>("folder")!!)
        val granted = activity.contentResolver.persistedUriPermissions.any {
            it.uri == folder && it.isWritePermission
        }
        if (!granted) throw SecurityException("permission revoked")
        return folder
    }

    private fun root(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    /** "Drive › Open Sky Finance": the app that provides the folder, then its name. */
    private fun folderName(tree: Uri): String {
        val pm = activity.packageManager
        val provider = tree.authority?.let { pm.resolveContentProvider(it, 0) }
            ?.loadLabel(pm)?.toString()
        return listOfNotNull(provider, displayName(tree)).joinToString(" › ")
    }

    private fun displayName(tree: Uri): String? =
        activity.contentResolver.query(root(tree), arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)
            ?.use { if (it.moveToFirst()) it.getString(0) else null }

    /** File name → document id of the files directly in [tree]. */
    private fun children(tree: Uri): Map<String, String> {
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val columns = arrayOf(Document.COLUMN_DISPLAY_NAME, Document.COLUMN_DOCUMENT_ID)
        val found = mutableMapOf<String, String>()
        activity.contentResolver.query(uri, columns, null, null, null)?.use {
            while (it.moveToNext()) found[it.getString(0)] = it.getString(1)
        } ?: throw IllegalStateException("not listed")
        return found
    }

    /** Runs [work] off the main thread; any failure means the folder can't be reached. */
    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        io.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Exception) {
                main.post { result.error("unreachable", e.javaClass.simpleName, null) }
            }
        }
    }

    private companion object {
        const val REQUEST = 4207
        const val FLAGS =
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
    }
}
