package cn.jiguang.jmlink_flutter_plugin;

import android.app.Activity;
import android.content.Context;
import android.net.Uri;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import cn.jiguang.jmlinksdk.api.JMLinkAPI;
import cn.jiguang.jmlinksdk.api.JMLinkCallback;
import cn.jiguang.jmlinksdk.api.YYBCallback;
import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class JmlinkFlutterPlugin implements MethodChannel.MethodCallHandler {

    // 定义日志 TAG
    private  static final String TAG = "| JML | Android | -";


    private static final String jmlink_handler_key  = "jmlink_handler_key";
    private static final String jmlink_getParam_key = "jmlink_getParam_key";

    private Context context;
    private MethodChannel channel;
    private WeakReference<Activity> activity;

    /** Plugin registration. */
    public static void registerWith(PluginRegistry.Registrar registrar) {

        final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.jiguang.jmlink_flutter_plugin");
        channel.setMethodCallHandler(new JmlinkFlutterPlugin(registrar,channel,registrar.activity()));
    }

    private JmlinkFlutterPlugin(PluginRegistry.Registrar registrar, MethodChannel channel, Activity activity){
        this.context = registrar.context();
        this.channel = channel;
        this.activity = new WeakReference<>(activity);
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"onMethodCall:" + call.method);
        if (call.method.equals("setup")) {
            setup(call,result);
        }else if (call.method.equals("setDebugMode")) {
            setDebugMode(call,result);
        }else if (call.method.equals("registerJMLinkDefaultHandler")) {
            registerJMLinkDefaultHandler(call,result);
        }else if (call.method.equals("registerJMLinkHandler")) {
            registerJMLinkHandler(call,result);
        }else if (call.method.equals("getJMLinkParam")) {
            getJMLinkParam(call,result);
        }else {
            result.notImplemented();
        }
    }


    private void setup(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"setup");
        JMLinkAPI.getInstance().init(context);
    }

    private void setDebugMode(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"setDebugMode");

        Object enable = getValueByKey(call,"debug");
        JMLinkAPI.getInstance().setDebugMode((boolean)enable);
    }

    private void registerJMLinkDefaultHandler(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"registerJMLinkDefaultHandler");

        JMLinkAPI.getInstance().registerDefault(new JMLinkCallback() {
            @Override
            public void execute(Map<String, String> map, Uri uri) {
                HashMap jsonMap = new HashMap();
                if (map != null) {
                    jsonMap.putAll(map);
                }
                channel.invokeMethod("onReceiveJMLinkDefaultHandler",jsonMap);
            }
        });
    }

    private void registerJMLinkHandler(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"registerJMLinkHandler");

        final String jmlink_key = (String)getValueByKey(call,jmlink_handler_key);

        JMLinkAPI.getInstance().register(jmlink_key, new JMLinkCallback() {
            @Override
            public void execute(Map<String, String> map, Uri uri) {

                HashMap jsonMap = new HashMap();
                jsonMap.put(jmlink_handler_key,jmlink_key);
                if (map != null) {
                    jsonMap.putAll(map);
                }
                channel.invokeMethod("onReceiveJMLinkHandler",jsonMap);
            }
        });


        JMLinkAPI.getInstance().deferredRouter();

        if (activity.get() != null) {
            Uri uri = activity.get().getIntent().getData();
            if (uri != null) {//uri不为null，表示应用是从scheme拉起
                JMLinkAPI.getInstance().router(uri);
            }else {
                JMLinkAPI.getInstance().checkYYB( new YYBCallback() {
                    @Override
                    public void onFailed() {

                    }

                    @Override
                    public void onSuccess() {

                    }
                });
            }
        }
    }

    private void getJMLinkParam(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG,"getJMLinkParam");

        Map object = JMLinkAPI.getInstance().getParams();
        result.success(object);
    }



    private Object valueForKey(Map para,String key){
        if (para != null && para.containsKey(key)){
            return  para.get(key);
        }else {
            return null;
        }
    }

    private Object getValueByKey(MethodCall call,String key){
        if (call != null && call.hasArgument(key)){
            return  call.argument(key);
        }else {
            return null;
        }
    }
}

