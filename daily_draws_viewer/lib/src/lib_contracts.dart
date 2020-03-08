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
  String utility;

  TimeSeries<num> calls;

  Contract.fromMap(Map<String,dynamic> x) {
    contractId = x['contractId'] ?? ArgumentError('contractId is required');
    maxDailyQuantity = x['maxDailyQuantity'] ?? ArgumentError('maxDailyQuantity is required');
    annualContractQuantity = x['annualContractQuantity'] ?? ArgumentError('annualDailyQuantity is required');
    interval = parseTerm(x['term']) ?? ArgumentError('term is required');
    pipeline = x['pipeline'];
    utility = x['utility'];
  }
}

List<Map<String,dynamic>> expandContracts(List<Contract> contracts) {
  var data = <Map<String,dynamic>>[];
  for (var contract in contracts) {
     for (var obs in contract.calls) {
       data.add({
         'contract': contract.contractId,
         'pipeline': contract.pipeline,
         'utility': contract.utility,
         'date': (obs.interval as Date).toString(),
         'value': obs.value,
       });
     }
  }
  return data;
}

/// Deal with the UI aggregation logic.
/// Return timeseries, the key is the aggregation key,
Map<String,Map<String,num>> aggregateData(List<Map<String,dynamic>> data,
    Controller controller) {

  var nest = Nest();
  var levelNames = <String>[]; //'date'];

  if (controller.filters['pipeline'] != 'All') {
    data = data.where((e) => e['pipeline'] == controller.filters['pipeline']).toList();
  }
  if (controller.filters['utility'] != 'All') {
    data = data.where((e) => e['utility'] == controller.filters['utility']).toList();
  }

  if (controller.checkboxes.contains('pipeline')) {
    nest.key((e) => e['pipeline']);
    levelNames.add('pipeline');
  }
  if (controller.checkboxes.contains('utility')) {
    nest.key((e) => e['utility']);
    levelNames.add('utility');
  }

  nest.key((e) => e['date']);
  nest.rollup((Iterable xs) => sum(xs.map((e) => e['value'])));

  var aux = nest.map(data);
  //var out = flattenMap(aux, [...levelNames, ...['date', 'value']]);

  var out = <String,Map<String,num>>{};
  if (levelNames.isEmpty) {
    out[''] = (aux as Map).cast<String,num>();
  } else if (levelNames.length == 1) {
    for (var key in aux.keys) {
      out[key as String] = (aux[key] as Map).cast<String,num>();
    }
  } else if (levelNames.length == 2) {
    for (var pipeline in aux.keys) {
      for (var utility in aux[pipeline].keys) {
        out['$pipeline|$utility'] =  (aux[pipeline][utility] as Map).cast<String,num>();
      }
    }
  }

  //var ts = reshape(out, ['date'], levelNames, 'value', fill: 0);

  if (controller.checkboxes.contains('cumulative')) {
    for (var entry in out.entries) {
      var previous = 0.0;
      for (var date in entry.value.keys) {
        entry.value[date] += previous;
        previous = entry.value[date];
      }
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
      'pipeline': 'Boom-Boom Express',
      'utility': 'Pomo Co.',
    },
    {
      'contractId': 2,
      'maxDailyQuantity': 5400,
      'annualContractQuantity': 243000,
      'term': 'Nov19-Mar20',
      'pipeline': 'Boom-Boom Express',
      'utility': 'High Gas',
    },
    {
      'contractId': 3,
      'maxDailyQuantity': 2700,
      'annualContractQuantity': 200000,
      'term': 'Dec19-Feb20',
      'pipeline': 'Transco Delight',
      'utility': 'High Gas',
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

