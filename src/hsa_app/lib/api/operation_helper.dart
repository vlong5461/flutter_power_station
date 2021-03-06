import 'package:hsa_app/model/model/all_model.dart';

// 权限获取逻辑处理封装类
class OperationHelper {

  OperationHelper._();
  static OperationHelper _instance;
  static OperationHelper getInstance() {
    if (_instance == null) {
      _instance = OperationHelper._();
      _instance.operation = Operation();
    }
    return _instance;
  }
  Operation operation;

  // 是否有某个功能的权限码权限
  bool _havePermission(String input) {
    if(operation.accountAllRolesContainedFuncCodes == null) return false;
    for(final code in operation.accountAllRolesContainedFuncCodes) {
      if(code.compareTo(input) == 0) return true;
    }
    return false;
  }

  // 是否有某个功能的权限码权限(带电站号)
  bool _havePermissionWithStation(String stationNo,String input) {
     if(operation.accountAllRolesContainedFuncCodes == null) return false;
     final dict = operation.hyStationContainedFuncCodeDictionary;
     if(dict != null) {
       for (String key in dict.keys) {
         final isHit = key.compareTo(stationNo) == 0; 
         if(isHit == true) {
            Map<String,dynamic> body = dict[stationNo];
            for(String code in body.keys) {
              if(code.compareTo(input) == 0) {
                return body[code];
              }
            }
         }
       }
     }
     for(final code in operation.accountAllRolesContainedFuncCodes) {
       if(code.compareTo(input) == 0) return true;
     }
     return false;
  }

  // ---- 工程模式 ---- 
  // UI入口 拥有进入工程模式 UI 的权限 
  bool get haveEngineeringModeUIAccess => haveRemoteUpgrade || haveOpenEquipmentControl || haveModifyPowerWithEditBox;

  // 拥有远程升级的权限
  bool get haveRemoteUpgrade {
    bool getInfo  = _havePermission('CoreData-GetDeviceUpgradeFileInfo');
    bool pushFile = _havePermission('CoreData-PushDeviceUpgradeFileToTerminal');
    return getInfo && pushFile;
  }
  // 拥有开启设备控制的权限
  bool get haveOpenEquipmentControl => _havePermission('MoblieApp-OpenEquipmentControl');
  // 拥有开启调功输入框的权限
  bool get haveModifyPowerWithEditBox => _havePermission('MoblieApp-ModifyPowerWithEditBox');

  // ---- 历史分析 ----
  // UI入口 拥有进入历史分析页 UI 的权限 
  bool haveHistoricalAnalysiseUIAccess(String stationNo) => haveWaterAndPowerGraph(stationNo) || haveElectricQuantityGraph(stationNo);

  // 拥有查看水位和电能图表的权限
  bool haveWaterAndPowerGraph(String stationNo) => _havePermissionWithStation(stationNo,'RuningData-GetTurbineWaterAndPowerAndState');
  // 拥有查看电量图表的权限
  bool haveElectricQuantityGraph(String stationNo) => _havePermissionWithStation(stationNo,'RuningData-GetTurbineStatisticalPower');

  // 全局权限:
  bool get haveWaterAndPowerHomePage => _havePermission('RuningData-GetTurbineWaterAndPowerAndState');

  // ---- 事件告警 ----
  // 拥有查看事件告警的权限
  bool haveGetTerminalAlarmEvent(String stationNo) => _havePermissionWithStation(stationNo,'RuningData-GetTerminalAlarmEvent');

  // ---- 操作面板 ---- 
  // 拥有开关水轮机的权限
  bool haveWaterTurbinePowerOnOff(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F1');
  // 拥有切换控制方案的权限
  bool haveSwitchControlType(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F13');
  // 拥有调节有功功率的权限
  bool haveModifyActivePower(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F3');
  // 拥有调节功率因数的权限
  bool haveModifyPowerFactor(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F4');
  // 拥有开关主阀的权限
  bool haveMainvalveControl(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F2');
  // 拥有开关旁通阀的权限
  bool haveSideValveControl(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F16');
  // 拥有清污机的权限
  bool haveRubishCleanerControl(String stationNo) => _havePermissionWithStation(stationNo,'DeviceCmd-AFN05_F21');

}