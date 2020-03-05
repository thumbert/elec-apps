library draws_viewer_app;

import 'dart:html' as html;

import 'package:daily_draws_viewer/src/lib_contracts.dart';
import 'package:plotly/plotly.dart';
import 'package:elec_server/ui.dart';

class DrawsViewerApp {

  html.Element wrapper;
  List<Contract> contracts;


  DrawsViewerApp(this.wrapper) {
   _addHtml();
    contracts = getContracts();
  }

  void show() async {

    var traces = <Map<String,dynamic>>[];


    Plot.id('chart', traces, _getPlotLayout());
  }

  Controller _makeController() {
    return Controller();
  }

  void _addHtml() {

    /// add a cumulative checkbox


    wrapper.children.add(html.DivElement()..setAttribute('id', 'chart'));
  }


  Map<String,dynamic> _getPlotLayout() {
    return <String,dynamic>{
      'title': 'Pipeline Daily Draws',
      'xaxis': {
        'showgrid': true,
        'gridcolor': '#bdbdbd',
      },
      'yaxis': {
        'showgrid': true,
        'gridcolor': '#bdbdbd',
        'zeroline': false,
        'title': 'Volume, MMBTU',
      },
      'hovermode': 'closest',
      'width': 950,
      'height': 600,
    };
  }


}