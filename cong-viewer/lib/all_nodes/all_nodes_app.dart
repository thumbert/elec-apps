library all_nodes_app;

import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:date/src/term_parse.dart';
import 'package:http/http.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec_server/src/utils/html_table.dart';
import 'package:elec_server/src/ui/controller.dart';



class AllNodesApp {

  var cache = <int,List<Map<String,dynamic>>>{};

  html.Element wrapper;

  html.InputElement _termInput;

  /// Visualize the congestion for all the nodes in the pool at once
  AllNodesApp(this.wrapper,
      {String rootUrl = 'http://localhost:8080/', Client client}){
    client ??= Client();

    _addHtmlControls();
  }


  show() async {
    var controller = _makeController();
  }


  void _addHtmlControls() {

  }


  Controller _makeController() {

  }



}