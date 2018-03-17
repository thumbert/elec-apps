library stack;

import 'dart:collection';
import 'package:date/date.dart';

typedef Stack StackModifier(Stack stack);

class Stack extends ListBase<Map> {
  List<Map> _data;

  /// The stack represents the energy offers of all the units at a given hour.
  /// Each offer block needs to contain at least:
  /// {
  /// "assetId": 17945,
  ///"Unit Status": "MUST_RUN",
  ///"price": -150,
  ///"quantity": 7,
  ///},
  Stack.from(this._data);

  /// need these methods from ListBase
  int get length => _data.length;
  void set length(int i) {_data.length = i;}
  Map operator [](int i) => _data[i];
  operator []=(int i, Map offer) => _data[i] = offer;
}





/// Take Pilgrim out of the stack
StackModifier pilgrimOut = (Stack stack) {
  return new Stack.from(
      stack.where((e) => e['assetId'] != 91063).toList());
};

/// Model Towantic as a bigger Kleen
StackModifier towanticIn = (Stack stack) {
  var kleen = stack.where((e) => e['assetId'] == 77459);
  var towantic = kleen.map((e) {
    e['assetId'] = 999991;
    e['quantity'] = 1.27*e['quantity'];
    return e;
  });
  return new Stack.from(stack..addAll(towantic));
};

