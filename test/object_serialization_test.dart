import 'dart:convert';

import 'package:object_serialization/object_serialization.dart';
import 'package:test/test.dart';

import 'test_classes.dart';

void main() {
  test('integer', () async {
    final buffer = ObjectSerialization.encode(1);
    expect(buffer, equals('[[0,"int",1]]'));
    final object = ObjectSerialization.decode(buffer, {}) as int;
    expect(object, equals(1));
  });

  test('string', () async {
    final buffer = ObjectSerialization.encode('one');
    expect(buffer, equals('[[0,"String","one"]]'));
    final object = ObjectSerialization.decode(buffer, {}) as String;
    expect(object, equals('one'));
  });

  test('list of simple objects', () async {
    final buffer = ObjectSerialization.encode([1, 'one']);
    expect(
      buffer,
      equals('[[0,"List<Object>",[],[1,2]],[1,"int",1],[2,"String","one"]]'),
    );
    final object = ObjectSerialization.decode(buffer, {}) as List;
    expect(object, equals([1, 'one']));
  });

  test('List<D>', () async {
    final d1 = D(1, 'one');
    final buffer = ObjectSerialization.encode([d1, d1]);
    expect(
      buffer,
      equals(
        '[[0,"List<D>",[],[1,1]],[2,"int",1],[3,"String","one"],[1,"D",[2,3],[]]]',
      ),
    );
    final factories = {
      'D': D.withFinalProperties,
    };
    final object = ObjectSerialization.decode(buffer, factories) as List;
    expect(object.first, equals(object.last));
  });

  test('Set<D>', () async {
    final d1 = D(1, 'one');
    final buffer = ObjectSerialization.encode(
      [
        {d1},
        {d1},
      ],
    );
    expect(
      buffer,
      equals(
        '[[0,"List<Set<D>>",[],[1,2]],'
        '[1,"_Set<D>",[],[3]],'
        '[2,"_Set<D>",[],[3]],'
        '[4,"int",1],'
        '[5,"String","one"],'
        '[3,"D",[4,5],[]]]',
      ),
    );
    final factories = {
      'D': D.withFinalProperties,
    };
    final object = ObjectSerialization.decode(buffer, factories) as List;
    expect(object.first.first, equals(object.last.first));
  });

  test('diamond', () async {
    final d1 = D(1, 'one');
    final b = B(d1);
    final c = C(d1);
    final a1 = A(b, c);
    expect(a1.b.d, equals(d1));
    expect(a1.c.d, equals(d1));
    final buffer = ObjectSerialization.encode(a1);
    final Map<String, FactoryFunction> factories = {
      'A': A.withFinalProperties,
      'B': B.withFinalProperties,
      'C': C.withFinalProperties,
      'D': D.withFinalProperties,
    };
    final a2 = ObjectSerialization.decode(buffer, factories) as A;
    expect(a2.b.d, equals(a2.c.d));
  });

  test('serialize jsonEncode and jsonDecode', () async {
    final s = 'abc';
    final list1 = [s, s];
    expect(identical(list1.first, list1.last), isTrue);
    final j = jsonEncode(list1);
    final list2 = jsonDecode(j) as List;
    expect(identical(list2.first, list2.last), isFalse);
  });

  test('serialize string with ObjectSerialization', () async {
    final s = 'abc';
    final list1 = [s, s];
    expect(identical(list1.first, list1.last), isTrue);
    final buffer = ObjectSerialization.encode(list1);
    final list2 = ObjectSerialization.decode(buffer, {}) as List;
    expect(identical(list2.first, list2.last), isTrue);
  });

  test('circular references', () async {
    final m1 = {};
    m1['self'] = m1;
    expect(identical(m1['self'], m1), isTrue);
    final buffer = ObjectSerialization.encode(m1);
    expect(
      buffer,
      equals('[[0,"_Map<dynamic, dynamic>",[],[1,0]],[1,"String","self"]]'),
    );
    final m2 = ObjectSerialization.decode(buffer, {}) as Map;
    expect(identical(m2['self'], m2), isTrue);
  });

  test('JSON data types', () async {
    final l1 = [
      0,
      'one',
      true,
      [],
      {1: 1},
      null,
    ];
    final buffer = ObjectSerialization.encode(l1);
    final l2 = ObjectSerialization.decode(buffer, {}) as List;
    expect(l2[0], equals(0));
    expect(l2[1], equals('one'));
    expect(l2[2], equals(true));
    expect(l2[3], equals([]));
    expect(l2[4], equals({1: 1}));
    expect(l2[5], isNull);
  });
}
