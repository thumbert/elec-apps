import 'dart:html';

import 'dart:async';
import 'dart:html';
import 'package:timezone/browser.dart';
import 'package:energyoffers_viewer/stack_viewer/stack_viewer.dart';


main() async {
  await initializeTimeZone();
//  querySelector('#output').text = 'Your Dart app is running.';

  await new StackViewer().show();

}
