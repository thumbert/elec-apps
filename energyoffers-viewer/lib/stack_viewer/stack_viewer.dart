library stack_viewer;


import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:energyoffers_viewer/src/clearing_price.dart';

class StackViewer {
  DateTime hourBeginning;
  Map layout;
  List offerData;
  Plot plot;
  BrowserClient client;
  Location location;

  StackViewer() {
    location = getLocation('US/Eastern');
    hourBeginning = new TZDateTime(location, 2017, 7, 1, 16);
    client = new BrowserClient();
    layout = {
      'title': 'Energy offer stack',
//      'autosize': false,
//      'margin': {
//        'l': 200,
//        'r': 100,
//        'pad': 10,
//      },
      'xaxis': {
        //'showline': true,
        'showgrid': true,
        'gridcolor': '#bdbdbd',
        //'ticks': 'outside',
        'showticklabels': true,
        'title': 'Cumulative MWh',
      },
      'yaxis': {
        //'showline': true,
        'showgrid': true,
        'gridcolor': '#bdbdbd',
        'zeroline': false,
        //'ticks': 'outside',
        'showticklabels': true,
        'title': 'Offer price, \$/Mwh',
      },
      'hovermode': 'closest',
      'width': 800,
      'height': 700,
    };

  }

  show() async {
    offerData ??= await getStack(hourBeginning, client);
    offerData.take(5).forEach(print);
    List data = _makeTrace(offerData);
    plot = new Plot.id('chart-stack', data, layout);
  }


  List _makeTrace(List offerData) {
    List x = [];
    List y = [];
    offerData.forEach((e) {
      x.add(e['cumulative qty']);
      y.add(e['price']);
    });
    return [{
      'x': x,
      'y': y,
      'mode': 'lines',
      'line': {
        'width': 5,
      },
    }];
  }


}