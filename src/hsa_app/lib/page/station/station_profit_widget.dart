import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hsa_app/config/app_config.dart';
import 'package:hsa_app/config/app_theme.dart';
import 'package:hsa_app/event/app_event.dart';
import 'package:hsa_app/event/event_bird.dart';
import 'package:supernova_flutter_ui_toolkit/keyframes.dart';

class StationProfitWidget extends StatefulWidget {

  final List<num> profit;

  const StationProfitWidget({Key key, this.profit}) : super(key: key);
  
  @override
  _StationProfitWidgetState createState() => _StationProfitWidgetState();
}

class _StationProfitWidgetState extends State<StationProfitWidget> with TickerProviderStateMixin{
  
  AnimationController controller;
  Animation<double> animation;
  

  // 防止内存泄漏 当等于0时才触发动画
  var canPlayAnimationOnZero = 1;

  void initAnimateController() {

    final oldProfit = widget?.profit[0] ?? 0.0;
    final profit    = widget?.profit[1] ?? 0.0;
    
    if(canPlayAnimationOnZero <= 0  && mounted ) {

      controller?.dispose();
      controller = AnimationController(duration: Duration(seconds:AppConfig.getInstance().stationPageAnimationDuration), vsync: this);
      //CurvedAnimation curvedAnimation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
      //animation = Tween<double>(begin: oldProfit, end: profit).animate(curvedAnimation);
      //3等分间隔

      num p1 = oldProfit+(profit-oldProfit)*(Random().nextInt(50)+75)/300;
      num p2 = oldProfit+(profit-oldProfit)*(Random().nextInt(50)+175)/300;

      animation = Interpolation(
        keyframes: [
          Keyframe<double>(fraction: 0, value: oldProfit),
          Keyframe<double>(fraction: 1/12, value: p1),
          Keyframe<double>(fraction: 4/12, value: p1),
          Keyframe<double>(fraction: 5/12, value: p2),
          Keyframe<double>(fraction: 8/12, value: p2),
          Keyframe<double>(fraction: 9/12, value: profit),
          Keyframe<double>(fraction: 1, value: profit),]
          
      ).animate(controller);
      controller.forward();
      canPlayAnimationOnZero = 0 ;
      //Random().nextInt(50);
    }
    canPlayAnimationOnZero --;
  }

  @override
  void dispose() {
    eventBird?.off(AppEvent.onRefreshProfit);
    controller?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initAnimateController();
    eventBird?.on(AppEvent.onRefreshProfit, (_){
      initAnimateController();
    });
  }

  Widget richTextMoneyWidget() {

    final current = animation?.value?.toStringAsFixed(2) ?? '0.00';

    if(animation == null || controller == null) {
      return RichText(text:TextSpan(children: 
          [
            TextSpan(text:current,style: TextStyle(color: Colors.white,fontFamily: AppTheme().numberFontName,fontSize: 50)),
            TextSpan(text:' 元',style: TextStyle(color: Colors.white,fontSize: 13)),
          ]
        ));
    }
    else {
      return AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget child) => RichText( text: TextSpan(children: 
            [
              TextSpan(text:animation.value.toStringAsFixed(2),style: TextStyle(color: Colors.white,fontFamily: AppTheme().numberFontName,fontSize: 50)),
              TextSpan(text:' 元',style: TextStyle(color: Colors.white,fontSize: 13)),
            ]
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: richTextMoneyWidget()
    );
  }
}