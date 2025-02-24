enum ShapeType {
  box,
  circle,
  point,
  link,
   decisionIf,
  note
}

class ComponentModel {
  double? top;
  double? left;
  int? id;
  String? name;
  ShapeType? type;
  ComponentModel({this.top,this.left,this.id,this.name,this.type});

}