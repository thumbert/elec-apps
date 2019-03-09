library all_nodes_app.lib;

import 'package:date/date.dart';
import 'package:fixnum/fixnum.dart';
import 'package:elec_server/src/generated/timeseries.pbgrpc.dart';
import 'package:elec_server/client/isoexpress/dalmp.dart';
import 'package:elec/src/common_enums.dart' as ce;


Future<NumericTimeSeries> getSeries(
    int ptid, Date start, Date end, LmpClient client) async {
  final congestion = LmpComponent()
    ..component = LmpComponent_Component.CONGESTION;

  var request = HistoricalLmpRequest()
    ..ptid = 4000
    ..start = Int64(start.start.millisecondsSinceEpoch)
    ..end = Int64(end.end.millisecondsSinceEpoch)
    ..component = congestion;

  var response = await client.getLmp(request);

  return response;
}

Future<NumericTimeSeries> getDailySeries(Date start, Date end,
    DaLmp client) async {

  var response = await client.getDailyPricesAllNodes(ce.LmpComponent.congestion,
    start, end);

  return response;
}
