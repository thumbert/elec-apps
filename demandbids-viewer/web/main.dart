
import 'dart:async';
import 'dart:convert';
import 'package:http/browser_client.dart';
import 'dart:html';
import 'package:plotly/plotly.dart';


Future getData() async {
  var client = new BrowserClient();
  String start = '20170701';
  String end = '20171001';
  var url = 'http://localhost:8080/da_demand_bids/v1/mwh/participant/start/$start/end/$end';
  var reponse = await client.get(url);
  return JSON.decode(reponse.body);
}

Future main() async {
  var data = await getData();

  querySelector('#chart').text = data.toString();
}
