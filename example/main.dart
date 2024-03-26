import 'package:object_serialization/object_serialization.dart';

void main() {
  final s = 'abc';
  // A list with two references to the same string.
  final List<Object> list1 = [s, s];
  // Add the list to itself for a circular reference.
  list1.add(list1);
  assert(identical(list1[0], list1[1]));
  assert(identical(list1, list1[2]));
  final buffer = ObjectSerialization.encode(list1);
  final list2 = ObjectSerialization.decode(buffer, {}) as List;
  // object identity is preserved.
  assert(identical(list2[0], list2[1]));
  // circular reference is preserved.
  assert(identical(list2, list2[2]));
  print('Success!');
}
