import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hsa_app/event/app_event.dart';
import 'package:hsa_app/event/event_bird.dart';
import 'package:hsa_app/util/share.dart';

typedef DebugHttpSuccCallback = void Function(dynamic data, String msg);
typedef DebugHttpFailCallback = void Function(String msg);

class DebugHttpHelper {

  // 开启代理模式,允许抓包
  static final isProxyModeOpen = true;
  // 代理主机地址
  static final proxyHost = '192.168.31.8:8888';
  // 接受超时时间
  static final recvTimeOutSeconds = 10000;
  // 发送超时时间
  static final sendTimeOutSeconds = 10000;

  // 创建 DIO 对象
  static Dio initDio() { 
    var dio = Dio();
    var adapter = dio.httpClientAdapter as DefaultHttpClientAdapter;
    adapter.onHttpClientCreate = (HttpClient client) {
        client.findProxy = (_) => isProxyModeOpen ? 'PROXY ' + proxyHost : 'DIRECT';
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    };
    return dio;
  }

  // 检测网络
  static Future<bool> isReachablity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      return true;
    } else if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  // 处理 DioError
  static void handleDioError(dynamic e,DebugHttpFailCallback onFail) {

    // DIO 错误
    if (e is DioError) {

      DioError dioError = e;
      var code = dioError.response?.statusCode;
      debugPrint('DioError ❌ : '+ dioError.toString());

      // 请求错误
      if(code == null) {
        if(onFail == null) onFail('请求错误');
        return;
      }
      // 401 Authorization 过期
      if (code == 401) {
        debugPrint('🔑 Authorization 过期错误');
        if(onFail == null) onFail('请求错误');
        EventBird().emit(AppEvent.tokenExpiration);
        return;
      } 
      if(onFail == null) onFail('请求错误');
      return;
    }
    // DIO 错误
    else {
        if(onFail == null) onFail('请求错误');
        return;
    }
  }

  // GET 请求统一封装
  static void getHttp(
      String path, 
      Map<String, dynamic> param, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail) async { 

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 发求请求
    try {
      Response response = await dio.get(
        path,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        queryParameters: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }

  // POST 请求统一封装
  static void postHttp(
      String path, 
      dynamic param, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail ) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {

      Response response = await dio.post(
        path,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        queryParameters: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }

  static void postHttpForm(
      String path, 
      dynamic param, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail ) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {
      Response response = await dio.post(
        path,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        data: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }


  // GET 请求通用请求封装
  static void getHttpCommon(
      String path, 
      Map<String, dynamic> param, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {
      var url = path ?? '';
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        queryParameters: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }

  // POST Application/Json 
  static void postHttpApplicationJson(String path, dynamic param, DebugHttpSuccCallback onSucc,DebugHttpFailCallback onFail)  async  {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {
      var url = path ?? '';
      Response response = await dio.post(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.jsonContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        data: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }

  }

  // POST 请求通用封装 String 
  static void postHttpCommonString(
      String path, 
      String string, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail,
      ) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {
      var url = path ?? '';
      Response response = await dio.post(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        data: {'':string},
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }

    // GET 请求通用请求封装
  static void getHttpCommonRespList(
      String path, 
      Map<String, dynamic> param, 
      DebugHttpSuccCallback onSucc,
      DebugHttpFailCallback onFail) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = DebugHttpHelper.initDio();

    // 尝试请求
    try {
      var url = path ?? '';
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: DebugHttpHelper.recvTimeOutSeconds,
          sendTimeout: DebugHttpHelper.sendTimeOutSeconds,
        ),
        queryParameters: param,
      );
      if (response == null) {
        onFail('网络异常,请检查网络');
        return;
      }
      if (response.statusCode != 200) {
        onFail('请求错误 ( ' + response.statusCode.toString() + ' )');
        return;
      }
      if (response.data is! List) {
        onFail('请求错误');
        return;
      }
      // 初步解析数据包
      onSucc(response.data, '请求成功');
    } catch (e) {
      handleDioError(e,(String msg) => onFail(msg));
      onFail('请求错误');
    }
  }

}


class DebugHttpResult {
  String msg;
  bool success;
}
