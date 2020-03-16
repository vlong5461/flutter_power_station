import 'package:flutter/material.dart';
import 'package:hsa_app/components/page_indicator/dots_decorator.dart';
import 'package:hsa_app/components/page_indicator/dots_indicator.dart';
import 'package:hsa_app/components/public_tool.dart';
import 'package:hsa_app/config/app_theme.dart';
import 'package:hsa_app/model/station_info.dart';
import 'package:hsa_app/page/history/history_page.dart';
import 'package:hsa_app/page/runtime/runtime_page.dart';
import 'package:hsa_app/service/umeng_analytics.dart';
import 'package:hsa_app/theme/theme_gradient_background.dart';

class RuntimeTabbarPage extends StatefulWidget {

  final List<Devices> devices;
  final int selectIndex;

  const RuntimeTabbarPage({Key key, this.devices, this.selectIndex}) : super(key: key);
  @override
  _RuntimeTabbarPageState createState() => _RuntimeTabbarPageState();
}

class _RuntimeTabbarPageState extends State<RuntimeTabbarPage> {

  int currentIndex;
  Devices currentDevice;
  int pageLength;
  String title;
  PageController pageController;
  String badgeName;

  @override
  void initState() {

    currentIndex = widget?.selectIndex ?? 0;
    currentDevice = widget?.devices[currentIndex];
    pageLength = widget?.devices?.length ?? 0;
    title = currentDevice?.name ?? '';
    pageController = PageController(initialPage: currentIndex);
    badgeName = (currentIndex + 1).toString() + '#';
    UMengAnalyticsService.enterPage('机组实时');
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    UMengAnalyticsService.exitPage('机组实时');
    super.dispose();
  }

   void onTapPushToHistoryPage(Devices devices) async {
    pushToPage(context, HistoryPage(title: '历史分析',address: devices.address));
  }
  

  @override
  Widget build(BuildContext context) {
    final isOnline = currentDevice?.status == 'online' ? true : false;
    return ThemeGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Text(title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: AppTheme().navigationAppBarFontSize)),
          actions: <Widget>[
            GestureDetector(
                onTap: () => onTapPushToHistoryPage(currentDevice),
                child: Center(child: Text('历史分析',style: TextStyle(color: Colors.white, fontSize: 16)))),
            SizedBox(width: 20),
          ],
        ),
        body: Stack(
          children: <Widget>[
            
            PageView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              controller: pageController,
              itemCount: widget.devices.length,
              itemBuilder: (BuildContext context, int index) => 
              RuntimePage(
                title: currentDevice.name,
                address:currentDevice.address,
                alias:(index+1).toString() + '#',
                isOnline:isOnline,
              ),
              onPageChanged: (int index) {
                currentIndex = index;
                currentDevice = widget?.devices[currentIndex];
                badgeName = (currentIndex + 1).toString() + '#';
                setState(() {
                  title = currentDevice.name;
                });
              },
            ),

            Positioned(
              top: -6.0,left: 0.0,right: 0.0,
              child: Container(
                child: Center(
                child: DotsIndicator(
                dotsCount: pageLength > 5 ? 5 : pageLength,position: (currentIndex % 5).toDouble(),
                decorator: DotsDecorator(
                size: const Size(6.0, 6.0),
                activeSize: const Size(15.0, 6.0),
                activeColor: Colors.white38,
                color: Colors.white38,
                activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0))),
                ),
                ),
              ),
            ),
          ],
        )));
  }
}