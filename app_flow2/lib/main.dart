import 'package:app_flow/application_controller.dart';
import 'package:app_flow/component_model.dart';
import 'package:app_flow/modules/widgets/point_of_execution_default.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'editor.dart';
import 'modules/widgets/point_of_execution_if.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {

    
    return GetMaterialApp( debugShowCheckedModeBanner: false,
      home: Editor());
  }
}