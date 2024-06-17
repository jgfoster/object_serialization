[![Pub Package](https://img.shields.io/pub/v/object_serialization.svg)](https://pub.dev/packages/object_serialization)


A serialization library that supports circular references and 
preserves identity when objects are referenced via multiple paths. 

## Features

Many serialization libraries do not handle circular references; this one does!
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
* A factory function is used to recreate the object.
* `set transientProperties(List<Object> properties)` is used to set other properties.

The reason we can't provide all the properties during creation is that there
may be circular references between objects. That is, `a` can reference `b` and
`b` can reference `a`. Yet, while there can be circular references, they cannot
both be `final` since one must exist to be used by the other.

See the test files for further examples.

## Format

The encoded data is a JSON list of objects. Each object is a list of three or four values. The first value is the internal object identifier (used to reference this object from elsewhere). The second value is the runtime type for the object (used to recreate the object). If the object is a simple `int` or `string` then the third value is a JSON representation of the object's value. Otherwise, the third value is a list of _final_ properties and the fourth value is a list of _transient_ properties. The final properties are used when recreating the object and the transient properties are updated after the objects are all recreated.

## Additional information

See https://github.com/jgfoster/object_serialization to contribute code or file issues.
