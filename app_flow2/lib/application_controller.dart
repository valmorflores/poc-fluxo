import 'package:get/get.dart';

import 'component_model.dart';

class ApplicationController extends GetxController {

  late List<ComponentModel>componentsList = [];

  add(ComponentModel componentModel ){
    componentsList.add(componentModel);
  }


  @override
  void onInit() {
    componentsList = [];
    componentsList.add(ComponentModel(id:0,left: 10, top: 0, name: '', type: ShapeType.box));
    componentsList.add(ComponentModel(id:0,left: 300, top: 450, name: '', type: ShapeType.decisionIf));
    componentsList.add(ComponentModel(id:0,left: 0, top: 0, name: '', type: ShapeType.circle));
    
    super.onInit();
  }
}