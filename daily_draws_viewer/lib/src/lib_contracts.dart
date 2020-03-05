library lib_contracts;

import 'dart:math';

import 'package:dama/dama.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/ui/controller.dart';
import 'package:table/table.dart';
import 'package:timeseries/timeseries.dart';


class Contract {
  int contractId;
  num maxDailyQuantity;  // in MMBTU
  num annualContractQuantity;  // in MMBTU
  Interval interval;
  String pipeline;

  TimeSeries<num> calls;

  Contract.fromMap(Map<String,dynamic> x) {
    contractId = x['contractId'] ?? ArgumentError('contractId is required');
    maxDailyQuantity = x['maxDailyQuantity'] ?? ArgumentError('maxDailyQuantity is required');
    annualContractQuantity = x['annualContractQuantity'] ?? ArgumentError('annualDailyQuantity is required');
    interval = parseTerm(x['term']) ?? ArgumentError('term is required');
    pipeline = x['pipeline'];
  }
}

List<Map<String,dynamic>> expandContracts(List<Contract> contracts) {
  var data = <Map<String,dynamic>>[];
  for (var contract in contracts) {
     for (var obs in contract.calls) {
       data.add({
         'contract': contract.contractId,
         'pipeline': contract.pipeline,
         'date': (obs.interval as Date).toString(),
         'value': obs.value,
       });
     }
  }
  return data;
}

/// Deal with the UI aggregation logic.
List<Map<String,dynamic>> aggregateContracts(List<Map<String,dynamic>> data,
    Controller controller) {

  var nest = Nest()
    ..key((e) => e['date']);
  var levelNames = <String>['date'];

  if (controller.filters['pipeline'] != 'All') {
    data = data.where((e) => e['pipeline'] = controller.filters['pipeline']).toList();
  }

  nest.rollup((Iterable xs) => sum(xs.map((e) => e['value'])));

  var aux = nest.map(data);
  var out = flattenMap(aux, levelNames..add('value'));

  if (controller.checkboxes.contains('cumulative')) {
    var previous = 0.0;
    for (var one in out) {
      one['value'] += previous;
      previous = one['value'];
    }
  }

  return out;
}



List<Contract> getContracts() {
  var contracts = [
    {
      'contractId': 1,
      'maxDailyQuantity': 1900,
      'annualContractQuantity': 171000,
      'term': 'Nov19-Mar20',
      'pipeline': 'A',
    },
    {
      'contractId': 2,
      'maxDailyQuantity': 5400,
      'annualContractQuantity': 243000,
      'term': 'Nov19-Mar20',
      'pipeline': 'A',
    },
    {
      'contractId': 3,
      'maxDailyQuantity': 2700,
      'annualContractQuantity': 200000,
      'term': 'Dec19-Feb20',
      'pipeline': 'B',
    },
  ];
  return contracts.map((e) => Contract.fromMap(e)).toList();
}

/// Simulate the calls on this contract from startDate to asOfDate
TimeSeries<num> simulateCalls(Contract contract, Date asOfDate) {
  var ts = TimeSeries<num>();
  var lastDate = asOfDate;
  var contractLastDate = Date.fromTZDateTime(contract.interval.end).subtract(1);
  if (asOfDate.isAfter(lastDate)) lastDate = contractLastDate;
  var days = Interval(contract.interval.start, lastDate.end)
      .splitLeft((dt) => Date.fromTZDateTime(dt));
  var rand = Random(contract.contractId);
  for (var day in days) {
    var draw = 0;
    var e = rand.nextDouble();
    if (e < 0.2) {
      draw += contract.maxDailyQuantity;
    }
    ts.add(IntervalTuple(day, draw));
  }
  return ts;
}

