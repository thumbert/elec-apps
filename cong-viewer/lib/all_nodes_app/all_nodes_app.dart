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
import 'package:elec_server/client/isoexpress/dalmp.dart';
import 'all_nodes_lib.dart';


class AllNodesApp {

  Client client;

  DaLmp _daLmpClient;

  var cache = <int,TimeSeries<num>>{};
  html.Element wrapper;
  TermInput _termInput;
  html.DivElement _plotWrapper;


  /// Visualize the congestion for all the nodes in the pool at once
  AllNodesApp(this.wrapper,
      {String rootUrl = 'http://localhost:8080/', this.client}){
    client ??= Client();
    _daLmpClient = DaLmp(client, rootUrl: rootUrl);

    _addHtmlControls();
  }


  show() async {
    var controller = _makeController();
    if (cache.isEmpty) {
      var start = Date.fromTZDateTime((controller.filters['term'] as Interval).start);
      var end = Date.fromTZDateTime((controller.filters['term'] as Interval).end).subtract(1);
      cache = await getDailySeries(start, end, _daLmpClient);
    }

    Plot.id('plot-all-nodes', _makeTraces(), _getPlotLayout());
  }


  void _addHtmlControls() {
    wrapper.setAttribute('style', 'margin-left: 15px');

    _termInput = TermInput(wrapper, defaultValue: 'Jul17')
      ..onChange((e) async {
        var start = Date.fromTZDateTime(_termInput.value.start);
        var end = Date.fromTZDateTime(_termInput.value.end).subtract(1);
        cache = await getDailySeries(start, end, _daLmpClient);
        show();
      });

    _plotWrapper = html.DivElement()..id = 'plot-all-nodes';
    wrapper.children.add(_plotWrapper);
  }


  Controller _makeController() {

    var filters = <String,dynamic>{
      'term': _termInput.value,
    };

    return Controller(filters: filters);
  }


  List<Map<String,dynamic>> _makeTraces() {
    var out = <Map<String,dynamic>>[];
    for (var ptid in cache.keys) {
      var x = [];
      var y = [];
      var text = [];
      cache[ptid].forEach((e) {
        x.add(e.interval.start);
        y.add(e.value);
        text.add('ptid: $ptid');
      });
      out.add({
        'x': x,
        'y': y,
        'text': text,
        'name': 'ptid $ptid',
        'mode': 'lines',
        'line': {
          'width': 1,
        },
      });
    }
    return out;
  }


  Map<String,dynamic> _getPlotLayout() {
    return <String,dynamic>{
      'xaxis': {
        'title': '',
        'showgrid': true,
      },
      'yaxis': {
        'showgrid': true,
        'zeroline': false,
        'title': 'MCC, \$/Mwh',
      },
      'showlegend': false,
      'hovermode': 'closest',
      'width': 950,
      'height': 600,
    };
  }


}