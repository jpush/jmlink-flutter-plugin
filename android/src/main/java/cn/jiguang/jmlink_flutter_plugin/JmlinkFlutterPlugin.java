package cn.jiguang.jmlink_flutter_plugin;

import android.app.Activity;
import android.content.Context;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;

import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.Map;

import cn.jiguang.jmlinksdk.api.JMLinkAPI;
import cn.jiguang.jmlinksdk.api.JMLinkCallback;
import cn.jiguang.jmlinksdk.api.ReplayCallback;
import cn.jiguang.jmlinksdk.api.YYBCallback;
import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;

public class JmlinkFlutterPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {

    // 定义日志 TAG
    private static final String TAG = "| JML | Android | -";


    private static final String jmlink_handler_key = "jmlink_handler_key";
    private static final String jmlink_getParam_key = "jmlink_getParam_key";

    public static JmlinkFlutterPlugin instance;
    private Context context;
    private MethodChannel channel;
    private static Uri myUri;
    private boolean isSetup = false;
    private boolean isRegisterHandler = false;
    private boolean isRegisterDefaultHandler = false;


    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.jiguang.jmlink_flutter_plugin");
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
    }


    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        instance.isSetup = false;
        instance.isRegisterHandler = false;
        instance.isRegisterDefaultHandler = false;
    }

    public JmlinkFlutterPlugin() {
        instance = this;
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "onMethodCall:" + call.method);
        if (call.method.equals("setup")) {
            setup(call, result);
        } else if (call.method.equals("setDebugMode")) {
            setDebugMode(call, result);
        } else if (call.method.equals("registerJMLinkDefaultHandler")) {
            registerJMLinkDefaultHandler(call, result);
        } else if (call.method.equals("registerJMLinkHandler")) {
            registerJMLinkHandler(call, result);
        } else if (call.method.equals("getJMLinkParam")) {
            getJMLinkParam(call, result);
        } else {
            result.notImplemented();
        }
    }


    public static void setData(Uri uri) {
        Log.d(TAG, "setData:" + uri);
        myUri = uri;
        scheduleCache();
    }

    private void setup(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "setup:" + call.arguments.toString());

        HashMap<String, Object> map = call.arguments();


        //初始化SDK
        JMLinkAPI.getInstance().init(context);

        //设置Debug
        Object debug = getValueByKey(call, "debug");
        if (debug != null) {
            JMLinkAPI.getInstance().setDebugMode((boolean) debug);
        }

        //设置剪切板
        Object clipboardEnable = getValueByKey(call, "clipboardEnable");
        if (clipboardEnable != null) {
            JMLinkAPI.getInstance().enabledClip((boolean) clipboardEnable);
        }

        JmlinkFlutterPlugin.instance.isSetup = true;
        scheduleCache();
    }

    private void setDebugMode(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "setDebugMode");

        Object enable = getValueByKey(call, "debug");
        JMLinkAPI.getInstance().setDebugMode((boolean) enable);
    }

    private void registerJMLinkDefaultHandler(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "registerJMLinkDefaultHandler：");

        instance.isRegisterDefaultHandler = true;
        JMLinkAPI.getInstance().registerDefault(new JMLinkCallback() {
            @Override
            public void execute(Map<String, String> map, Uri uri) {
                Log.d(TAG, "registerJMLinkDefaultHandler：" + "map=" + map + ",uri = " + uri);

                HashMap jsonMap = new HashMap();
                if (map != null) {
                    jsonMap.putAll(map);
                }

                runMainThread(jsonMap, null, "onReceiveJMLinkDefaultHandler");
            }
        });

        //router(myUri);
        scheduleCache();
    }

    private void registerJMLinkHandler(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "registerJMLinkHandler");

        instance.isRegisterHandler = true;
        final String jmlink_key = (String) getValueByKey(call, jmlink_handler_key);

        JMLinkAPI.getInstance().register(jmlink_key, new JMLinkCallback() {
            @Override
            public void execute(Map<String, String> map, Uri uri) {
                Log.d(TAG, "registerJMLinkHandler：" + "map=" + map + ",uri = " + uri);

                HashMap jsonMap = new HashMap();
                jsonMap.put(jmlink_handler_key, jmlink_key);
                if (map != null) {
                    jsonMap.putAll(map);
                }

                runMainThread(jsonMap, null, "onReceiveJMLinkHandler");
            }
        });
        //router(myUri);
        scheduleCache();
    }

    private void getJMLinkParam(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, "getJMLinkParam");

        Map object = JMLinkAPI.getInstance().getParams();

        runMainThread(object, result, null);
    }

    public static void scheduleCache() {
        Log.d(TAG, "scheduleCache ");
        if (instance == null) {
            return;
        }
        if (instance.isSetup) {
            Log.d(TAG, "scheduleCache - " + "handler=" + instance.isRegisterHandler + "，defaultHandler=" + instance.isRegisterDefaultHandler);
            if (!instance.isRegisterHandler && !instance.isRegisterDefaultHandler) {
                return;
            }
            //if (myUri != null) { }
            router(myUri);
        }
    }

    private static void router(Uri uri) {
        Log.d(TAG, "router:" + uri);

        //JMLinkAPI.getInstance().deferredRouter();
        if (uri != null) {//uri不为null，表示应用是从scheme拉起
            JMLinkAPI.getInstance().router(uri);
            myUri = null;
        } else {
            JMLinkAPI.getInstance().replay(new ReplayCallback() {
                @Override
                public void onFailed() {

                }

                @Override
                public void onSuccess() {

                }
            });
//            JMLinkAPI.getInstance().checkYYB( new YYBCallback() {
//                @Override
//                public void onFailed() {
//                    Log.d(TAG,"router - " + "checkYYB - onFailed");
//                }
//
//                @Override
//                public void onSuccess() {
//                    Log.d(TAG,"router - " + "checkYYB - onSuccess");
//                }
//            });
        }
    }


    // 主线程再返回数据
    private void runMainThread(final Map<String, Object> map, final MethodChannel.Result result, final String method) {
        Handler handler = new Handler(Looper.getMainLooper());
        handler.post(new Runnable() {
            @Override
            public void run() {
                if (result != null && method == null) {
                    result.success(map);
                } else if (method != null) {
                    channel.invokeMethod(method, map);
                } else {

                }

            }
        });
    }


    private Object valueForKey(Map para, String key) {
        if (para != null && para.containsKey(key)) {
            return para.get(key);
        } else {
            return null;
        }
    }

    private Object getValueByKey(MethodCall call, String key) {
        if (call != null && call.hasArgument(key)) {
            return call.argument(key);
        } else {
            return null;
        }
    }
}

