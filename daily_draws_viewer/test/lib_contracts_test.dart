library test.lib_contracts_test;

import 'package:daily_draws_viewer/src/lib_contracts.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/ui/controller.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() {
  group('daily draws tests', () {
    var asOfDate = Date(2020,2, 5);
    var contracts = getContracts();
    for (var contract in contracts) {
      contract.calls = simulateCalls(contract, asOfDate);
    }
    var data = expandContracts(contracts);
    test('expand contracts', () {
      expect(data.length, 261);
    });
    test('aggregate all contracts/pipeplines', () {
      var controller = Controller()
        ..checkboxes = ['cumulative']
        ..filters['pipeline'] = 'All'
        ..filters['utility'] = 'All';
      var agg = aggregateData(data, controller);
      expect(agg.length, 1);  // total data
      expect(agg['']['2019-11-01'], 5400);
      expect(agg['']['2019-11-02'], 10800);
      expect(agg['']['2019-11-03'], 10800);
    });
    test('aggregate contracts by pipepline', () {
      var controller = Controller()
        ..checkboxes = ['cumulative', 'pipeline']
        ..filters['pipeline'] = 'All'
        ..filters['utility'] = 'All';
      var agg = aggregateData(data, controller);
      expect(agg.length, 2); // 2 pipelines
      expect(agg.keys.toSet(), {'Boom-Boom Express', 'Transco Delight'});
      expect(agg['Boom-Boom Express']['2019-11-01'], 5400);
      expect(agg['Boom-Boom Express']['2019-11-02'], 10800);
      expect(agg['Boom-Boom Express']['2019-11-03'], 10800);
      expect(agg['Transco Delight']['2019-12-01'], 0);
      expect(agg['Transco Delight']['2019-12-02'], 2700);
    });
    test('aggregate contracts by pipepline and utility', () {
      var controller = Controller()
        ..checkboxes = ['cumulative', 'pipeline', 'utility']
        ..filters['pipeline'] = 'All'
        ..filters['utility'] = 'All';
      var agg = aggregateData(data, controller);
      expect(agg.length, 3); // 2 pipelines & utility combinations
      expect(agg.keys.toSet(), {'Boom-Boom Express|Pomo Co.',
        'Boom-Boom Express|High Gas', 'Transco Delight|High Gas'});
      expect(agg['Boom-Boom Express|High Gas']['2019-11-01'], 5400);
      expect(agg['Boom-Boom Express|High Gas']['2019-11-02'], 10800);
      expect(agg['Boom-Boom Express|High Gas']['2019-11-03'], 10800);
      expect(agg['Boom-Boom Express|Pomo Co.']['2019-11-01'], 0);
      expect(agg['Boom-Boom Express|Pomo Co.']['2019-11-02'], 0);
    });

  });
}


void main() async {
  await initializeTimeZones();

  tests();

}