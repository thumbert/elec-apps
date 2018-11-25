library lmp_viewer;

import 'dart:async';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:date/src/term_parse.dart';
import 'package:http/browser_client.dart';
import 'package:plotly/plotly.dart';
import 'package:timezone/browser.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec_server/src/utils/html_table.dart';
import 'package:energyoffers_viewer/src/scenario.dart';
import 'package:energyoffers_viewer/src/stack.dart';
import 'package:energyoffers_viewer/src/lib_data.dart';

class LmpViewerApp {
  Month month;
  Map layout;
  List<Map> lmpData;
  Plot plot;
  BrowserClient client;
  Location location;

  Scenario baseScenario;
  List<Map> dataTable;

  html.InputElement monthInput;
  html.Element tableWrapper;
  Map _tableOptions;

  LmpViewerApp(html.DivElement wrapper, {BrowserClient client}) {
    location = getLocation('US/Eastern');
    monthInput = html.querySelector('#month-input');
    monthInput.onChange.listen(_onMonthInputChange);

    month = new Month(2017, 6, location: location);
    client ??= BrowserClient();
    layout = _getPlotLayout();

    var dollar = new NumberFormat.currency(symbol: '\$');
    tableWrapper = html.querySelector('#price-table');
    _tableOptions = {
      '5x16': {'valueFormat': (num x) => dollar.format(x)},
      '2x16H': {'valueFormat': (num x) => dollar.format(x)},
      '7x8': {'valueFormat': (num x) => dollar.format(x)},
    };
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
      dataTable = [];
      dataTable.add({
        'Scenario': 'Historical',
        '5x16': avg[0],
        '2x16H': avg[1],
        '7x8': avg[2]
      });
      new HtmlTable(tableWrapper, dataTable, options: _tableOptions);
    });

    estimatePrices();
  }

  estimatePrices() {
    makeBaseScenario(month, client).then((_baseScenario) {
      baseScenario = _baseScenario;
      var lmpEstimated = baseScenario.calculateClearingPrice();
      Map traceLmpEstimated =
          _makeTrace(lmpEstimated, other: {'name': 'estimated'});
      plot.addTrace(traceLmpEstimated);
      html.querySelector('#output').text = '';

      TimeSeries lmpData = new TimeSeries.fromIterable(lmpEstimated.map(
          (Map e) => new IntervalTuple(
              new Hour.beginning(e['hourBeginning']), e['lmp'])));
      List<num> avg = _monthlyBucketPrice(lmpData);
      dataTable.add({
            'Scenario': 'Estimated',
            '5x16': avg[0],
            '2x16H': avg[1],
            '7x8': avg[2]
          });
      new HtmlTable(tableWrapper, dataTable, options: _tableOptions);

      addPilgrimTrace();
      new HtmlTable(tableWrapper, dataTable, options: _tableOptions);

      addTowanticTrace();
      new HtmlTable(tableWrapper, dataTable, options: _tableOptions);
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

    TimeSeries lmpData = new TimeSeries.fromIterable(lmp.map((Map e) =>
        new IntervalTuple(new Hour.beginning(e['hourBeginning']), e['lmp'])));
    List<num> avg = _monthlyBucketPrice(lmpData);
    dataTable.add({
      'Scenario': 'Pilgrim Out',
      '5x16': avg[0],
      '2x16H': avg[1],
      '7x8': avg[2]
    });
  }

  addTowanticTrace() {
    TimeSeries towanticInStack = new TimeSeries.from(
        baseScenario.stack.intervals,
        baseScenario.stack.values.map(towanticIn));
    var towanticScenario = new Scenario(
        towanticInStack, baseScenario.demand, baseScenario.imports);
    var lmp = towanticScenario.calculateClearingPrice();
    plot.addTrace(_makeTrace(lmp, other: {'name': 'Towantic in'}));

    TimeSeries lmpData = new TimeSeries.fromIterable(lmp.map((Map e) =>
        new IntervalTuple(new Hour.beginning(e['hourBeginning']), e['lmp'])));
    List<num> avg = _monthlyBucketPrice(lmpData);
    dataTable.add({
      'Scenario': 'Towantic in',
      '5x16': avg[0],
      '2x16H': avg[1],
      '7x8': avg[2]
    });
  }

  /// return the 5x16, 2x16H, 7x8 prices
  List _monthlyBucketPrice(TimeSeries x) {
    var aux = monthlyAvgByBucket(x);
    return [
      aux[month][IsoNewEngland.bucket5x16],
      aux[month][IsoNewEngland.bucket2x16H],
      aux[month][IsoNewEngland.bucket7x8],
    ];
  }

  void _onMonthInputChange(e) {
    var aux = parseTerm(monthInput.value);
    month = new Month(aux.start.year, aux.start.month, location: location);

    /// redo the analysis
    show();
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
