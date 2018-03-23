library stack_viewer;


import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:energyoffers_viewer/src/lib_data.dart';

class StackViewer {
  Hour hour;
  Map layout;
  List offerData;
  Plot plot;
  BrowserClient client;
  Location location;

  StackViewer() {
    location = getLocation('US/Eastern');
    hour = new Hour.beginning(new TZDateTime(location, 2017, 7, 1, 16));
    client = new BrowserClient();
    layout = {
      'title': 'Energy offer stack',
//      'autosize': false,
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
      'width': 500,
      'height': 400,
    };

  }

  show() async {
    offerData ??= await getStack(hour, client);
    offerData.take(5).forEach(print);
    List data = _makeTrace(offerData);
    plot = new Plot.id('chart-stack', data, layout);
  }


  List _makeTrace(List offerData) {
    List x = [];
    List y = [];
    num cumQty = 0;
    offerData.forEach((e) {
      x.add(e['quantity'] + cumQty);
      y.add(e['price']);
      cumQty += e['quantity'];
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