

import 'dart:html';
import 'package:timezone/browser.dart';
//import 'package:load_viewer/shape_viewer/shape_viewer.dart';
import 'package:elec_server/src/utils/custom_client.dart';


main() async {
  await initializeTimeZone();

//  var client = CustomClient();
//  var rootUrl = "http://localhost:8080/";
//  var wrapper = querySelector('#wrapper-hourly-shape');
//
//  var shapeViewer = ShapeViewer(wrapper, client, rootUrl: rootUrl);
//  await shapeViewer.show();

  querySelector('#output').text = 'Your Dart app is running.';


}
