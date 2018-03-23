library stack;

import 'dart:collection';
import 'package:more/ordering.dart';

typedef Stack StackModifier(Stack stack);

Ordering stackOrdering = getStackOrdering();


class Stack extends ListBase<Map> {
  List<Map> _data;
  Ordering ordering;

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
  var newStack = new Stack.from(stack);
  var kleen = newStack.where((e) => e['assetId'] == 77459);
  var towantic = kleen.map((e) {
    var out = new Map.from(e);
    out['assetId'] = 999991;
    out['quantity'] = 1.27*e['quantity'];
    return out;
  });
  newStack.addAll(new List.from(towantic));
  stackOrdering.sort(newStack);
  return newStack;
};



/// How to order the stack.  Need this after you modify the stack.
Ordering getStackOrdering() {
  var natural = new Ordering.natural();
  var byPrice = natural.onResultOf((Map e) => e['price']);
  var byAssetId = natural.onResultOf((Map e) => e['assetId']);
  return byPrice.compound(byAssetId);
}
