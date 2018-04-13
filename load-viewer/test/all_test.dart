

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:load_viewer/src/lib_data.dart';

getData() async {

  Interval interval = new Interval(new DateTime(2017,1),  new DateTime(2017,2));
  var data = await getHourlyRtSystemDemand(interval);
  data.take(5).forEach(print);


}


main() async {
  initializeTimeZoneSync(getLocationTzdb());

  await getData();
}