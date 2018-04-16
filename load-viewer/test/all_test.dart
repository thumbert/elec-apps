

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:timezone/standalone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec/src/time/calendar/calendar.dart';
import 'package:load_viewer/src/lib_data.dart';
import 'package:load_viewer/lib_shape_analysis.dart';
import 'package:load_viewer/shape.dart';

getData() async {
  NercCalendar _calendar = new NercCalendar();
  Interval interval = new Interval(new DateTime(2014,1),  new DateTime(2017,8));
  var data = await getHourlyRtSystemDemand(interval);
  //data.take(5).forEach(print);

  var dataJul = new TimeSeries.fromIterable(
      data.where((obs) => obs.interval.start.month == 7));
  dataJul.take(5).forEach(print);
  //print(dataJul.length);

  var shapeByDay = hourlyShapeByDay(dataJul);
  print(shapeByDay[new Date(2014,7,1)]);

  // keep only the non-holiday weekdays
  List daysOut = [];
  shapeByDay.keys.forEach((Date day) {
    if (day.isWeekend() || _calendar.isHoliday(day))
      daysOut.add(day);
  });
  daysOut.forEach((day) => shapeByDay.remove(day));


  // find the average shape of this year/month combination
  var byYear = groupBy(shapeByDay.keys, (Date day) => day.year);
  var avgShape = <int,HourlyShape>{};
  byYear.forEach((year,days) {
    avgShape[year] = averageShape(days.map((day) => shapeByDay[day]).toList());
    print(avgShape[year].weights);
  });


  print(avgShape);

}


main() async {
  initializeTimeZoneSync(getLocationTzdb());

  await getData();
}