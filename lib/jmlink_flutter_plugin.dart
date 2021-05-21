import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef JMLDefaultHandlerListener = void Function(Map jsonMap);
typedef JMLHandlerListener = void Function(String key, Map jsonMap);

class JMLEventHandlers {
  static final JMLEventHandlers _instance = new JMLEventHandlers._internal();

  JMLEventHandlers._internal();

  factory JMLEventHandlers() => _instance;

  List<JMLDefaultHandlerListener> defaultHandlerEvents = [];
  Map<String, List<JMLHandlerListener>> handlerMap = Map();
}

class JmlinkFlutterPlugin {
  final String flutterLog = "| JML | Flutter | - ";

  static const String jmlink_handler_key = "jmlink_handler_key";
  static const String jmlink_getParam_key = "jmlink_getParam_key";

  static const String _methodChannelName = 'com.jiguang.jmlink_flutter_plugin';
  final MethodChannel _methodChannel;
  final JMLEventHandlers _eventHanders = new JMLEventHandlers();

  // 工厂模式 : 单例公开访问点
  factory JmlinkFlutterPlugin() => _getInstance();

  static JmlinkFlutterPlugin get instance => _getInstance();

  // 静态私有成员，没有初始化
  static JmlinkFlutterPlugin? _instance;

  // 私有构造函数
  JmlinkFlutterPlugin._internal(MethodChannel channel)
      : _methodChannel = channel;

  /// 静态、同步、私有访问点
  static JmlinkFlutterPlugin _getInstance() {
    if (_instance == null) {
      _instance =
          new JmlinkFlutterPlugin._internal(MethodChannel(_methodChannelName));
    }
    return _instance!;
  }

  /// 添加 默认的mLink handler 的监听
  /// 在监听回调里，根据返回的参数做相应的操作，如：跳转页面
  addDefaultHandlerListener(JMLDefaultHandlerListener callback) {
    _eventHanders.defaultHandlerEvents.add(callback);
  }

  /// 添加 mLink handler 的监听
  /// @para jmlinkKey 需要监听的短链
  /// 在监听回调里，根据返回的参数做相应的操作，如：跳转页面
  addHandlerListener(String jmlinkKey, JMLHandlerListener callback) {
    List<JMLHandlerListener>? list = _eventHanders.handlerMap[jmlinkKey];
    if (list == null) {
      list = [];
    }
    list.add(callback);
    _eventHanders.handlerMap[jmlinkKey] = list;
  }

  /// 监听回调方法
  Future<void> _handlerMethod(MethodCall call) async {
    print(flutterLog + "handleMethod method = ${call.method}");
    switch (call.method) {
      case 'onReceiveJMLinkDefaultHandler':
        {
          for (JMLDefaultHandlerListener cb
              in _eventHanders.defaultHandlerEvents) {
            Map jsonMap = call.arguments.cast<dynamic, dynamic>();
            cb(jsonMap);
          }
        }
        break;
      case 'onReceiveJMLinkHandler':
        {
          Map jsonMap = call.arguments.cast<dynamic, dynamic>();
          String jmlinkKey = jsonMap[jmlink_handler_key];
          bool isContains = _eventHanders.handlerMap.containsKey(jmlinkKey);
          if (isContains) {
            jsonMap.remove(jmlink_handler_key);
            List<JMLHandlerListener>? list =
                _eventHanders.handlerMap[jmlinkKey];
            if (list != null) {
              for (JMLHandlerListener cb in list) {
                cb(jmlinkKey, jsonMap);
              }
            }
          }
        }
        break;
      default:
        throw new UnsupportedError("Unrecognized Event");
    }
    return;
  }

  /// 初始换 SDK
  void setup({@required JMLConfig? config}) {
    print(flutterLog + "setup");
    _methodChannel.setMethodCallHandler(_handlerMethod);
    _methodChannel.invokeMethod("setup", config?.toMap());
  }

  /// 过期方法，请在 【setup】方法中设置
  /// 设置 SDK 是否 debug 模式
  void setDebugMode({@required bool? debug}) {
    print(flutterLog + "setDebugMode");
    _methodChannel.invokeMethod("setDebugMode", {"debug": debug});
  }

  /// 注册一个默认的 mLink handler，当接收到URL，并且所有的 mLink key 都没有匹配成功，就会调用默认的 mLink handler
  /// handler mlink 的回调通过 addDefaultHandlerListener 来监听
  void registerJMLinkDefaultHandler() {
    print(flutterLog + "registerJMLinkDefaultHandler");
    _methodChannel.invokeMethod("registerJMLinkDefaultHandler");
  }

  /// 注册一个mLink handler，当接收到URL的时候，会根据mLink key进行匹配，当匹配成功会调用相应的handler
  /// @param key 后台注册mlink时生成的mlink key
  /// handler mlink 的回调通过 addHandlerListener 来监听
  void registerJMLinkHandler({@required String? key}) {
    print(flutterLog + "registerJMLinkHandler: key=$key");
    if (key == null) {
      print(flutterLog + "mlink key can not be nil");
      return;
    }
    _methodChannel
        .invokeMethod("registerJMLinkHandler", {jmlink_handler_key: key});
  }

  /// 获取无码邀请中传回来的相关值
  /// return 无码邀请中传回来的相关值
  Future<Map> getJMLinkParam() async {
    print(flutterLog + "getJMLinkParam");

    Map map = await _methodChannel.invokeMethod("getJMLinkParam");
    return map;
  }
}

/// 配置类
class JMLConfig {
  String? appKey; // appKey 必须的,应用唯一的标识
  String? channel = ""; // channel 发布渠道. 可选，默认为空
  bool useIDFA = false; // only iOS， advertisingIdentifier 广告标识符（IDFA). 可选，默认为空
  bool isProduction =
      false; //isProduction 是否生产环境. 如果为开发状态,设置为NO;如果为生产状态,应改为YES.可选，默认为NO
  bool debug = false; //设置日志debug级别，可以查看更多日志
  bool clipboardEnable = true; // 是否启用剪切板，启用剪切板会大大增加场景还原成功率

  JMLConfig() {
    print("JMConfig init");
  }

  JMLConfig.fromJson(Map<dynamic, dynamic> json)
      : appKey = json['appKey'],
        channel = json['channel'],
        useIDFA = json['useIDFA'],
        isProduction = json['isProduction'],
        debug = json['debug'],
        clipboardEnable = json['clipboardEnable'];

  Map toMap() {
    return {
      'appKey': appKey,
      'channel': channel ??= "",
      'useIDFA': useIDFA,
      'isProduction': isProduction,
      'debug': debug,
      'clipboardEnable': clipboardEnable,
    }..removeWhere((key, value) => value == null);
  }
}
