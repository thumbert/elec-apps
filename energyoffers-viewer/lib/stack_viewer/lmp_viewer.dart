library lmp_viewer;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:timeseries/timeseries.dart';
import 'package:energyoffers_viewer/src/scenario.dart';
import 'package:energyoffers_viewer/src/stack.dart';
import 'package:energyoffers_viewer/src/lib_data.dart';

class LmpViewer {
  Interval interval;
  Map layout;
  List<Map> lmpData;
  Plot plot;
  BrowserClient client;
  Location location;

  Scenario baseScenario;

  LmpViewer() {
    location = getLocation('US/Eastern');
    interval = new Month(2017, 6, location: location);
    client = new BrowserClient();
    layout = _getPlotLayout();
  }

  show() async {
    lmpData ??= await getHourlyHubPrices(interval, client);
    //lmpData.take(5).forEach(print);
    Map traceLmpActual = _makeTrace(lmpData, other: {'name': 'actual'});
    plot = new Plot.id('chart-lmp', [traceLmpActual], layout);
    html.querySelector('#output').text = 'Clearing the market ...';

    makeBaseScenario(interval, client).then((_baseScenario){
      baseScenario = _baseScenario;
      var lmpEstimated = baseScenario.calculateClearingPrice();
      Map traceLmpEstimated =
      _makeTrace(lmpEstimated, other: {'name': 'estimated'});
      plot.addTrace(traceLmpEstimated);
      html.querySelector('#output').text = '';

      addPilgrimTrace();
      addTowanticTrace();
    });

  }

  addPilgrimTrace() {
    TimeSeries pilgrimOutStack = new TimeSeries.from(
        baseScenario.stack.intervals,
        baseScenario.stack.values.map(pilgrimOut));
    var pilgrimOutScenario = new Scenario(pilgrimOutStack, baseScenario.demand,
        baseScenario.imports);
    var lmp = pilgrimOutScenario.calculateClearingPrice();
    plot.addTrace(_makeTrace(lmp, other: {'name': 'Pilgrim out'}));
    html.querySelector('#output').text = '';
  }

  addTowanticTrace() {
    TimeSeries towanticInStack = new TimeSeries.from(
        baseScenario.stack.intervals,
        baseScenario.stack.values.map(towanticIn));
    var towanticScenario = new Scenario(towanticInStack, baseScenario.demand,
        baseScenario.imports);
    var lmp = towanticScenario.calculateClearingPrice();
    plot.addTrace(_makeTrace(lmp, other: {'name': 'Towantic in'}));
    html.querySelector('#output').text = '';
  }


}



Map _makeTrace(List data, {Map other}) {
  other ??= {};
  List x = [];
  List y = [];
  data.forEach((e) {
    x.add(e['hourBeginning']);
    y.add(e['lmp']);
  });
  return other
    ..addAll({
      'x': x,
      'y': y,
      'mode': 'lines',
      'line': {
        'width': 2,
      },
    });
}

Map _getPlotLayout() {
  return {
    'title': 'LMP estimator',
    'xaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
    },
    'yaxis': {
      'showgrid': true,
      'gridcolor': '#bdbdbd',
      'zeroline': false,
      'title': 'Hub LMP, \$/Mwh',
    },
    'hovermode': 'closest',
    'width': 950,
    'height': 600,
  };
}
