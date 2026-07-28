package com.example.irms_mobile

import android.os.Bundle
import android.view.View
import android.view.autofill.AutofillManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val afm = getSystemService(AutofillManager::class.java)
        afm?.disableAutofillServices()
    }

    override fun onResume() {
        super.onResume()
        window.decorView.importantForAutofill = View.IMPORTANT_FOR_AUTOFILL_NO_EXCLUDE_DESCENDANTS
    }
}
