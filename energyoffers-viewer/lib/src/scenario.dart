library scenario;

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'stack.dart';

//typedef TimeSeries DemandModification(TimeSeries demand);
//typedef TimeSeries ImportsModification(TimeSeries imports);

class Scenario {
  String scenarioName;
  int scenarioId;

  TimeSeries<Stack> stack;
  TimeSeries<num> demand;
  TimeSeries<num> imports;

  /// Construct a DAM scenario for a given time interval (hour, day, month).
  Scenario(this.stack, this.demand, this.imports) {
    /// check that the timeseries align
    bool ok = true;
    if (stack.length != demand.length || stack.length != imports.length)
      throw new ArgumentError('Dimensions of input timeseries don\'t match');
    for (int i = 0; i < stack.length; i++) {
      if (stack[i].interval != demand[i].interval ||
          stack[i].interval != imports[i].interval) {
        ok = false;
        break;
      }
    }
    if (!ok)
      throw new ArgumentError('Intervals of the input timeseries don\'t match');
  }

  /// Calculate hourly clearing price.  Return a List of
  /// {'hourBeginning': TZDateTime, 'lmp': num, 'marginalUnitId': int}
  List<Map> calculateClearingPrice() {
    List res = [];
    /// TODO: simple loop works after constructor guarantee
    for (Hour hour in stack.intervals) {
      var stackHour = stack.observationAt(hour).value;
      var demandHour = demand.observationAt(hour).value;
      var importsHour = imports.observationAt(hour).value;
      var mu = marginalUnit(stackHour, demandHour, importsHour);
      res.add({
        'hourBeginning': hour.start,
        'lmp': mu['price'],
        'marginalUnitId': mu['assetId']
      });
    }
    return res;
  }
}


/// Find the marginal unit in the stack.  Assumes that the stack is ordered.
Map marginalUnit(Stack stack, num demand, num imports) {
  Map res = {};
  num cumulativeQty = 0;
  for (Map e in stack) {
    cumulativeQty += e['quantity'];
    if (cumulativeQty >= demand - imports) {
      return e;
    }
  }
  return res;
}

//Scenario pilgrimOutScenario = new Scenario()..stackModifier = pilgrimOut;
