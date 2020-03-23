class DeviceTerminal {
  String terminalId;  //终端Id
  String stationNo;  	//所属电站号
  String terminalAddress;  //终端通讯地址
  String deviceType;  //设备类型识别码
  String deviceVersion;  //设备型号标识
  String deviceName;  
  String intelligentControlScheme;
  String simCardNumber;  //设备绑定的SIM卡号
  bool isOnLine;  //是否连接到通讯服务
  bool isLinkSDU;  //是否允当链路设备
  bool isMaster;
  bool isAllowRemoteControl;
  String controlType;

  DeviceTerminal(
      {this.terminalId,
      this.stationNo,
      this.terminalAddress,
      this.deviceType,
      this.deviceVersion,
      this.deviceName,
      this.intelligentControlScheme,
      this.simCardNumber,
      this.isOnLine,
      this.isLinkSDU,
      this.isMaster,
      this.isAllowRemoteControl,
      this.controlType});

  DeviceTerminal.fromJson(Map<String, dynamic> json) {
    terminalId = json['terminalId'];
    stationNo = json['stationNo'];
    terminalAddress = json['terminalAddress'];
    deviceType = json['deviceType'];
    deviceVersion = json['deviceVersion'];
    deviceName = json['deviceName'];
    intelligentControlScheme = json['intelligentControlScheme'];
    simCardNumber = json['simCardNumber'];
    isOnLine = json['isOnLine'];
    isLinkSDU = json['isLinkSDU'];
    isMaster = json['isMaster'];
    isAllowRemoteControl = json['isAllowRemoteControl'];
    controlType = json['controlType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['terminalId'] = this.terminalId;
    data['stationNo'] = this.stationNo;
    data['terminalAddress'] = this.terminalAddress;
    data['deviceType'] = this.deviceType;
    data['deviceVersion'] = this.deviceVersion;
    data['deviceName'] = this.deviceName;
    data['intelligentControlScheme'] = this.intelligentControlScheme;
    data['simCardNumber'] = this.simCardNumber;
    data['isOnLine'] = this.isOnLine;
    data['isLinkSDU'] = this.isLinkSDU;
    data['isMaster'] = this.isMaster;
    data['isAllowRemoteControl'] = this.isAllowRemoteControl;
    data['controlType'] = this.controlType;
    return data;
  }
}