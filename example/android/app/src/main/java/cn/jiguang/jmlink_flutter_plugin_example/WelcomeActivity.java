package cn.jiguang.jmlink_flutter_plugin_example;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import cn.jiguang.jmlink_flutter_plugin.JmlinkFlutterPlugin;

public class WelcomeActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d("| WelcomeActivity | - ","onCreate:");
        super.onCreate(savedInstanceState);

        JmlinkFlutterPlugin.setData(getIntent().getData());

        Intent intent = new Intent(this,MainActivity.class);
        startActivity(intent);
        finish();
    }
    //@Override


    protected void onDestroy() {
        Log.d("| WelcomeActivity | - ","onDestroy:");
        super.onDestroy();
    }
    protected void onNewIntent(Intent intent) {
        Log.d("| WelcomeActivity | - ","onNewIntent:");
        super.onNewIntent(intent);
        setIntent(intent);
    }
}
