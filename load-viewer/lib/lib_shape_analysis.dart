library lib_shape_analysis;

import 'package:elec/elec.dart';
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:dama/stat/descriptive/summary.dart';
import 'shape.dart';

/// Calculate the average shape given a list of shapes, say the shapes of all
/// the non-holiday weekdays in a month.
HourlyShape averageShape(Iterable<HourlyShape> shapes) {
  var hours = new List.generate(24, (i) => i);

  var res = [];
  for (var hour in hours) {
    List<num> aux = [];
    shapes.forEach((e) => aux.add(e.weights[hour]));
    res.add(mean(aux));
  }

  return HourlyShape(res, level: 1);
}


/// Calculate the shape for each day.  Shape = value/mean(values) - 1.
/// <p>Input time-series contains an hourly time-series.  Return a daily
/// time-series of Hourly Shape.
Map<Date,HourlyShape> hourlyShapeByDay(TimeSeries data) {

  var byDay = data.groupByIndex((hour) => new Date.fromTZDateTime(hour.start));

  var shapes = byDay.map((observation) =>
    new HourlyShape.fromValues(observation.value));

  return new Map.fromIterables(byDay.intervals, shapes);
}



Map groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}