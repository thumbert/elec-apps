library all_nodes_app.lib;

import 'package:date/date.dart';
import 'package:fixnum/fixnum.dart';
import 'package:elec_server/src/generated/timeseries.pbgrpc.dart';

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
