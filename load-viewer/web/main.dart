
import 'dart:async';
import 'dart:html';
import 'package:timezone/browser.dart';
import 'package:load_viewer/shape_viewer/shape_viewer.dart';


main() async {
  await initializeTimeZone();

  var shapeViewer = new ShapeViewer();
  await shapeViewer.show();

  querySelector('#output').text = 'Your Dart app is running.';


}
