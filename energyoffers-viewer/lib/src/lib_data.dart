library lib_data;

import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/http.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'scenario.dart';

Location _eastern = getLocation('US/Eastern');

/// Get the historical stack, demand, and make the base scenario.
Future<Scenario> makeBaseScenario(Interval interval, Client client) async {
  TimeSeries demand = await getClearedDemand(interval, client);
  TimeSeries imports =
      new TimeSeries.from(demand.intervals, new List.filled(demand.length, 0));

  List hours = interval.splitLeft((dt) => new Hour.beginning(dt));
  TimeSeries stack = new TimeSeries.fromIterable([]);
  for (Hour hour in hours) {
    var aux = await getStack(hour, client);
    stack.add(new IntervalTuple(hour, aux));
  }
  return new Scenario(stack, demand, imports)..scenarioName = 'Base scenario';
}

/// Get the stack for an hour. Need a BrowserClient for web apps.
/// [dt] is the hour beginning.  Return a List
/// [{
///"assetId": 10393,
///"Unit Status": "ECONOMIC",
///"Economic Maximum": 14.9,
///"price": -150,
///"quantity": 10.5,
///"cumulative qty": 10.5
///}, ...
Future<List<Map>> getStack(Hour hour, Client client) async {
  List stamp = toIsoHourEndingStamp(hour.start);
  var url =
      'http://localhost:8080/da_energy_offers/v1/stack/date/${stamp[0]}/hourending/${stamp[1]}';
  var response = await client.get(url);
  return JSON.decode(response.body);
}

Future<List<Map>> getHourlyHubPrices(Interval interval, Client client) async {
  Date start =
      new Date(interval.start.year, interval.start.month, interval.start.day);
  Date end = new Date(interval.end.year, interval.end.month, interval.end.day)
      .previous;
  var url =
      'http://localhost:8080/dalmp/v1/byrow/lmp/ptid/4000/start/${start.toString()}/end/${end.toString()}';
  var response = await client.get(url);
  return JSON.decode(response.body);
}

/// Get the cleared demand for a time interval.  Usually, the interval should
/// match day boundaries.
Future<TimeSeries> getClearedDemand(Interval interval, Client client) async {
  Date start =
      new Date(interval.start.year, interval.start.month, interval.start.day);
  Date end = new Date(interval.end.year, interval.end.month, interval.end.day)
      .previous;
  if (end.isBefore(start)) end = start;
  var url =
      'http://localhost:8080/system_demand/v1/market/da/start/${start.toString()}/end/${end.toString()}';
  var response = await client.get(url);
  List<Map> aux = JSON.decode(response.body);
  var ts = aux
      .map((Map e) => new IntervalTuple(
          new Hour.beginning(TZDateTime.parse(_eastern, e['hourBeginning'])),
          e['Day-Ahead Cleared Demand']))
      .where((it) => interval.containsInterval(it.interval));
  return new TimeSeries.fromIterable(ts);
}
