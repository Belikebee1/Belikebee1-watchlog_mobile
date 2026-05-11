package com.belikebee.watchlog

// local_auth on Android requires hosting Flutter in a FlutterFragmentActivity
// (not the default FlutterActivity) because the biometric prompt is itself a
// fragment that needs an AndroidX FragmentManager.
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
