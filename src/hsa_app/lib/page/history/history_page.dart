import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cupertino_date_picker/flutter_cupertino_date_picker.dart';
import 'package:hsa_app/api/api.dart';
import 'package:hsa_app/components/empty_page.dart';
import 'package:hsa_app/components/segment_control.dart';
import 'package:hsa_app/components/spinkit_indicator.dart';
import 'package:hsa_app/event/app_event.dart';
import 'package:hsa_app/event/event_bird.dart';
import 'package:hsa_app/model/event_types.dart';
import 'package:hsa_app/model/history_event.dart';
import 'package:hsa_app/model/history_point.dart';
import 'package:hsa_app/model/runtime_adapter.dart';
import 'package:hsa_app/page/history/history_event_tile.dart';
import 'package:hsa_app/page/history/history_pop_dialog.dart';
import 'package:hsa_app/theme/theme_gradient_background.dart';
import 'package:native_color/native_color.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HistoryPage extends StatefulWidget {
  final String title;
  final String address;

  const HistoryPage({Key key, this.title, this.address}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEvent> showEvents = List<HistoryEvent>();
  HistoryPointResp historyPointResp = HistoryPointResp();
  int segmentIndex = 0;

  String startDateTime;
  String endDateTime;

  // 是否空视图
  bool isEmpty = false;
  // 是否首次数据加载完毕
  bool isLoadFinsh = false;

  List<EventTypes> evnetTypes = List<EventTypes>();

  // 获取事件类型
  void reqeustGetEventTypes() {
    API.eventTypes((types) {
      this.evnetTypes = types;
    }, (msg) {});
  }

  @override
  void initState() {
    super.initState();
    reqeustGetEventTypes();
    requestTodayData();
    addObserverEventFilterChoose();
  }

  @override
  void dispose() {
    EventBird().off(AppEvent.eventFilterChoose);
    super.dispose();
  }

  void addObserverEventFilterChoose() {
    EventBird().on(AppEvent.eventFilterChoose, (flag) {
      String ercFlag = flag;
      if (ercFlag == '')
        return;
      else if (ercFlag == '全部') {
        debugPrint(ercFlag);
      } else {
        debugPrint(ercFlag);
      }
    });
  }

  // 获取当天数据
  void requestTodayData() {
    this.startDateTime = formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd]);
    this.endDateTime = formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd]);
    requestData();
  }

  // 获取数据
  void requestData() {
    this.isEmpty = false;
    this.isLoadFinsh = false;

    final address = widget.address ?? '';

    API.eventList(address, startDateTime, endDateTime, (events) {
      isLoadFinsh = true;

      if (events.length == 0) {
        this.isEmpty = true;
      }
      setState(() {
        this.showEvents = events;
      });
    }, (msg) {
      debugPrint(msg);
    });

    API.historyPowerAndWater(address, startDateTime, endDateTime,
        (historyResp) {
      setState(() {
        this.historyPointResp = historyResp;
      });
    }, (msg) {
      debugPrint(msg);
    });
  }

  void onTapFilterButton(BuildContext context) {
    if (this.evnetTypes.length == 0) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => HistoryEventDialogWidget(eventTypes: this.evnetTypes));
  }

  // 点击了日.周.月.年
  void onTapToggleButton() {
    final now = DateTime.now();

    if (segmentIndex == 0) {
      this.startDateTime = formatDate(now, [yyyy, '-', mm, '-', dd]);
      this.endDateTime = formatDate(now, [yyyy, '-', mm, '-', dd]);
    } else if (segmentIndex == 1) {
      final year = now.year;
      final month = now.month;
      final day = now.day;
      final end =
          formatDate(DateTime(year, month, day), [yyyy, '-', mm, '-', dd]);
      final start = formatDate(
          DateTime(year, month, day).subtract(Duration(days: 6)),
          [yyyy, '-', mm, '-', dd]);
      this.startDateTime = start;
      this.endDateTime = end;
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
      this.startDateTime = start;
      this.endDateTime = end;
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
      this.startDateTime = start;
      this.endDateTime = end;
    }
    requestData();
  }

  void showPickerPopWindow() {
    final max = DateTime.now();
    final min = max.subtract(Duration(days: 365 * 2));

    // 选择 日
    if (segmentIndex == 0) {
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
                color: Colors.white, fontFamily: 'ArialNarrow', fontSize: 22),
          ), onConfirm: (selectDate, _) {
        setState(() {
          this.startDateTime = formatDate(selectDate, [yyyy, '-', mm, '-', dd]);
          this.endDateTime = formatDate(selectDate, [yyyy, '-', mm, '-', dd]);
        });
      });
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
                color: Colors.white, fontFamily: 'ArialNarrow', fontSize: 22),
          ), onConfirm: (selectDate, index) {
        final year = selectDate.year;
        final month = selectDate.month;
        final day = selectDate.day;
        final end =
            formatDate(DateTime(year, month, day), [yyyy, '-', mm, '-', dd]);
        final start = formatDate(
            DateTime(year, month, day).subtract(Duration(days: 6)),
            [yyyy, '-', mm, '-', dd]);
        setState(() {
          this.startDateTime = start;
          this.endDateTime = end;
        });
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
                color: Colors.white, fontFamily: 'ArialNarrow', fontSize: 22),
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
        setState(() {
          this.startDateTime = start;
          this.endDateTime = end;
        });
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
                color: Colors.white, fontFamily: 'ArialNarrow', fontSize: 22),
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
        setState(() {
          this.startDateTime = start;
          this.endDateTime = end;
        });
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
          title: Text('历史曲线',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 18)),
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

  Widget calendarBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      height: 36,
      child: Stack(children: [
        Container(
          child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                  height: 22,
                  width: 22,
                  child:
                      Image.asset('images/history/History_calendar_btn.png'))),
        ),
        Positioned(
          right: 32,
          top: 8,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$startDateTime ～ $endDateTime',
              style: TextStyle(
                  color: Colors.white, fontFamily: 'ArialNarrow', fontSize: 16),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => showPickerPopWindow(),
        ),
      ]),
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
          calendarBar(),
          Container(
            height: 264,
            child: SfCartesianChart(
                plotAreaBorderWidth: 2,
                plotAreaBorderColor: Colors.transparent,
                zoomPanBehavior: ZoomPanBehavior(
                  enablePinching: true,
                  enablePanning: true,
                  zoomMode: ZoomMode.x,
                ),
                primaryXAxis: NumericAxis(
                  labelStyle: ChartTextStyle(color: Colors.white),
                  majorGridLines: MajorGridLines(
                    width: 0,
                  ),
                  minorGridLines: MinorGridLines(
                    width: 0,
                  ),
                  majorTickLines: MajorTickLines(
                    width: 0,
                  ),
                  minorTickLines: MinorTickLines(
                    width: 0,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  axisLine: AxisLine(color: Colors.transparent),
                  minimum: 300,
                  labelStyle: ChartTextStyle(color: Colors.white),
                  majorTickLines: MajorTickLines(width: 0),
                  majorGridLines: MajorGridLines(
                    width: 0.5,
                    color: Colors.white60,
                  ),
                  minorGridLines: MinorGridLines(width: 0),
                  minorTickLines: MinorTickLines(width: 0),
                ),
                series: getRandomData()),
          ),
        ],
      ),
    );
  }

  static List<ChartSeries> getRandomData() {
    final chartData1 = <ActivePowerPoint>[
      ActivePowerPoint(0, 240),
      ActivePowerPoint(10, 236),
      ActivePowerPoint(20, 233),
      ActivePowerPoint(30, 232),
      ActivePowerPoint(40, 230),
      ActivePowerPoint(50, 232),
      ActivePowerPoint(60, 234),
      ActivePowerPoint(70, 236),
      ActivePowerPoint(80, 242),
      ActivePowerPoint(90, 238),
      ActivePowerPoint(100, 236),
      ActivePowerPoint(110, 234),
      ActivePowerPoint(120, 230),
      ActivePowerPoint(130, 238),
      ActivePowerPoint(140, 242),
      ActivePowerPoint(150, 245),
      ActivePowerPoint(160, 241),
      ActivePowerPoint(170, 240),
      ActivePowerPoint(180, 238),
      ActivePowerPoint(190, 236),
      ActivePowerPoint(200, 235),
    ];

    final chartData2 = <ActivePowerPoint>[
      ActivePowerPoint(0, 120),
      ActivePowerPoint(10, 118),
      ActivePowerPoint(20, 116),
      ActivePowerPoint(30, 112),
      ActivePowerPoint(40, 116),
      ActivePowerPoint(50, 122),
      ActivePowerPoint(60, 128),
      ActivePowerPoint(70, 124),
      ActivePowerPoint(80, 122),
      ActivePowerPoint(90, 121),
      ActivePowerPoint(100, 134),
      ActivePowerPoint(110, 132),
      ActivePowerPoint(120, 128),
      ActivePowerPoint(130, 119),
      ActivePowerPoint(140, 113),
      ActivePowerPoint(150, 112),
      ActivePowerPoint(160, 110),
      ActivePowerPoint(170, 118),
      ActivePowerPoint(180, 120),
      ActivePowerPoint(190, 125),
      ActivePowerPoint(200, 119),
    ];

    final chartData3 = <ActivePowerPoint>[
      ActivePowerPoint(0, 210),
      ActivePowerPoint(10, 210),
      ActivePowerPoint(20, 210),
      ActivePowerPoint(30, 210),
      ActivePowerPoint(40, 210),
      ActivePowerPoint(50, 210),
      ActivePowerPoint(60, 210),
      ActivePowerPoint(70, 210),
      ActivePowerPoint(80, 210),
      ActivePowerPoint(90, 210),
      ActivePowerPoint(100, 210),
      ActivePowerPoint(110, 210),
      ActivePowerPoint(120, 210),
      ActivePowerPoint(130, 210),
      ActivePowerPoint(140, 210),
      ActivePowerPoint(150, 210),
      ActivePowerPoint(160, 210),
      ActivePowerPoint(170, 210),
      ActivePowerPoint(180, 210),
      ActivePowerPoint(190, 210),
      ActivePowerPoint(200, 210),
    ];

    final chartData4 = <ActivePowerPoint>[
      ActivePowerPoint(0, 180),
      ActivePowerPoint(10, 180),
      ActivePowerPoint(20, 180),
      ActivePowerPoint(30, 180),
      ActivePowerPoint(40, 180),
      ActivePowerPoint(50, 180),
      ActivePowerPoint(60, 180),
      ActivePowerPoint(70, 180),
      ActivePowerPoint(80, 180),
      ActivePowerPoint(90, 180),
      ActivePowerPoint(100, 180),
      ActivePowerPoint(110, 180),
      ActivePowerPoint(120, 180),
      ActivePowerPoint(130, 180),
      ActivePowerPoint(140, 180),
      ActivePowerPoint(150, 180),
      ActivePowerPoint(160, 180),
      ActivePowerPoint(170, 180),
      ActivePowerPoint(180, 180),
      ActivePowerPoint(190, 180),
      ActivePowerPoint(200, 180),
    ];

    return <ChartSeries>[
      SplineSeries<ActivePowerPoint, num>(
        animationDuration: 5000,
        dataSource: chartData1,
        splineType: SplineType.natural,
        color: HexColor('ee2e3b'),
        xValueMapper: (ActivePowerPoint sales, _) => sales.minute,
        yValueMapper: (ActivePowerPoint sales, _) => sales.value,
      ),
      SplineAreaSeries<ActivePowerPoint, num>(
        animationDuration: 5000,
        dataSource: chartData2,
        borderDrawMode: BorderDrawMode.excludeBottom,
        gradient: LinearGradient(colors: [
          HexColor('0003a9f4'),
          HexColor('9903a9f4'),
        ]),
        xValueMapper: (ActivePowerPoint sales, _) => sales.minute,
        yValueMapper: (ActivePowerPoint sales, _) => sales.value,
      ),
      LineSeries<ActivePowerPoint, num>(
        animationDuration: 2500,
        dataSource: chartData3,
        dashArray: <double>[10, 10],
        color: Colors.white,
        width: 0.5,
        xValueMapper: (ActivePowerPoint sales, _) => sales.minute,
        yValueMapper: (ActivePowerPoint sales, _) => sales.value,
      ),
      LineSeries<ActivePowerPoint, num>(
        animationDuration: 2500,
        dataSource: chartData4,
        dashArray: <double>[10, 10],
        color: Colors.white,
        width: 0.5,
        xValueMapper: (ActivePowerPoint sales, _) => sales.minute,
        yValueMapper: (ActivePowerPoint sales, _) => sales.value,
      ),
    ];
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
          segmentIndex = index;
          onTapToggleButton();
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
            child: Text('  系统日志',
                style: TextStyle(fontSize: 16, color: Colors.white))));
  }

  Widget eventListView(List<HistoryEvent> events) {
    if (isLoadFinsh == false)
      return Expanded(child: SpinkitIndicator(title: '正在加载', subTitle: '请稍后'));
    if (isEmpty == true)
      return Expanded(child: EmptyPage(title: '暂无数据', subTitle: ''));
    return Expanded(
        child: ListView.builder(
            itemBuilder: (ctx, index) {
              final event = events[index];
              final left = 'ERC${event.eRCFlag}--${event.eRCTitle}';
              var right = event.freezeTime.replaceAll('T', ' ');
              right = right.split(' ').last ?? '';
              return HistoryEventTile(event: EventTileData(left, right));
            },
            itemCount: events.length ?? 0));
  }
}

class ActivePowerPoint {
  ActivePowerPoint(this.minute, this.value);
  final num minute;
  final int value;
}
