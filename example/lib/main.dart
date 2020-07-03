import 'package:flutter/material.dart';
import 'dart:async';

import 'package:jmlink_flutter_plugin/jmlink_flutter_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final JmlinkFlutterPlugin jmlink = new JmlinkFlutterPlugin();


  String _paramString = "param";
  String _defaultMlinkMapString = "default handler";
  String _milinkMapString = "key handler";

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }



  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {

    JMLConfig config = new JMLConfig();
    config.appKey = "你自己应用的 AppKey";
    config.channel = "devloper-default";// 初始化sdk,  appKey 和 channel 只对ios设置有效
    config.useIDFA = false;
    config.isProduction = true;
    config.debug = true;


    jmlink.setup(config: config);

    registerDefaultJMLinkHandler();

    if (!mounted) return;

  }

  // 注册默认的 handler
  registerDefaultJMLinkHandler() {
    // 监听默认的 mLink handler 回调
    jmlink.addDefaultHandlerListener((Map jsonMap){
      print("监听到默认短链的 mLink handler 回调，回调参数为：${jsonMap.toString()}");
      setState(() {
        _defaultMlinkMapString = jsonMap.toString();
      });
      getJMLinkParam();
    });
    // 注册默认的 handler
    jmlink.registerJMLinkDefaultHandler();
  }


  // 获取无码邀请返回参数
  getJMLinkParam(){
    jmlink.getJMLinkParam().then((param){
      print("获取到无码邀请参数为： ${param.toString()}");
      setState(() {
        _paramString = param.toString();
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            new Text("默认的 mLink handler 回调:"),
            new Container(
              margin: EdgeInsets.all(5),
              color: Colors.brown,
              child: Text(_defaultMlinkMapString),
              width: double.infinity,
              height: 80,
            ),
            new Text(" mLink handler 回调:"),
            new Container(
              margin: EdgeInsets.all(5),
              color: Colors.brown,
              child: Text(_milinkMapString),
              width: double.infinity,
              height: 80,
            ),
            new Text("无码邀请返回参数:"),
            new Container(
              margin: EdgeInsets.all(5),
              color: Colors.brown,
              child: Text(_paramString),
              width: double.infinity,
              height: 80,
            ),
          ],
        ),
      ),
    );
  }
}
