library src.lib_data;

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

Location _eastern = getLocation('US/Eastern');

/// Get the RT system demand.  Return an hourly timeseries.
Future<TimeSeries> getHourlyRtSystemDemand(Interval interval,
    {Client client}) async {
  client ??= Client();
  Date start =
      new Date(interval.start.year, interval.start.month, interval.start.day);
  Date end = new Date(interval.end.year, interval.end.month, interval.end.day)
      .previous;
  var url =
      'http://localhost:8080/system_demand/v1/market/rt/start/${start.toString()}/end/${end.toString()}';
  var response = await client.get(url);
  var aux = json.decode(response.body);
  return new TimeSeries.fromIterable(aux.map((Map e) => new IntervalTuple(
      new Hour.beginning(TZDateTime.parse(_eastern, e['hourBeginning'])),
      e['Total Load'])));
}


