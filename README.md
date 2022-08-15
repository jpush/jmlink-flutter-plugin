

# Jmlink Flutter Plugin

### 安装

在工程 pubspec.yaml 中加入 dependencies

```yaml
//pub 集成
dependencies:
  jmlink_flutter_plugin: 2.1.3

  
//github 集成  
dependencies:
  jmlink_flutter_plugin:
    git:
      url: git://github.com/jpush/jmlink-flutter-plugin.git
      ref: master
```
### 配置

##### Android:

+ 在 `/android/app/build.gradle` 中添加下列代码：

```groovy
android: {
  ....
  defaultConfig {
    applicationId "替换成自己应用 ID"
    ...
    ndk {
	//选择要添加的对应 cpu 类型的 .so 库。
	abiFilters 'armeabi', 'armeabi-v7a', 'x86', 'x86_64', 'mips', 'mips64', 'arm64-v8a',        
    }

    manifestPlaceholders = [
        JPUSH_PKGNAME : applicationId,
        JPUSH_APPKEY : "appkey", // NOTE: JPush 上注册的包名对应的 Appkey.
        JPUSH_CHANNEL : "developer-default", //暂时填写默认值即可.
        JMLINK_SCHEME: "you scheme",//  设置跳转的scheme
    ]
  }    
}
```

+ 在 `/android/app/src/main/AndroidManifest.xml` 中配置 scheme

```
<!-- 将“你的Scheme”替换为后台填写的URI Scheme。-->

<activity android:name=".WelcomeActivity">
         <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme='${JMLINK_SCHEME}' />
         </intent-filter>
</activity>
```

***注意：***配置完`scheme`之后，必须在 `WelcomeActivity` 的 `onCreate` 方法中执行 `JmlinkFlutterPlugin.setData`方法：

```
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
```

#### iOS

[详细请看](https://docs.jiguang.cn/jmlink/client/iOS/ios_guide/)

- 1.配置App的URL Scheme

iOS系统中App之间是相互隔离的，通过URL Scheme，App之间可以相互调用，并且可以传递参数。

选中Target->Info->URL Types，配置URL Scheme（比如：jmlink）

在Safari中输入URL Scheme://（比如：jmlink://）如果可以唤起App，说明该URL Scheme配置成功

- 2.配置Universal link

Universal link是iOS9的一个新特性，通过Universal link，App可以无需打开Safari，直接从微信等应用中跳转到App，真正的实现一键直达

