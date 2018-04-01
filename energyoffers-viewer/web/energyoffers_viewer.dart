import 'dart:html';

import 'dart:async';
import 'dart:html';
import 'package:timezone/browser.dart';
import 'package:google_charts/google_charts.dart';
import 'package:energyoffers_viewer/stack_viewer/stack_viewer.dart';
import 'package:energyoffers_viewer/stack_viewer/lmp_viewer.dart';

main() async {
  await initializeTimeZone();
  querySelector('#output').text = 'Your Dart app is running.';
  await Table.load();
  // increase the table font because default is too small.
  document.head.append(new StyleElement());
  CssStyleSheet styleSheet = document.styleSheets.last;
  styleSheet.insertRule('.google-visualization-table-table *  { font-size: 15px; }');

  var lmpViewer = new LmpViewer();
  await lmpViewer.show();
  
//  await new StackViewer().show();

}
