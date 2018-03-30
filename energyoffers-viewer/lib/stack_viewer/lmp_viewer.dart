library lmp_viewer;

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:google_charts/google_charts.dart' as gvis;
import 'package:timeseries/timeseries.dart';
import 'package:energyoffers_viewer/src/scenario.dart';
import 'package:energyoffers_viewer/src/stack.dart';
import 'package:energyoffers_viewer/src/lib_data.dart';

class LmpViewer {
  Month month;
  Map layout;
  List<Map> lmpData;
  Plot plot;
  BrowserClient client;
  Location location;

  Scenario baseScenario;
  gvis.Table table;
  gvis.DataTable dataTable;

  LmpViewer() {
    location = getLocation('US/Eastern');
    month = new Month(2017, 6, location: location);
    client = new BrowserClient();
    layout = _getPlotLayout();

    table = new gvis.Table(html.document.getElementById('price-table'));
    _makeDataTable();
  }

  show() async {
    html.querySelector('#output').text = 'Clearing the market ...';

    getHourlyHubPrices(month, client).then((lmpData) {
      //lmpData.take(5).forEach(print);
      List aux = lmpData
          .map((IntervalTuple e) =>
              {'hourBeginning': e.interval.start, 'lmp': e.value})
          .toList();
      Map traceLmpActual = _makeTrace(aux, other: {'name': 'actual'});
      plot = new Plot.id('chart-lmp', [traceLmpActual], layout);

      List<num> avg = _monthlyBucketPrice(lmpData);
      dataTable.addRow([
        'Historical',
        {'v': avg[0], 'f': '\$${avg[0].toStringAsPrecision(2)}'},
        {'v': avg[1], 'f': '\$${avg[1].toStringAsPrecision(2)}'},
        {'v': avg[2], 'f': '\$${avg[2].toStringAsPrecision(2)}'},
      ]);
      table.draw(dataTable, {'showRowNumber': true});
    });

    makeBaseScenario(month, client).then((_baseScenario) {
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
    var pilgrimOutScenario = new Scenario(
        pilgrimOutStack, baseScenario.demand, baseScenario.imports);
    var lmp = pilgrimOutScenario.calculateClearingPrice();
    plot.addTrace(_makeTrace(lmp, other: {'name': 'Pilgrim out'}));
    dataTable.addRow([
      'Pilgrim out',
      {'v': 51, 'f': '\$51.00'},
      {'v': 41, 'f': '\$41.00'},
      {'v': 31, 'f': '\$31.00'},
    ]);
    table.draw(dataTable, {'showRowNumber': true});
  }

  addTowanticTrace() {
    TimeSeries towanticInStack = new TimeSeries.from(
        baseScenario.stack.intervals,
        baseScenario.stack.values.map(towanticIn));
    var towanticScenario = new Scenario(
        towanticInStack, baseScenario.demand, baseScenario.imports);
    var lmp = towanticScenario.calculateClearingPrice();
    plot.addTrace(_makeTrace(lmp, other: {'name': 'Towantic in'}));
  }

  void _makeDataTable() {
    dataTable = new gvis.DataTable();
    dataTable.addColumn('string', 'Scenario');
    dataTable.addColumn('number', '5x16');
    dataTable.addColumn('number', '2x16H');
    dataTable.addColumn('number', '7x8');
  }

  /// return the 5x16, 2x16H, 7x8 prices
  List _monthlyBucketPrice(TimeSeries x) {
    var aux = monthlyAvgByBucket(x);
    return [
      aux[month.toString()]['5x16'],
      aux[month.toString()]['2x16H'],
      aux[month.toString()]['7x8'],
    ];
  }
}

/// each element of data is a Map {'hourBeginning': TZDateTime, 'lmp': num}
Map _makeTrace(List<Map> data, {Map other}) {
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
