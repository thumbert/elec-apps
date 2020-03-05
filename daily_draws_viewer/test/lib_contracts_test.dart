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
    test('expand contracts', () {
      var data = expandContracts(contracts);
      expect(data.length, 261);
    });
    test('aggregate all contracts/pipeplines', () {
      var data = expandContracts(contracts);
      var controller = Controller()
        ..checkboxes = ['cumulative']
        ..filters['pipeline'] = 'All';
      var agg = aggregateContracts(data, controller);
      expect(agg.length, 97);
      expect(agg[0]['value'], 5400);
      expect(agg[1]['value'], 10800);
      expect(agg[2]['value'], 10800);
    });
    test('aggregate contracts by pipepline', () {
      var data = expandContracts(contracts);
      var controller = Controller()
        ..checkboxes = ['cumulative', 'pipeline']
        ..filters['pipeline'] = 'All';
      var agg = aggregateContracts(data, controller);
      expect(agg.length, 97);
      expect(agg[0]['value'], 5400);
      expect(agg[1]['value'], 10800);
      expect(agg[2]['value'], 10800);
    });
  });
}


void main() async {
  await initializeTimeZones();

  tests();

}