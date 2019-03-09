library all_nodes_app;

import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:date/src/term_parse.dart';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec_server/src/utils/html_table.dart';
import 'package:elec_server/src/ui/controller.dart';
import 'package:elec_server/src/ui/term_input.dart';



class AllNodesApp {

  var cache = <int,TimeSeries<num>>{};

  html.Element wrapper;

  TermInput _termInput;


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
    wrapper.setAttribute('style', 'margin-left: 15px');

    _termInput = TermInput(wrapper, defaultValue: '-40d');


  }


  Controller _makeController() {

    var filters = <String,dynamic>{
      'term': _termInput.value,
    };

    return Controller(filters: filters);
  }



}