library shape;

import 'package:date/date.dart';
import 'package:dama/stat/descriptive/summary.dart';


class HourlyShape {
  List<num> weights;
  /// the average value of the values used to calculate the weights
  num level;

  /// An hourly shape for given date, using these weights
  HourlyShape(this.weights, {this.level: 1.0}) {
    if (weights.length != 24)
      throw new ArgumentError('Wrong number of weights');
  }

  /// Construct an hourly shape from a list of values.
  HourlyShape.fromValues(List<num> values) {
    level = mean(values);
    weights = values.map((v) => v/level - 1.0).toList();
  }
}