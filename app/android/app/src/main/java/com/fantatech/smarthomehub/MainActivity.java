package com.fantatech.smarthomehub;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Force WebView text zoom to 100% so the Android system
        // "Font size" and "Display size" accessibility settings never
        // inflate the app UI beyond its intended design scale.
        this.bridge.getWebView().getSettings().setTextZoom(100);
    }
}
