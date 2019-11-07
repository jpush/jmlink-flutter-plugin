## API

#### setup

初始化sdk,  appKey 和 channel 只对ios设置有效，Android 的直接读取配置文件里的 AppKey

```
JMConfig config = new JMConfig();
config.appKey = "你的 AppKey";
config.channel = "channel";
config.useIDFA = false;
config.isProduction = true;

jmlink.setup(config: config);
```

#### setDebugMode
设置是否开启debug模式。true则会打印更多的日志信息

```
jmlink.setDebugMode(debug: true);
```

#### registerJMLinkDefaultHandler

- 注册handler

注册一个默认的mLink handler，当接收到URL，并且所有的mLink key都没有匹配成功，就会调用默认的mLink handler

```
jmlink.registerJMLinkDefaultHandler();
```

- 监听数据回调

```
// 监听默认的 mLink handler 回调
jmlink.addDefaultHandlerListener((Map jsonMap){
  print("监听到默认短链的 mLink handler 回调，回调参数为：${jsonMap.toString()}");
});
```

#### registerJMLinkHandler

注册一个mLink handler，当接收到URL的时候，会根据mLink key进行匹配，当匹配成功会调用相应的 handler 回调

key 后台注册mlink时生成的mlink key



```
// 监听 某个锻炼mLink handler 回调
String jmlinkKey = "jmlinkKey";// 短链 key
jmlink.addHandlerListener(jmlinkKey, (String key, Map jsonMap){
  if (jmlinkKey == key) {
    print("监听到短链为【$jmlinkKey】的 mLink handler 回调，回调参数为：${jsonMap.toString()}");
  }
});
// 注册短链对应的 handler
jmlink.registerJMLinkHandler(key: jmlinkKey);
```

#### getJMLinkParam


```
jmlink.getJMLinkParam().then((param){
      print("获取到无码邀请参数为： ${param.toString()}");
      setState(() {
        _paramString = param.toString();
      });
    });
```