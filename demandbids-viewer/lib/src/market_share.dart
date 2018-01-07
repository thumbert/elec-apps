library market_share;

import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/browser_client.dart';
import 'package:dama/stat/descriptive/summary.dart';
import 'package:plotly/plotly.dart';
import 'package:timeseries/timeseries.dart';

class MarketShare {
  Date start, end;
  int topN;
  bool showStacked;
  List<Map> jsonData;
  Plot plot;
  Map layout;

  MarketShare() {
    start = new Date(
      2017,
      1,
      1,
    );
    end = new Date(2017, 9, 30);
    topN = 10;
    showStacked = false;

    layout = {
      'title': 'Demand bids by participant',
      'yaxis': {
        'title': 'Total MWh by day',
      },
      'width': 600,
      'height': 500,
    };
  }

  show() async {
    jsonData ??= await getData(start, end);
    var gData = groupBy(jsonData, (Map e) => e['participantId']);
    var big = topParticipants(gData);

    var topData = big.take(topN);
    topData.forEach(print);
    var gDataN = {};
    topData
        .forEach((p) => gDataN[p['participantId']] = gData[p['participantId']]);

    List data;
    if (showStacked) {
      data = makeStackedTraces(gDataN);
    } else {
      data = makeIndividualTraces(gDataN);
    }
    plot ??= new Plot.id('chart-market-share', data, layout);
  }

  /// add them one on top of each other ...
  List makeStackedTraces(Map<String, List<Map>> groupedData) {
    String fill = 'tozeroy';
    List res = [];
    groupedData.forEach((k, List v) {
      v.sort((a, b) => a['date'].compareTo(b['date']));
      res.add({
        'x': v.map((e) => DateTime.parse(e['date'])).toList(),
        'y': v.map((e) => e['MWh']).toList(),
        'mode': 'lines',
        'name': 'id: $k',
//      'fill': fill,
      });
//    if (fill == 'tozeroy') fill = 'tonexty';
    });
    return res;
  }


  /// make them time series for easier manipulations.
  Map<String, TimeSeries> _makeTimeSeries(Map<String, List<Map>> groupedData) {
    List<Interval> days = new TimeIterable(start,end.add(1)).toList();
    List zeros = new TimeSeries.from(days, new List.filled(days.length, 0));



  }



}



/// Return the data in this format
/// [{"participantId": 985313, "date": "2017-09-29", "MWh": 847.2}, ...]
Future<List<Map>> getData(Date start, Date end) async {
  var client = new BrowserClient();
  String startDt = start.toString();
  String endDt = end.toString();
  var url =
      'http://localhost:8080/da_demand_bids/v1/mwh/participant/start/$startDt/end/$endDt';
  var response = await client.get(url);
  return JSON.decode(response.body);
}

/// Prepare the data for plotly
List makeIndividualTraces(Map<String, List<Map>> groupedData) {
  List res = [];
  groupedData.forEach((k, List v) {
    v.sort((a, b) => a['date'].compareTo(b['date']));
    res.add({
      'x': v.map((e) => DateTime.parse(e['date'])).toList(),
      'y': v.map((e) => e['MWh']).toList(),
      'mode': 'lines',
      'name': 'id: $k',
    });
  });
  return res;
}

/// return the sorted list of daily max MWh by participant
List<Map> topParticipants(Map<String, List<Map>> groupedData) {
  List res = [];
  groupedData.forEach((k, List v) {
    res.add({'participantId': k, 'maxMWh': max(v.map((e) => e['MWh']))});
  });
  res.sort((a, b) => -a['maxMWh'].compareTo(b['maxMWh']));
  return res;
}

Map groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}
