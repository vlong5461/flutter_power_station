import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:hsa_app/api/apis/api_history.dart';
import 'package:hsa_app/components/empty_page.dart';
import 'package:hsa_app/components/segment_control.dart';
import 'package:hsa_app/components/spinkit_indicator.dart';
import 'package:hsa_app/config/app_theme.dart';
import 'package:hsa_app/api/api.dart';
import 'package:hsa_app/model/model/all_model.dart';
import 'package:hsa_app/event/app_event.dart';
import 'package:hsa_app/event/event_bird.dart';
import 'package:hsa_app/model/model/runtime_adapter.dart';
import 'package:hsa_app/page/history/history_calendar_bar.dart';
import 'package:hsa_app/page/history/history_chart_value.dart';
import 'package:hsa_app/page/history/history_event_tile.dart';
import 'package:hsa_app/page/history/history_pop_dialog.dart';
import 'package:hsa_app/theme/theme_gradient_background.dart';
import 'package:native_color/native_color.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {

  final StationInfo stationInfo;        // 电站信息
  final bool isSingleDevice;            // 是否是单台设备
  final WaterTurbine singleWaterTurbine;  // 如果是单台设备,从这里取数据

  const HistoryPage({Key key,@required this.stationInfo,@required  this.isSingleDevice,this.singleWaterTurbine}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  List<TerminalAlarmEvent> showEvents = List<TerminalAlarmEvent>();
  List<WaterLevel> waterLevelList = List<WaterLevel>();
  List<Turbine> turbinelList = List<Turbine>();

  // 0日  1周  2月 3年
  int segmentIndex = 0; 

  int get minuteInterval  {
    switch (segmentIndex) {
      case 0:return  10;break; // 日 = 10  10分钟
      case 1:return  60;break; // 周 = 60  1小时
      case 2:return 240;break; // 月 = 240 4小时
      case 3:return 720;break; // 年 = 720 1天
      default:return 10;
    }
  }
  // 时间
  String currentStartDateTime;
  String currentEndDateTime;
  // 当前事件标志
  String currentERCFlag = '-1';
  // 是否空视图
  bool isEventEmpty = false;
  // 事件列表是否首次数据加载完毕
  bool isEventLoadFinsh = false;
  // 图表是否首次数据加载完毕
  bool isChartLoading = true;
  // ERC列表
  List<ERCFlagType> evnetTypesList = List<ERCFlagType>();
  // 曲线点
  List<HistoryChartValue> points = List<HistoryChartValue>();
  
  List<StatisticalPower> statisticalPowerList;
  //柱状图初始
  List<ChartSampleData> chartData = List<ChartSampleData>();

  //告警水位
  num waterMax = 0;


  // 是否是单台设备
  bool isSingleDevice = false;

  // 获取日期格式化
  DateFormat getDateFormat() {
    if(segmentIndex == 0) return DateFormat.Hm();
    if(segmentIndex == 1) return DateFormat.Md();
    if(segmentIndex == 2) return DateFormat.Md();
    if(segmentIndex == 3) return DateFormat.Md();
    return DateFormat.Md();
  }

  // 获取事件类型
  void reqeustGetEventTypes() {
    API.getErcFlagTypeList(type: '0',onSucc: (types){this.evnetTypesList = types;},onFail: (msg){});
  }

  @override
  void initState() {
    super.initState();
    this.isSingleDevice = widget?.isSingleDevice ?? false;
    reqeustGetEventTypes();
    requestTodayData();
    addObserverEventFilterChoose();
  }

  @override
  void dispose() {
    eventBird?.off(AppEvent.eventFilterChoose);
    super.dispose();
  }

  // 监听事件过滤选择器
  void addObserverEventFilterChoose() {
    eventBird?.on(AppEvent.eventFilterChoose, (flag) {
      if (flag == '') return;
      this.currentERCFlag = flag;
      requestEventListData();
    });
  }

  // 获取当天数据
  void requestTodayData() {

    var now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final day = now.day;
    final end   = formatDate(DateTime(year, month, day), [yyyy, '-', mm, '-', dd]);
    final start = formatDate(DateTime(year, month, day),[yyyy, '-', mm, '-', dd]);
    this.currentStartDateTime = start;
    this.currentEndDateTime = end;

    requestEventListData();
    requestChartHistory();
  }

  // 获取事件列表
  void requestEventListData() {

    this.isEventEmpty = false;
    this.isEventLoadFinsh = false;
    
    // 电站号 
    final stationNos = widget?.stationInfo?.stationNo ?? '';
    // 单台机组地址
    final address = widget?.singleWaterTurbine?.deviceTerminal?.terminalAddress ?? '';

    API.getTerminalAlertList(
      endDateTime : currentStartDateTime   + '  00:00:00',
      startDateTime : currentEndDateTime   + '  23:59:59',
      stationNos : this.isSingleDevice == true ? null :  stationNos ,
      terminalAddress : this.isSingleDevice == true ? address : null,
      ercVersions: '0',
      eventFlags: (this.currentERCFlag.compareTo('-1') == 0) ? null : this.currentERCFlag,
      limitSize : 1000,
      onSucc: (events){

        this.isEventLoadFinsh = true;
        this.isEventEmpty = events.length == 0 ? true : false;
        if(mounted) {
          setState(() {
          this.showEvents = events;
          });
        }

      },onFail: (msg){});

  }

  // 获取曲线列表图
  void requestChartHistory() {

    this.isChartLoading = true;

    final stationNos = widget?.stationInfo?.stationNo ?? '';
    final address = widget?.singleWaterTurbine?.deviceTerminal?.terminalAddress ?? '';

    var endDateTime = currentEndDateTime  + ' 23:59:59';

    final now = DateTime.now();
    final will = DateTime.parse(endDateTime) ?? now;

    if(will.isAfter(now)) {
      endDateTime = formatDate(now, [yyyy, '-', mm, '-', dd,' ',hh, ':', nn, ':', ss]);
    }
    if(segmentIndex == 0 || segmentIndex == 1){
      API.getTurbineWaterAndPowerAndState(
        stationNo : stationNos,
        terminalAddress : this.isSingleDevice == true ? address : null,
        startDateTime:  currentStartDateTime  + ' 00:00:00',
        endDateTime: endDateTime,
        minuteInterval:this.minuteInterval.toString(), 
        onSucc: (turbinelist){
        
          this.isChartLoading = false;

          if(mounted) {

            setState(() {
            
            this.turbinelList = turbinelist;

            this.waterMax = widget?.stationInfo?.reservoirAlarmWaterStage ?? 0.0;

            List<HistoryChartValue> originalPoints = [];

            // 单台机组
            if(this.isSingleDevice) {
              final ratePower = widget?.singleWaterTurbine?.ratedPowerKW ?? 0.0;
              for (final t in turbinelList) {
                var value = HistoryChartValue(DateTime.parse(t.freezeTime));
                value.powerMax = ratePower;
                value.waterMax = waterMax;
                value.power = t.turbineElectricalPower.generatorActivePowerAll;
                value.water = t.turbineRuningStage.measuringWaterLevel;
                originalPoints.add(value);
              }
            }
            // 整个电站
            else {
              var totalPower = 0.0;
              for (final waterTurbine in widget.stationInfo.waterTurbines) {
                totalPower += waterTurbine.ratedPowerKW;
              }
              for (final t in turbinelList) {
                var value = HistoryChartValue(DateTime.parse(t.freezeTime));
                value.powerMax = totalPower;
                value.waterMax = waterMax;
                value.power = t.turbineElectricalPower.generatorActivePowerAll;
                value.water = t.turbineRuningStage.measuringWaterLevel;
                originalPoints.add(value);
              }
            }

            this.points  = originalPoints;
          });

          }
        },onFail:(msg){});
    }
    else if(segmentIndex == 2){
      APIHistory.activePowerPointsMonth(
        stationNos: stationNos, 
        startDate: currentStartDateTime  + ' 00:00:00', 
        endDate: endDateTime,
        terminalAddress: this.isSingleDevice == true ? address : null,
        onSucc: (data){

          this.isChartLoading = false;

          if(mounted) {
            setState(() {
              statisticalPowerList = data;
              chartData.clear();
              changeData();
            });
          }
        }, onFail: (msg){});
    }

    else if(segmentIndex == 3){
      List<int> intList = List<int>();
      intList.add(DateTime.parse(endDateTime).year);
      APIHistory.activePowerPointsYear(
        stationNos: stationNos, 
        years: intList,
        terminalAddress: this.isSingleDevice == true ? address : null,
        onSucc: (data){

          this.isChartLoading = false;
          
          if(mounted) {
            setState(() {
            statisticalPowerList = data;
            chartData.clear();
            changeData();
           });
          }
        }, onFail: (msg){},);
    }
  }

  //处理月数据和年数据
  void changeData(){
    
    //月数据
    if(segmentIndex == 2){
      int day = getDay();
      for(int i = 0 ; i < day ; i++){
        chartData.add(ChartSampleData(x:'${i+1}日',y: 0));
        for(int j = 0 ; j < statisticalPowerList.length ; j++){
          StatisticalPower statisticalPower = statisticalPowerList[j];
          if(i+1 == statisticalPower.day){
            chartData[i] = ChartSampleData(x:'${i+1}日',y: statisticalPower.power);
            break;
          }
        }
      }
    }
    //年数据
    else if(segmentIndex == 3){
      for(int i = 0 ; i < 12 ; i++){
        chartData.add(ChartSampleData(x:'${i+1}月',y: 0));
        for(int j = 0 ; j < statisticalPowerList.length ; j++){
          StatisticalPower statisticalPower = statisticalPowerList[j];
          if(i+1 == statisticalPower.month){
            chartData[i] = ChartSampleData(x:'${i+1}月',y: statisticalPower.power);
            break;
          }
        }
      }
    }
  }


  
  //获取当月总天数
  int getDay(){

    DateTime startDate = DateTime.parse(currentEndDateTime);
    //DateTime获取年和月
    var dateTime = new DateTime.fromMillisecondsSinceEpoch(
        startDate.millisecondsSinceEpoch);
    //通过DateTime获取当月的下个月第一天。
    var dateNextMonthDate = new DateTime(dateTime.year, dateTime.month + 1, 1);
    //下一个月的第一天时间戳减去一天的时间戳就是当前月的最后一天的时间戳
    int nextTimeSamp =
        dateNextMonthDate.millisecondsSinceEpoch - 24 * 60 * 60 * 1000;
    //取得了下一个月1号码时间戳
    var dateTimeeee = new DateTime.fromMillisecondsSinceEpoch(nextTimeSamp);

    return dateTimeeee.day;
  }

  void onTapFilterButton(BuildContext context) {
    if (this.evnetTypesList.length == 0) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => HistoryEventDialogWidget(ercFlag: this.currentERCFlag,eventTypes: this.evnetTypesList));
  }

  // 点击了日.周.月.年
  void onTapToggleButton() {

    final now = DateTime.now();
    // 日
    if (segmentIndex == 0) {
      this.currentStartDateTime   = formatDate(now, [yyyy, '-', mm, '-', dd]);
      this.currentEndDateTime     = formatDate(now, [yyyy, '-', mm, '-', dd]);
    // 周
    } else if (segmentIndex == 1) {
      final year  = now.year;
      final month = now.month;
      final day   = now.day;
      final end   = formatDate(DateTime(year, month, day), [yyyy, '-', mm, '-', dd]);
      final start = formatDate( DateTime(year, month, day).subtract(Duration(days: 6)),[yyyy, '-', mm, '-', dd]);
      this.currentStartDateTime = start;
      this.currentEndDateTime   = end;
    // 月
    } else if (segmentIndex == 2) {
      final year = now.year;
      final month = now.month;
      final start = formatDate(DateTime(year, month), [yyyy, '-', mm, '-', dd]);
      final endDate = DateTime(year, month + 1).subtract(Duration(days: 1));
      var end = '';
      if (now.isBefore(endDate)) {
        end = formatDate(now, [yyyy, '-', mm, '-', dd]);
      } else {
        end = formatDate(endDate, [yyyy, '-', mm, '-', dd]);
      }
      this.currentStartDateTime  = start;
      this.currentEndDateTime    = end;
    // 年
    } else if (segmentIndex == 3) {
      final year = now.year;
      final start = formatDate(DateTime(year), [yyyy, '-', mm, '-', dd]);
      final endDate = DateTime(year + 1).subtract(Duration(days: 1));
      var end = '';
      if (now.isBefore(endDate)) {
        end = formatDate(now, [yyyy, '-', mm, '-', dd]);
      } else {
        end = formatDate(endDate, [yyyy, '-', mm, '-', dd]);
      }
      this.currentStartDateTime = start;
      this.currentEndDateTime = end;
    }
    requestEventListData();
    requestChartHistory();
  }

  void showPickerPopWindow() {
    final max = DateTime.now();
    final min = max.subtract(Duration(days: 365 * 2));

    // 选择 日
    if (segmentIndex == 0) {
      DatePicker.showDatePicker(
        context,
        dateFormat: 'yyyy-MM-dd',
        maxDateTime: max,
        minDateTime: min,
        pickerMode: DateTimePickerMode.date,
        pickerTheme: DateTimePickerTheme(
          cancel: Center(
            child: Text('取消',
                style: TextStyle(color: Colors.white54, fontSize: 18))),
          confirm: Center(
            child: Text('确定',
                style: TextStyle(color: Colors.white, fontSize: 18))),
          backgroundColor: Color.fromRGBO(53, 117, 191, 1),
          itemTextStyle: TextStyle(
              color: Colors.white, fontFamily: AppTheme().numberFontName, fontSize: 22),
        ), onConfirm: (selectDate, _) {
          if(mounted) {
            setState(() {
            this.currentStartDateTime  = formatDate(selectDate, [yyyy, '-', mm, '-', dd]);
            this.currentEndDateTime    = formatDate(selectDate, [yyyy, '-', mm, '-', dd]);
          });
          }
          requestEventListData();
          requestChartHistory();
        }
      );
    }
    // 选择 周
    else if (segmentIndex == 1) {
      DatePicker.showDatePicker(context,
          dateFormat: 'yyyy-MM-dd',
          maxDateTime: max,
          minDateTime: min,
          pickerMode: DateTimePickerMode.date,
          pickerTheme: DateTimePickerTheme(
            cancel: Center(
                child: Text('取消',
                    style: TextStyle(color: Colors.white54, fontSize: 18))),
            confirm: Center(
                child: Text('确定',
                    style: TextStyle(color: Colors.white, fontSize: 18))),
            backgroundColor: Color.fromRGBO(53, 117, 191, 1),
            itemTextStyle: TextStyle(
                color: Colors.white, fontFamily: AppTheme().numberFontName, fontSize: 22),
          ), onConfirm: (selectDate, index) {
        final year = selectDate.year;
        final month = selectDate.month;
        final day = selectDate.day;
        final end = formatDate(DateTime(year, month, day), [yyyy, '-', mm, '-', dd]);
        final start = formatDate( DateTime(year, month, day).subtract(Duration(days: 6)),[yyyy, '-', mm, '-', dd]);
        if(mounted) {
          setState(() {
          this.currentStartDateTime = start;
          this.currentEndDateTime   = end;
          });
        }
        requestEventListData();
        requestChartHistory();
      });
    }
    // 按月
    else if (segmentIndex == 2) {
      DatePicker.showDatePicker(context,
          dateFormat: 'yyyy-MM',
          maxDateTime: max,
          minDateTime: min,
          pickerMode: DateTimePickerMode.date,
          pickerTheme: DateTimePickerTheme(
            cancel: Center(
                child: Text('取消',
                    style: TextStyle(color: Colors.white54, fontSize: 18))),
            confirm: Center(
                child: Text('确定',
                    style: TextStyle(color: Colors.white, fontSize: 18))),
            backgroundColor: Color.fromRGBO(53, 117, 191, 1),
            itemTextStyle: TextStyle(
                color: Colors.white, fontFamily: AppTheme().numberFontName, fontSize: 22),
          ), onConfirm: (selectDate, index) {
        final year = selectDate.year;
        final month = selectDate.month;
        final start =
            formatDate(DateTime(year, month), [yyyy, '-', mm, '-', dd]);
        final endDate = DateTime(year, month + 1).subtract(Duration(days: 1));
        var end = '';
        if (max.isBefore(endDate)) {
          end = formatDate(max, [yyyy, '-', mm, '-', dd]);
        } else {
          end = formatDate(endDate, [yyyy, '-', mm, '-', dd]);
        }
        if(mounted) {
          setState(() {
            this.currentStartDateTime = start;
            this.currentEndDateTime   = end;
          });
        }
        requestEventListData();
        requestChartHistory();
      });
    } else if (segmentIndex == 3) {
      DatePicker.showDatePicker(context,
          dateFormat: 'yyyy',
          maxDateTime: max,
          minDateTime: min,
          pickerMode: DateTimePickerMode.date,
          pickerTheme: DateTimePickerTheme(
            cancel: Center(
                child: Text('取消',
                    style: TextStyle(color: Colors.white54, fontSize: 18))),
            confirm: Center(
                child: Text('确定',
                    style: TextStyle(color: Colors.white, fontSize: 18))),
            backgroundColor: Color.fromRGBO(53, 117, 191, 1),
            itemTextStyle: TextStyle(
                color: Colors.white, fontFamily: AppTheme().numberFontName, fontSize: 22),
          ), onConfirm: (selectDate, index) {
        final year = selectDate.year;
        final start = formatDate(DateTime(year), [yyyy, '-', mm, '-', dd]);
        final endDate = DateTime(year + 1).subtract(Duration(days: 1));
        var end = '';
        if (max.isBefore(endDate)) {
          end = formatDate(max, [yyyy, '-', mm, '-', dd]);
        } else {
          end = formatDate(endDate, [yyyy, '-', mm, '-', dd]);
        }
        if(mounted) {
          setState(() {
            this.currentStartDateTime = start;
            this.currentEndDateTime   = end;
          });
        }
        requestEventListData();
        requestChartHistory();
      });
    }
  }

  Widget filterButton() {
    return GestureDetector(
      onTap: () => onTapFilterButton(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: 22,
          width: 22,
          child: Image.asset('images/history/History_selt_btn.png'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('历史分析',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: AppTheme().navigationAppBarFontSize)),
          actions: <Widget>[
            filterButton(),
          ],
        ),
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              segmentWidget(),
              chartGraphWidget(),
              eventListViewHeader(),
              divLine(),
              eventListView(showEvents),
            ],
          ),
        ),
      ),
    );
  }

  Widget chartGraphWidget() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: HexColor('1affffff'),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[

          HistoryCalendarBar(
            startDateTime: this.currentStartDateTime,
            endDateTime: this.currentEndDateTime,
            isLoading: this.isChartLoading,
            onChoose: () => showPickerPopWindow(),
          ),

          Container(
            height: 264,
            child: 
            (segmentIndex == 0 || segmentIndex == 1) ?
            SfCartesianChart(
              legend: Legend(
                isVisible:  true,
                overflowMode: LegendItemOverflowMode.wrap,
                position: LegendPosition.bottom,
                textStyle: ChartTextStyle(color: Colors.white,fontSize: 8),
              ),
              plotAreaBorderWidth: 0,
              zoomPanBehavior: ZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
                zoomMode: ZoomMode.x,
              ),
              primaryXAxis: DateTimeAxis(
                axisLine: AxisLine(
                  color: Colors.white60,
                  width: 0.5
                ),
                labelStyle: ChartTextStyle(
                  color: Colors.white,
                  fontFamily:'ArialNarrow',
                ),
                majorGridLines: MajorGridLines(width: 0),
                minorGridLines: MinorGridLines(width: 0),
                majorTickLines: MajorTickLines(width: 0),
                minorTickLines: MinorTickLines(width: 0),
                dateFormat: getDateFormat(),
              ),

              axes:[
                NumericAxis(
                  //maximum: points != null && points.length > 0 ? points[0].powerMax * 1.4 : 0.0,
                  name:'power',
                  opposedPosition: false,
                  axisLine: AxisLine(color: Colors.transparent),
                  labelStyle: ChartTextStyle(color: Colors.white,fontFamily:'ArialNarrow'),
                  majorGridLines: MajorGridLines(width: 0.5,color: Colors.white60),
                  minorGridLines: MinorGridLines(width: 0),
                  majorTickLines: MajorTickLines(width: 0),
                  minorTickLines: MinorTickLines(width: 0),
                ),
                NumericAxis(
                  //maximum: points != null && points.length > 0 ? points[0].waterMax * 1.8 : 0.0,
                  name: 'water',
                  opposedPosition: true,
                  axisLine: AxisLine(color: Colors.transparent),
                  labelStyle: ChartTextStyle(color: Colors.white,fontFamily:'ArialNarrow'),
                  majorGridLines: MajorGridLines(width: 0),
                  minorGridLines: MinorGridLines(width: 0),
                  majorTickLines: MajorTickLines(width: 0),
                  minorTickLines: MinorTickLines(width: 0),
                ),
              ],
              
              series: drawChartSeries(),
              
              trackballBehavior: TrackballBehavior(
                enable: true,
                lineColor: Colors.white60,
                tooltipAlignment:ChartAlignment.near,
                activationMode: ActivationMode.singleTap,
                tooltipDisplayMode:  TrackballDisplayMode.groupAllPoints,
                tooltipSettings: InteractiveTooltip(
                  borderColor:Colors.black54,
                  color: Colors.black54,),
                shouldAlwaysShow: true,
              ),
              
            )  
            : SfCartesianChart(
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: MajorGridLines(width: 0,color: Colors.white60),
                labelStyle: ChartTextStyle(
                  color: Colors.white,
                  fontFamily:'ArialNarrow',
                ),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: ChartTextStyle(
                  color: Colors.white,
                  fontFamily:'ArialNarrow',
                ),
                axisLine: AxisLine(width: 0,color: Colors.white60),
                labelFormat: '{value}',
                majorTickLines: MajorTickLines(size: 0)
              ),
              series: getDefaultColumnSeries(),
              tooltipBehavior: TooltipBehavior(
                enable: true, 
                canShowMarker: false,
                header: '',
                format: 'point.x : point.y kW',
                color: Colors.black,
                opacity:0.54
              ),
              
            )
          ),
        ],
      ),
    );
  }

  //柱状图
  List<ColumnSeries<ChartSampleData, String>> getDefaultColumnSeries() {
    return <ColumnSeries<ChartSampleData, String>>[
      ColumnSeries<ChartSampleData, String>(
        enableTooltip: true,
        dataSource: chartData,
        xValueMapper: (ChartSampleData sales, _) => sales.x,
        yValueMapper: (ChartSampleData sales, _) => sales.y,
        color: HexColor('9903a9f4'),
        yAxisName: 'power',
        width: 1,
        spacing: 0.2,
        dataLabelSettings: DataLabelSettings(
          isVisible: false, textStyle: ChartTextStyle(fontSize: 10,color: Colors.white),
        )
      ),

    ];
  }

  // draw 绘制曲线
  List<ChartSeries> drawChartSeries() {
    List<ChartSeries> list = List<ChartSeries>();
    // 水位告警曲线 = 告警水位水位
    //waterMax > 0 ?? 
    list.add(LineSeries<HistoryChartValue, DateTime>(
      name: '告警水位(m)',
      dataSource: points,
      // dashArray: <double>[10, 10],
      color: HexColor('9903a9f4'),
      width: 0.8,
      xValueMapper: (HistoryChartValue point, _) => point.time,
      yValueMapper: (HistoryChartValue point, _) => point.waterMax,
      yAxisName: 'water'
    ));

    // 有功告警曲线 = 额定 或 额定和
    list.add(LineSeries<HistoryChartValue, DateTime>(
      name: '额定功率(kW)',
      dataSource: points,
      // dashArray: <double>[10, 10],
      color: HexColor('ee2e3b'),
      width: 0.8,
      xValueMapper: (HistoryChartValue point, _) => point.time,
      yValueMapper: (HistoryChartValue point, _) => point.powerMax,
      yAxisName: 'power'
    ));

    // 水位高度
    //waterMax > 0 ?? 
    list.add(SplineAreaSeries<HistoryChartValue, DateTime>(
      name: '水位(m)',
      dataSource: points,
      borderDrawMode: BorderDrawMode.excludeBottom,
      gradient: LinearGradient(
        colors: [HexColor('0003a9f4'),HexColor('9903a9f4')]
      ),
      xValueMapper: (HistoryChartValue point, _) => point.time,
      yValueMapper: (HistoryChartValue point, _) => point.water,
      yAxisName: 'water',
    ));

    // 有功曲线
    list.add(SplineSeries<HistoryChartValue, DateTime>(
      name: '功率(kW)',
      emptyPointSettings: EmptyPointSettings(mode: EmptyPointMode.average),
      dataSource: this.points,
      splineType: SplineType.natural,
      color: HexColor('ee2e3b'),
      xValueMapper: (HistoryChartValue point, _) => point.time,
      yValueMapper: (HistoryChartValue point, _) => point.power,
      yAxisName: 'power',
    ));


    return list;
  }

  Widget divLine() {
    return Container(height: 1, color: Colors.white30);
  }

  Widget segmentWidget() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6),
      height: 40,
      child: SegmentControl(
        radius: 4,
        activeTitleStyle: TextStyle(fontSize: 14),
        normalTitleStyle: TextStyle(fontSize: 14),
        activeTitleColor: Colors.white,
        borderColor: Colors.white54,
        normalTitleColor: Colors.white,
        normalBackgroundColor: Colors.transparent,
        activeBackgroundColor: Color.fromRGBO(72, 114, 222, 1),
        selected: (int index, String valueM) {
          if(mounted) {
            setState(() {
            segmentIndex = index;
            onTapToggleButton();
          });
          }
        },
        tabs: <String>['日', '周', '月', '年'],
      ),
    );
  }

  Widget eventListViewHeader() {
    return Container(
        height: 46,
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('  系统日志',style: TextStyle(fontSize: 16, color: Colors.white))));
  }

  Widget eventListView(List<TerminalAlarmEvent> events) {
    if (this.isEventLoadFinsh == false)
      return Expanded(child: SpinkitIndicator(title: '正在加载', subTitle: '请稍后'));
    if (this.isEventEmpty == true)
      return Expanded(child: EmptyPage(title: '暂无数据', subTitle: ''));
    return Expanded(
      child: ListView.builder(
        itemCount: events.length ?? 0,
        itemBuilder: (ctx, index) {
          final event = events[index];
          final left = 'ERC${event.eventFlag}--${event.eventTitle}';
          var right = event.eventTime;
          return HistoryEventTile(event: EventTileData(left, right));
        },
      )
    );
  }
}

//柱状图入参
class ChartSampleData {
  final dynamic x;
  final num y;
  
  ChartSampleData({this.x,this.y,});
}
