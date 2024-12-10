import 'dart:convert';
import 'package:decimal/decimal.dart';

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

  test('nested lists', () async {
    final obj1 = [
      1,
      [
        2,
        [
          3,
          [4],
        ],
      ]
    ];
    final buffer = ObjectSerialization.encode(obj1);
    expect(
      buffer,
      equals('['
          '[0,"List<Object>",[],[1,2]],'
          '[1,"int",1],'
          '[2,"List<Object>",[],[3,4]],'
          '[3,"int",2],'
          '[4,"List<Object>",[],[5,6]],'
          '[5,"int",3],'
          '[6,"List<int>",[],[7]],'
          '[7,"int",4]'
          ']'),
    );
    final obj2 = ObjectSerialization.decode(buffer, {}) as List;
    expect(obj2, equals(obj1));
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

  test('DateTime', () async {
    final d1 = DateTime.now();
    final buffer = ObjectSerialization.encode(d1);
    final d2 = ObjectSerialization.decode(buffer, {}) as DateTime;
    expect(d2, equals(d1));
  });

  test('Decimal', () async {
    final d0 = Decimal.zero;
    final d1 = Decimal.parse('123.456');
    final buffer = ObjectSerialization.encode([d0, d1]);
    final d2 = [];
    for (final each in ObjectSerialization.decode(buffer, {})) {
      d2.add(each as Decimal);
    }
    expect(d2[0], equals(d0));
    expect(d2[1], equals(d1));
  });

  test('double', () async {
    final d1 = 1.1;
    final buffer = ObjectSerialization.encode(d1);
    final d2 = ObjectSerialization.decode(buffer, {}) as double;
    expect(d2, equals(d1));
  });

  test('Duration', () async {
    final d1 = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);
    final buffer = ObjectSerialization.encode(d1);
    final d2 = ObjectSerialization.decode(buffer, {}) as Duration;
    expect(d2, equals(d1));
  });

  test('BigInt', () async {
    final i1 = BigInt.parse('9223372036854775808');
    final buffer = ObjectSerialization.encode(i1);
    final i2 = ObjectSerialization.decode(buffer, {}) as BigInt;
    expect(i2, equals(i1));
  });

  test('Uri', () async {
    final u1 = Uri.parse('https://example.com');
    final buffer = ObjectSerialization.encode(u1);
    final u2 = ObjectSerialization.decode(buffer, {}) as Uri;
    expect(u2, equals(u1));
  });

  test('RegExp', () async {
    final r1 = RegExp(r'\d+');
    final buffer = ObjectSerialization.encode(r1);
    final r2 = ObjectSerialization.decode(buffer, {}) as RegExp;
    expect(r2, equals(r1));
  });

  test('Null', () async {
    final buffer = ObjectSerialization.encode(null);
    final object = ObjectSerialization.decode(buffer, {});
    expect(object, isNull);
  });

  test('List with Null', () async {
    final list1 = [null];
    final buffer = ObjectSerialization.encode(list1);
    final list2 = ObjectSerialization.decode(buffer, {});
    expect(list1, equals(list2));
  });

  test('Serializable with Null', () async {
    final n1 = N(null);
    final buffer = ObjectSerialization.encode(n1);
    final factories = {'N': N.withFinalProperties};
    final n2 = ObjectSerialization.decode(buffer, factories) as N;
    expect(n2.x, isNull);
    expect(n2.y, isNull);
  });
}
