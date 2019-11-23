import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/material.dart';
import 'package:hsa_app/event/app_event.dart';
import 'package:hsa_app/model/pageConfig.dart';
import 'package:hsa_app/model/province.dart';
import 'package:hsa_app/model/station.dart';
import 'package:hsa_app/model/version.dart';
import 'package:hsa_app/util/encrypt.dart';
import 'package:hsa_app/util/share.dart';
import 'package:ovprogresshud/progresshud.dart';
import 'package:hsa_app/model/banner_item.dart';

typedef HttpSuccCallback = void Function(dynamic data, String msg);
typedef HttpFailCallback = void Function(String msg);

// 获取广告栏列表
typedef BannerResponseCallBack = void Function(List<BannerItem> banners);
// 获取省份列表
typedef ProvinceResponseCallBack = void Function(List<String> provinces);
// 获取电站数量
typedef StationCountResponseCallBack = void Function(int count);

class HttpResult {
  String msg;
  bool success;
}

class HttpHelper {

  // 开启代理模式,可抓包
  static final isProxyModeOpen = true;
  static final proxyIP = 'PROXY 192.168.31.74:8888';
  // 超时时间
  static final receiveTimeout = 20;
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
  static void handleDioError(dynamic e) {
    debugPrint('HttpError ❌ : '+ e.toString());
    if (e is DioError) {
      DioError dioError = e;
      var code = dioError.response.statusCode;
      debugPrint('DioError ❌ : '+ dioError.toString());
      // 401 Authorization 过期
      if (code == 401) {
        debugPrint('🔑 Authorization 过期错误');
        EventTaxiImpl.singleton().fire(TokenExpireEvent());
      } else {
        
      }
    }
  }

  // GET 请求统一封装
  static void getHttp(
      String path, 
      Map<String, dynamic> param, 
      HttpSuccCallback onSucc,
      HttpFailCallback onFail ) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = Dio();

    // 代理控制
    if (isProxyModeOpen == true) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
        client.findProxy = (_) => proxyIP;
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    }

    // 尝试请求
    try {
      final url = API.host + path;
      Response response = await dio.get(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: HttpHelper.receiveTimeout,
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
      if (response.data is! Map) {
        onFail('请求错误');
        return;
      }
      // 初步解析数据包
      Map<String, dynamic> map = response.data;
      var code = map['code'] ?? -1;
      if (code != 0) {
        var msg = map['msg'] ?? '请求错误';
        onFail(msg);
        return;
      }
      var msg = map['msg'] ?? '请求成功';
      onSucc(response.data, msg);
    } catch (e) {
      handleDioError(e);
      onFail('请求错误');
    }
  }

  // POST 请求统一封装
  static void postHttp(
      String path, 
      dynamic param, 
      HttpSuccCallback onSucc,
      HttpFailCallback onFail ) async {

    // 检测网络
    var isReachable = await isReachablity();
    if (isReachable == false) {
      if (onFail != null) {
        onFail('网络异常,请检查网络');
        return;
      }
    }

    var dio = Dio();

    // 代理控制
    if (isProxyModeOpen == true) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
        client.findProxy = (_) => proxyIP;
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    }

    // 尝试请求
    try {
      final url = API.host + path;
      Response response = await dio.post(
        url,
        options: Options(
          headers: {'Authorization': ShareManager.instance.token},
          contentType: Headers.formUrlEncodedContentType,
          receiveTimeout: HttpHelper.receiveTimeout,
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
      if (response.data is! Map) {
        onFail('请求错误');
        return;
      }
      // 初步解析数据包
      Map<String, dynamic> map = response.data;
      var code = map['code'] ?? -1;
      if (code != 0) {
        var msg = map['msg'] ?? '请求错误';
        onFail(msg);
        return;
      }
      var msg = map['msg'] ?? '请求成功';
      onSucc(response.data, msg);
    } catch (e) {
      handleDioError(e);
      onFail('请求错误');
    }
  }

}

class API {
  // 内网主机地址
  static final host = 'http://192.168.16.120:18081/';
  // 穿透内网主机地址
  // static final host = 'http://18046053193.qicp.vip:20187/';

  // 文件路径 与 地址
  static final filePath = 'HsaApp2.0/Native/';
  static final fileVersionInfo = 'appVersion.json';
  static final fileWebRoute = 'pageConfig.json';

  // API 接口地址
  static final loginPath = 'Account/Login';
  static final pswdPath = 'api/Account/ChangePassword';
  static final customStationInfoPath = 'api/General/CustomerStationInfo';
  static final terminalInfoPath = '/api/General/TerminalInfo';
  static final treeNodePath = 'CustomerHydropowerStation/TreeNodeJSON';
  // 设备运行参数概要
  static final runtimeDataPath = 'api/General/RuntimeData';

  // 上传文件
  static final uploadFilePath = 'Api/Account/UploadMobileAccountCfg';
  // 下载文件
  static final downloadFilePath = 'Api/Account/DownloadMobileAccountCfg';

  // 广告栏
  static final bannerListPath = 'app/GetBannerList';
  // 省份列表
  static final provinceListPath = 'app/GetProvinceList';
  // 电站列表
  static final stationListPath = 'app/GetStationList';

  // 广告栏
  static void banners(BannerResponseCallBack onSucc,HttpFailCallback onFail) {

    HttpHelper.getHttp(
      bannerListPath, null, 
      (dynamic data,String msg) {
        var map  = data as Map<String,dynamic>;
        var resp = BannerResponse.fromJson(map);
        if(onSucc != null) onSucc(resp.data.banner);
      }, 
      onFail);
  }

  // 省份列表
  static void provinces(ProvinceResponseCallBack onSucc,HttpFailCallback onFail) {

    HttpHelper.getHttp(
      provinceListPath, null, 
      (dynamic data,String msg) {
        var map  = data as Map<String,dynamic>;
        var resp = ProviceResponse.fromJson(map);
        if(onSucc != null) onSucc(resp.data.province);
      }, 
      onFail);
  }

  // 获取电站数量
  static void stationsCount(StationCountResponseCallBack onSucc,HttpFailCallback onFail) {

    HttpHelper.getHttp(
      stationListPath, {
      'page':'1',
      'rows':'1',
    },
    (dynamic data,String msg) {
        var map  = data as Map<String,dynamic>;
        var resp = StationsResponse.fromJson(map);
        if(onSucc != null) onSucc(resp.data?.total ?? 0);
      }, 
      onFail);
  }

  // 

  // 获取设备运行参数
  // static Future<RunTimeData> runtimeData(String addressId) async {

  //   if(addressId == null)return null;
  //   if(addressId.length ==0) return null;

  //   try {
  //     final path = host + runtimeDataPath + '/' + addressId;
  //     Response response = await Dio().post(path,
  //       options: Options(
  //         headers: {
  //           'Authorization':ShareManager.instance.token
  //         }
  //       )
  //     );
  //     if(response.statusCode != 200) {
  //       return null;
  //     }
  //     if(response.data is! Map) {
  //       return null;
  //     }
  //     var map  = response.data as Map<String,dynamic>;
  //     var data = RunTimeData.fromJson(map);
  //     return data;
  //     } catch (e) {
  //       handleError(e);
  //       debugPrint('错误❌:' + e.toString());
  //     }
  //     return null;
  // }

  // 上传文件
  static Future<bool> uploadFileJson(String uploadJsonString) async {
    if (uploadJsonString == null) return false;
    if (uploadJsonString.length == 0) return false;

    var dio = Dio();
    // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
    // client.findProxy = (_) => "PROXY 192.168.31.74:8888";
    // client.badCertificateCallback =  (X509Certificate cert, String host, int port) => true;
    // };
    try {
      final path = host + uploadFilePath;
      Response response = await dio.post(
        path,
        options: Options(
          headers: {
            'Authorization': ShareManager.instance.token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: {'': uploadJsonString ?? ''},
      );
      if (response.statusCode != 200) {
        return false;
      }
      if (response.data is! Map) {
        return false;
      }
      Map<String, dynamic> map = response.data;
      if (map['code'] == 0) return true;
      return false;
    } catch (e) {
      // handleError(e);
      EventTaxiImpl.singleton().fire(TokenExpireEvent());
      return false;
    }
  }

  // 下载文件
  static Future<String> downloadFileJson() async {
    try {
      final path = host + downloadFilePath;
      Response response = await Dio().get(
        path,
        options: Options(
          headers: {
            'Authorization': ShareManager.instance.token,
          },
          responseType: ResponseType.plain,
        ),
      );
      if (response.statusCode != 200) {
        return null;
      }
      if (response.data is! String) {
        return null;
      }
      String jsonString = response.data;
      return jsonString;
    } catch (e) {
      debugPrint(e.toString());
      // handleError(e);
    }
    return null;
  }

  // 更改登录密码
  static Future<HttpResult> modifyPswd(String oldWord, String newWord) async {
    if (oldWord == null || newWord == null) return null;
    if (oldWord.length == 0 || newWord.length == 0) return null;

    var secOld = LDEncrypt.encryptedMd5Pwd(oldWord);
    var secNew = LDEncrypt.encryptedMd5Pwd(newWord);

    debugPrint('🔑旧密码:' + secOld);
    debugPrint('🔑新密码:' + secNew);

    HttpResult result = HttpResult();
    result.success = false;
    result.msg = '请求错误.';

    Progresshud.showWithStatus('密码修改中...');

    try {
      final path = host + pswdPath;
      Response response = await Dio().post(
        path,
        options: Options(
          headers: {
            'Authorization': ShareManager.instance.token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
        data: {
          'oldPassword': secOld,
          'newPassword': secNew,
        },
      );
      if (response.statusCode != 200) {
        Progresshud.dismiss();
        Progresshud.showSuccessWithStatus('修改失败');
        return result;
      }
      if (response.data is! Map) {
        Progresshud.dismiss();
        Progresshud.showSuccessWithStatus('修改失败');
        return result;
      }
      var map = response.data as Map<String, dynamic>;
      var pass = map['Success'];
      if (pass) {
        result.success = true;
        result.msg = '';
        Progresshud.dismiss();
        Progresshud.showSuccessWithStatus('修改成功');
      } else {
        result.success = false;
        result.msg = map['Msg'] ?? '';
        Progresshud.dismiss();
        Progresshud.showErrorWithStatus(result.msg);
      }
      return result;
    } catch (e) {
      Progresshud.dismiss();
      Progresshud.showErrorWithStatus('网络错误');
      print(e);
      return result;
    }
  }

  // 获取所有电站列表 From TreeNodeJson 含有链接数据
  // static Future<List<Station>> getStationsFromTreeNode() async {

  //   Progresshud.showWithStatus('正在加载...');

  //   try {
  //     final path = host + treeNodePath;
  //     Response response = await Dio().get(path,
  //       options: Options(
  //         headers: {
  //           'Authorization':ShareManager.instance.token
  //         }
  //       )
  //     );
  //     if(response.statusCode != 200) {
  //       Progresshud.dismiss();
  //       Progresshud.showErrorWithStatus('请求失败');
  //       return null;
  //     }
  //     if(response.data is! List){
  //       Progresshud.dismiss();
  //       Progresshud.showErrorWithStatus('请求失败');
  //       return null;
  //     }
  //     List<Station> stations = [];
  //     var list = response.data as List;
  //     for (var item in list) {
  //       Station station = Station.fromJson(item);
  //       stations.add(station);
  //     }
  //     Progresshud.dismiss();
  //     return stations;
  //     } catch (e) {
  //       handleError(e);
  //     }
  //     return null;
  // }

  // 获取所有电站列表
  // static Future<List<StationOld>> getAllStations() async {

  //   try {
  //     final path = host + customStationInfoPath;
  //     Response response = await Dio().get(path,
  //       options: Options(
  //         headers: {
  //           'Authorization':ShareManager.instance.token
  //         }
  //       )
  //     );
  //     if(response.statusCode != 200) {
  //       return null;
  //     }
  //     if(response.data is! List){
  //       return null;
  //     }
  //     List<StationOld> stations = [];
  //     var list = response.data as List;
  //     for (var item in list) {
  //       StationOld station = StationOld.fromJson(item);
  //       stations.add(station);
  //     }
  //     return stations;
  //     } catch (e) {
  //       handleError(e);
  //     }
  //     return null;
  // }



  // Touch 外部环境
  static Future<String> touchNetWork() async {
    try {
      final path = 'http://www.baidu.com';
      Response response = await Dio().get(path);
      if (response.statusCode != 200) {
        return null;
      }
      return '';
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Touch Url
  static Future<String> touchNetWorkWithUrl(String url) async {
    try {
      Response response = await Dio().get(
        url,
        options: Options(
          headers: {
            'Authorization': ShareManager.instance.token,
          },
          contentType: Headers.formUrlEncodedContentType,
        ),
      );
      if (response.statusCode != 200) {
        return null;
      }
      return '';
    } catch (e) {
      print(e);
      return null;
    }
  }

  // 获取远端版本信息接口(文件)
  static Future<Version> getAppVersionRemote() async {
    try {
      final path = host + filePath + fileVersionInfo;
      Response response = await Dio().get(path);
      if (response.statusCode != 200) {
        return null;
      }
      var map = response.data;
      var version = Version.fromJson(map);
      return version;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // 获取web路由接口(文件)
  static Future<PageConfig> getWebRoute() async {
    try {
      final path = host + filePath + fileWebRoute;
      Response response = await Dio().get(path);
      if (response.statusCode != 200) {
        return null;
      }
      var map = response.data;
      var webRoute = PageConfig.fromJson(map);
      return webRoute;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // 机组信息列表根据客户Id和电站Id
  // static Future<List<Terminal>> getTerminalsWithCustomIdAndStationId(String customId,String stationId) async {
  //   Progresshud.showWithStatus('正在加载...');
  //   try {
  //     final path = host + terminalInfoPath + '/' + customId + '/' + stationId;
  //     Response response = await Dio().get(path,
  //       options: Options(
  //         headers: {
  //           'Authorization':ShareManager.instance.token
  //         }
  //       )
  //     );
  //     if(response.statusCode != 200) {
  //       Progresshud.dismiss();
  //       Progresshud.showErrorWithStatus('请求失败...');
  //       return null;
  //     }
  //     if(response.data is! List){
  //       Progresshud.dismiss();
  //       Progresshud.showErrorWithStatus('请求失败...');
  //       return null;
  //     }
  //     List<Terminal> terminals = [];
  //     var list = response.data as List;
  //     for (var item in list) {
  //       Terminal terminal = Terminal.fromJson(item);
  //       terminals.add(terminal);
  //     }
  //     Progresshud.dismiss();
  //     return terminals;
  //     } catch (e) {
  //       handleError(e);
  //     }
  //     return null;
  // }

  // 登录获取 Token
  static Future<String> getLoginToken(String name, String pwd) async {
    try {
      final path = host + loginPath;
      Response response = await Dio().post(
        path,
        queryParameters: {
          'accountName': name,
          'accountPwd': LDEncrypt.encryptedMd5Pwd(pwd)
        },
      );
      if (response.statusCode != 200) {
        return '';
      }
      var map = response.data;
      bool loginSucc = map['Success'];
      if (loginSucc) {
        var authorizationList = response.headers['set-authorization'];
        if (authorizationList is List<String>) {
          List<String> list = authorizationList;
          var token = list.first;
          return token;
        }
        return '';
      } else {
        return '';
      }
    } catch (e) {
      print(e);
      return '';
    }
  }
}
