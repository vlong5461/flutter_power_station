import 'package:flutter/material.dart';
import 'package:hsa_app/api/api_helper.dart';
import 'package:hsa_app/model/model/all_model.dart';
import 'package:hsa_app/model/response/all_resp.dart';

// 返回回调 : 
typedef HttpSuccMsgCallback = void Function(String msg);
// 获取账户信息
typedef AccountInfoCallback = void Function(AccountInfo account);
// 地址信息列表
typedef AreaInfoCallback = void Function(List<AreaInfo> areas);
// 地址信息列表
typedef StationListCallback = void Function(Data stations);
// 地址信息列表
typedef StationInfoCallback = void Function(StationInfo stationInfo);
// 地址信息列表
typedef NearestRunningDataCallback = void Function(NearestRunningData nearestRunningData);
//List
typedef ListCallback = void Function(List<String> list);
// ERCFlag类型列表
typedef ERCFlagTypeListCallback = void Function(List<ERCFlagType> types);
// 告警事件列表
typedef AlertEventListCallback = void Function(List<TerminalAlarmEvent> events);
// 水位曲线列表
typedef WaterLevelListCallback = void Function(List<WaterLevel> points);
// 有功曲线列表
typedef ActivePowerListCallback = void Function(List<ActivePower> points);
// 水轮机信息
typedef WaterTurbineCallback = void Function(WaterTurbine waterTurbines);
// 终端信息
typedef DeviceTerminalCallback = void Function(DeviceTerminal deviceTerminal);
// 终端信息
typedef TurbineCallback = void Function(List<Turbine> turbines);
//广告
typedef BannerListCallback = void Function(List<BannerModel> turbines);
//天气
typedef WeatherCallback = void Function(Weather weather);
// 有功曲线列表
typedef StatisticalPowerListCallback = void Function(List<StatisticalPower> statisticalPowerList);
// 升级文件类型列表
typedef UpgradeFileTypeCallback = void Function(List<String> upgradeFileType);
// 升级文件列表
typedef UpgradeFileListCallback = void Function(List<UpdateFile> upgradeFileList);
// 升级任务列表
typedef UpgradeTaskListCallback = void Function(List<UpdateTask> upgradeTaskList);
// 升级任务信息
typedef UpgradeTaskInfoCallback = void Function(UpdateTask upgradeTaskInfo);
// APP发布信息获取
typedef PublishCallback = void Function(Publish publish);

class API {

  // IP 地址或域名
  static final ip = '192.168.16.120'; // 开发环境 IP
  // static final ip = '27.148.136.253'; // 生产和测试环境 IP
  // static final ip = 'devops.hsa.fjlead.com';  // 生产和测试环境 IP (线上用这个)

  // 通讯代理地址
  static final agentHost    = 'http://' + ip + ':8280';

  // 基础信息地址
  static final baseHost     = 'http://' + ip + ':8281';

  // 动态数据地址
  static final liveDataHost = 'http://' + ip + ':8282';

  // 固定应用ID AppKey 由平台下发
  static final appKey = '3a769958-098a-46ff-a76a-de6062e079ee'; 

  //天气接口的版本
  static final wVersion = 'v2.5';

  //天气接口token
  static final wToken = 'TAkhjf8d1nlSlspN';

  // 获取省份列表信息
  static void getAreaList({@required String rangeLevel,AreaInfoCallback onSucc,HttpFailCallback onFail}) async {
    // 输入检查
    if(rangeLevel == null) {
      if(onFail != null) onFail('地址范围参数缺失');
      return;
    }
    
    // 获取帐号信息地址
    final path = baseHost + '/v1/City/CurrentAccountHyStation/' + '$rangeLevel';
    
    HttpHelper.httpGET(path, null, (map,_){

      var resp = AreaInfoResp.fromJson(map);
      if(onSucc != null) onSucc(resp.data);
      
    }, onFail);
  }
  

  // 获取告警事件类型列表 type = 0 水轮机 1 生态下泄
  static void getErcFlagTypeList({@required String type,ERCFlagTypeListCallback onSucc,HttpFailCallback onFail}) async {
    // 输入检查
    if(type == null) {
      if(onFail != null) onFail('终端告警类型参数缺失');
      return;
    }
    
    // 获取帐号信息地址
    final path = baseHost + '/v1/EnumAlarmEventERC/' + '$type';
    
    HttpHelper.httpGET(path, null, (map,_){

      var resp = ERCFlagTypeResp.fromJson(map);
      if(onSucc != null) onSucc(resp.data);
      
    }, onFail);
  }

  

  

  
  // 获取终端告警列表
  static void getTerminalAlertList({
        String searchAnchorDateTime,
        String searchDirection,
        String startDateTime,
        String endDateTime,
        String stationNos,
        String ercVersions,
        String eventFlags,
        String deviceTerminalType,
        String deviceTerminalHardware,
        String terminalAddress,
        int limitSize,
        bool isIncludedDetail, 
        AlertEventListCallback onSucc,HttpFailCallback onFail}) async {

    var param = Map<String, dynamic>();

    // searchAnchorDateTime	string	否	时间锚点
    if(searchAnchorDateTime != null) {
      param['searchAnchorDateTime'] = searchAnchorDateTime;
    }
    // SearchDirection	string	否	Backward(上一页)或Forward(下一页) 依赖于时间锚点，默认Forward
    if(searchDirection != null) {
      param['searchDirection'] = searchDirection;
    }
    // StartDateTime	DateTime	否	起始时间
    if(startDateTime != null) {
      param['startDateTime'] = startDateTime;
    }
    // EndDateTime	DateTime	否	结束时间
    if(endDateTime != null) {
      param['endDateTime'] = endDateTime;
    }
    // StationNos	string[]	否	电站号
    if(stationNos != null) {
      param['stationNos'] = stationNos;
    }
    // ErcVersions	byte[]	否	告警版本号
    if(ercVersions != null) {
      param['ercVersions'] = ercVersions;
    }
    // EventFlags	ushort[]	否	告警标识，前置条件：ErcVersions
    if(eventFlags != null) {
      param['eventFlags'] = eventFlags;
    }
    // DeviceTerminalType	DeviceTerminalTypeEnum	否	设备类型
    if(deviceTerminalType != null) {
      param['deviceTerminalType'] = deviceTerminalType;
    }
    // DeviceTerminalHardware	string	否	设备版本
    if(deviceTerminalHardware != null) {
      param['deviceTerminalHardware'] = deviceTerminalHardware;
    }
    // TerminalAddress	string	否	终端地址
    if(terminalAddress != null) {
      param['terminalAddress'] = terminalAddress;
    }
    // LimitSize	int	否	查询条数，默认20
    if(limitSize != null) {
      param['limitSize'] = limitSize;
    }
    // IsIncludedDetail	bool	否	是否包含详情数据，默认false
    if(isIncludedDetail != null) {
      param['isIncludedDetail'] = isIncludedDetail;
    }
        
    // 获取帐号信息地址
    final path = liveDataHost + '/v1/TerminalAlarmEvent';

    HttpHelper.httpGET(path, param, (map,_){
    
      var resp = TerminalAlarmEventResp.fromJson(map);
      if(onSucc != null) onSucc(resp.data.rows);
        
    }, onFail);
  }
  

  static void getTurbineWaterAndPowerAndState({
    @required String stationNo,
    String searchAnchorDateTime,
    String searchDirection,
    String startDateTime,
    String endDateTime,
    String minuteInterval,
    String terminalAddress,
    String limitSize,
    TurbineCallback onSucc,HttpFailCallback onFail}) async {

    var param = Map<String, dynamic>();

    // searchAnchorDateTime	string	否	时间锚点
    if(searchAnchorDateTime != null) {
      param['searchAnchorDateTime'] = searchAnchorDateTime;
    }
    // SearchDirection	string	否	Backward(上一页)或Forward(下一页) 依赖于时间锚点，默认Forward
    if(searchDirection != null) {
      param['searchDirection'] = searchDirection;
    }
    // StartDateTime	DateTime	否	起始时间
    if(startDateTime != null) {
      param['startDateTime'] = startDateTime;
    }
    // EndDateTime	DateTime	否	结束时间
    if(endDateTime != null) {
      param['endDateTime'] = endDateTime;
    }
    // TerminalAddress	string	否	终端地址
    if(terminalAddress != null) {
      param['terminalAddress'] = terminalAddress;
    }
    // LimitSize	int	否	查询条数，默认20
    if(limitSize != null) {
      param['limitSize'] = limitSize;
    }

    // 事件间隔
    if(minuteInterval != null) {
      param['minuteInterval'] = minuteInterval;
    }

    final path = liveDataHost + '/v1/TurbineWaterAndPowerAndState/'+'$stationNo';

    HttpHelper.httpGET(path,param, (map,_){
      
      var resp = TurbineResp.fromJson(map);
      if(onSucc != null) onSucc(resp.data.turbine);

    },onFail);
  }
     

  //获取平台广告牌信息
  static void getAdvertisingBoard({BannerListCallback onSucc,HttpFailCallback onFail}) async {

    final path = baseHost + '/v1/SystemExtendInfo/AdvertisingBoard';

    HttpHelper.httpGET(path,null, (map,_){
      
      var resp = BannerResp.fromJson(map);
      if(onSucc != null) onSucc(resp.data.banners);

    },onFail);
  }
}
  



