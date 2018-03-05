library clearing_price;

import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/http.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/elec.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';



Location _eastern = getLocation('US/Eastern');

/// Get the stack. Need a BrowserClient for web apps.
/// [dt] is the hour beginning.  Return a List
/// [{
///"assetId": 10393,
///"Unit Status": "ECONOMIC",
///"Economic Maximum": 14.9,
///"hourBeginning": "2017-07-01 15:00:00.000-0400",
///"price": -150,
///"quantity": 10.5,
///"cumulative qty": 10.5
///}, ...
Future<List<Map>> getStack(TZDateTime hourBeginning, Client client) async {
  List stamp = toIsoHourEndingStamp(hourBeginning);
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
Future<TimeSeries> _getClearedDemand(Interval interval, Client client) async {
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

/// Find the intersection of hourly supply & demand.  No nodal separation.
/// The stack and the demand should correspond to a given hour.
/// Each element of the stack is like this:
///  {
///"assetId": 17945,
///"Unit Status": "MUST_RUN",
///"hourBeginning": "2017-07-01 15:00:00.000-0400",
///"price": -150,
///"quantity": 7,
///},
///<p> return a map with the info of the marginal unit.
Map marginalUnit(Iterable<Map> stack, num demand) {
  /// Do I need to do some linear interpolation?
  Map res = {};
  num cumulativeQty = 0;
  for (Map e in stack) {
    cumulativeQty += e['quantity'];
    if (cumulativeQty >= demand) {
      return e;
    }
  }
  return res;
}

/// Calculate the hourly clearing prices for a time interval.
/// Use the function [stackModifier] to modify the stack, e.g. remove or
/// add a unit.
/// Return a List of Map {'hourBeginning', 'estimated LMP', 'marginalUnitId'}
Future<List<Map>> calculateClearingPrice(Interval interval, Client client,
    {Function stackModifier}) async {
  stackModifier ??= (x) => x;

  var clearedDemand = await _getClearedDemand(interval, client);

  List hours = interval.splitLeft((dt) => new Hour.beginning(dt));
  List res = [];
  for (Hour hour in hours) {
    var stack = await getStack(hour.start, client);
    stack = stackModifier(stack);
    var demand = clearedDemand.observationAt(hour);
    var mu = marginalUnit(stack, demand.value);
    res.add({
      'hourBeginning': hour.start,
      'estimatedLMP': mu['price'],
      'marginalUnitId': mu['assetId']
    });
  }
  return res;
}


/// Calculate the monthly price by bucket.
/// Input [x] is a List of {'interval': Interval, 'price': num}
List<Map> monthlyAvgByBucket(List<Map> x) {
  List buckets = [
    IsoNewEngland.bucket5x16,
    IsoNewEngland.bucket2x16H,
    IsoNewEngland.bucket7x8
  ];

  Nest nest = new Nest()
    ..key((Map e) {
      TZDateTime dt = e['interval'].start;
      return new Month.fromTZDateTime(dt);
    })
    ..key((Map e) {
      Hour hour = new Hour.containing(e['interval'].start);
      return buckets.firstWhere((bucket) => bucket.containsHour(e['hour']));
    })
    ..rollup((Iterable x) => mean(x.map((e) => e['price'])));

  var monthlyLmp = nest.map(x);
  //print(monthlyLmp);

  return flattenMap(monthlyLmp);
}

num mean(Iterable<num> x) {
  int i = 0;
  num res = 0;
  x.forEach((e) {
    res += e;
    i++;
  });
  return res/i;
}


monthlyBenchmark(Month month, Client client, {Function stackModifier}) async {
  var interval = new Date.fromTZDateTime(month.start);

  /// estimated prices
  List<Map> eLmp = await calculateClearingPrice(interval, client,
      stackModifier: stackModifier);

  var table = new Table.from(eLmp);
  print(table.toCsv());



//  var ts = new TimeSeries.fromIterable(eLmp.map((e) => new IntervalTuple(
//      new Hour.beginning(e['hourBeginning']), e['estimated LMP'])));
//  print(ts);
//
//
//
//  /// get hub LMPs
//  List<Map> lmp = await getHourlyHubPrices(month, client);
//  lmp = lmp
//      .map((Map e) => {
//            'interval': new Hour.beginning(
//                TZDateTime.parse(_eastern, e['hourBeginning'])),
//            'price': e['lmp']
//          })
//      .toList();
//
//
//
//
//  List res = monthlyAvgByBucket(lmp);
//  res.forEach(print);

}




