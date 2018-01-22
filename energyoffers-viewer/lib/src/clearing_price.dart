library clearing_price;

import 'dart:async';
import 'dart:convert';
import 'package:date/date.dart';
import 'package:http/http.dart';
import 'package:plotly/plotly.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

/// Get the stack. Need a BrowserClient for web apps.
Future<List<Map>> getStack(TZDateTime dt, Client client) async {
  String day = new Date(dt.year, dt.month, dt.day).toString();
  String hourEnding = dt.hour.toString().padLeft(2, '0');
  var url =
      'http://localhost:8080/da_energy_offers/v1/stack/date/$day/hourending/$hourEnding';
  var response = await client.get(url);
  return JSON.decode(response.body);
}


/// Find the intersection of supply & demand.  No nodal separation.  Toy-like.
num clearPrice(List<Map> stack, num demand) {

}