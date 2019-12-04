import 'package:flutter/material.dart';
import 'package:hsa_app/api/api.dart';
import 'package:hsa_app/model/more_data.dart';
import 'package:hsa_app/page/more/more_page_tile.dart';
import 'package:hsa_app/theme/theme_gradient_background.dart';

class MorePage extends StatefulWidget {

  final String addressId;
  const MorePage({Key key, this.addressId}) : super(key: key);
  
  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
 
  List<MoreItem> moreItems = [];

  @override
  void initState() {
    super.initState();
    requestMoreData();
  }

  // 请求更多数据
  void requestMoreData() {
    
    var address = widget.addressId ?? '';

    // 更多数据
    API.moreData(address,(List<MoreItem> items){
      setState(() {
        this.moreItems = items;
      });
    }, (String msg){
      debugPrint(msg);
    });

  }

  @override
  Widget build(BuildContext context) {
    
    return ThemeGradientBackground(
      child: Scaffold( 
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Text('更多',style: TextStyle(color: Colors.white,fontWeight: FontWeight.normal,fontSize: 20)),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.only(left:14.0,right: 14.0,bottom: 14.0),
              child: ListView.builder(
                itemCount: moreItems?.length ?? 0,
                itemBuilder: (_,index) {
                  var item = moreItems[index];
                  return MorePageTile(item: item,index: index);
                },
              ),
          ),
        ),
      ),
    );
  }

  
}