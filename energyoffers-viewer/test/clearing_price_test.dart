library test.clearing_price_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:energyoffers_viewer/src/clearing_price.dart';

getStackTest() async {
  group('Test stack and clearing price:', () {
    var location = getLocation('US/Eastern');
    Client client = new Client();

    test('get stack middle of day', () async {
      TZDateTime dt = new TZDateTime(location, 2017, 7, 1, 15);
      List<Map> stack = await getStack(dt, client);
      //stack.forEach(print);
      Map mu = marginalUnit(stack, 17841);
      //print(mu);
    });

    test('get stack last hour of day', () async {
      TZDateTime dt = new TZDateTime(location, 2017, 7, 1, 16);
      List<Map> stack = await getStack(dt, client);
      //stack.forEach(print);
      Map mu = marginalUnit(stack, 17841);
      print(mu);
    });

    test('clear one day', () async {
      Date date = new Date(2017, 7, 1, location: location);
      List cp = await calculateClearingPrice(date, client);
      //cp.forEach(print);
    });
  });
}

debugStack() async {
  //var location = getLocation('US/Eastern');
  Client client = new Client();

  test('get stack middle of day', () async {
    var url =
        'http://localhost:8080/da_energy_offers/v1/date/20170701/hourending/16';
    var response = await client.get(url);
    List<Map> aux = JSON.decode(response.body);
    //aux.forEach(print);

    // aggregate the qty by asset
    Nest nest = new Nest()
      ..key((e) => e['assetId'])
      ..rollup((List x) => x.map((e) => e['quantity']).reduce((a, b) => a + b));
    List res = nest
        .entries(aux)
        .map(
            (Map e) => new Map.fromIterables(['assetId', 'total MW'], e.values))
        .toList();
    res.sort((a, b) => a['total MW'].compareTo(b['total MW']));
    res.forEach(print);

    //var totalMw = nest.(aux, (e) => e['assetId']);
  });
}

monthlyBenchmarkTest() async {
  var location = getLocation('US/Eastern');
  Client client = new Client();
  Month month = new Month(2017, 7, location: location);

  var p0 = await monthlyBenchmark(month, client);


  print('Without asset 91063:');
  var p1 = await monthlyBenchmark(month, client,
      stackModifier: (Iterable<Map> e) =>
          e.where((x) => x['assetId'] != 91063).toList());
}

main() async {
  initializeTimeZoneSync(getLocationTzdb());

  //await getStackTest();

  await monthlyBenchmarkTest();
}
