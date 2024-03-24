<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

## Description

`object_serialization` is a serialization library that preserves identity 
when objects are referenced via multiple paths. 

## Features

Most serialization libraries do not perserve identity; this one does! 
That is, when `a` references both `b` and `c`, each of which reference `d`, 
this library installs the same `d` into both `b` and `c`. 

```
  a
 / \
b   c
 \ /
  d
```

Consider the following code in which a list contains two references to
the same object (in this case, a String):
```dart
final s = 'abc';
final list1 = [s, s];
assert(identical(list1.first, list1.last));
```
If we use `jsonEncode()` and `jsonDecode()`, the referenced object is
duplicated (object identity is lost):

```dart
final buffer = jsonEncode(list1);
final list2 = jsonDecode(buffer) as List;
assert(identical(list2.first, list2.last));  // FAILS!
```
But with `object_serializatiion` the referenced object is the same
(object identity is preserved):
```dart
final buffer = ObjectSerialization.encode(list1);
final list2 = ObjectSerialization.decode(buffer, {}) as List;
assert(identical(list2.first, list2.last));  // PASSES!
```

## Usage

While a few simple objects are handled automatically, more complex classes 
should implement or extend `Serializable`. This requires up to four new
methods:
* `List<Object> get finalProperties` and `List<Object> get transientProperties`
are used to obtain a list of properties that can be used to recreate the object.
  * `finalProperties` are those that must be provided _when the object is created_.
  * `transientProperties` are all other properties.
* `factory Serializable.withFinalProperties(List<dynamic> finalProperties)`
is used to recreate the object.
* `set transientProperties(List<Object> properties)` is used to set other properties.

The reason we can't provide all the properties during creation is that there
may be circular references between objects. That is, `a` can reference `b` and
`b` can reference `a`. Yet, while there can be circular references, they cannot
both be `final` since one must exist to be used by the other.

See the test files for examples.

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
