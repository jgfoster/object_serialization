import 'dart:convert';

/// When decoding a JSON string, the [ObjectSerialization] class uses factory
/// functions to create objects of specific types. The factory functions are
/// provided as a map where the keys are the type names and the values are
/// functions that create objects of that type.
///
/// For example, `{ 'A': A.withFinalProperties }` is a map where the key is the
/// type name 'A' and the value is a factory function that creates objects of
/// type 'A'. The factory function must take a list of final properties and
/// return an object of type 'A'.
///
/// The separation of final properties from transient properties allows for the
/// deserialization of objects with circular references.
typedef FactoryFunction = Serializable Function(List<dynamic> finalProperties);

/// This class that provides static methods to [encode]
/// and [decode] objects to and from JSON strings.
class ObjectSerialization {
  /// [encode] takes an object and returns a JSON string representation of that
  /// object. The object can be a simple object, a list, a set, or an object that
  /// implements [Serializable]. The object can contain circular references.
  static String encode(dynamic object) {
    return _Writer(object).toString();
  }

  /// [decode] takes a JSON string and a map of factory functions and returns
  /// the object that was encoded in the JSON string. The factory functions are
  /// used to create objects of specific types. The factory functions are
  /// provided as a map where the keys are the type names and the values are
  /// functions that create objects of that type.
  static dynamic decode(
    String buffer,
    Map<String, FactoryFunction>? factories,
  ) {
    return _Reader(buffer, factories).object;
  }
}

/// This is an interface that classes can implement or inherit
/// to handle custom serialization and deserialization. Classes that implement
/// [Serializable] must provide a factory constructor that takes a list of final
/// properties. The final properties are the properties that are not transient
/// and are required to create the object. The transient properties are set
/// separately after the object is created.
abstract class Serializable {
  Serializable();

  /// Implementors of Serializable must provide a factory constructor
  /// but since static methods are not allowed in interfaces and are
  /// not inherited by subclasses, this is here as documentation.
  factory Serializable.withFinalProperties(List<dynamic> finalProperties) {
    throw UnimplementedError();
  }

  /// [finalProperties] returns a list of properties that are required to create
  /// the object. These properties are serialized and deserialized with the
  /// object. By separating final properties from transient properties, objects
  /// with circular references can be serialized and deserialized.
  List<dynamic> get finalProperties {
    return [];
  }

  /// [transientProperties] returns a list of properties that are not required to
  /// create the object. These properties are set after the object is created.
  List<dynamic> get transientProperties {
    return [];
  }

  /// set [transientProperties] sets the transient properties of the object after
  /// the object is created. This method is called by the [ObjectSerialization]
  /// class after the object is created.
  set transientProperties(List<dynamic> properties) {}
}

class _Object {
  _Object(this.id, this.object, this.finalProperties, this.transientProperties);
  final int id;
  final dynamic object;
  List<dynamic> finalProperties;
  List<dynamic> transientProperties;

  List<dynamic> toList() {
    final List<dynamic> result = [id, object.runtimeType.toString()];
    if (object is Serializable ||
        object is List ||
        object is Set ||
        object is Map) {
      result.add(finalProperties);
      result.add(transientProperties);
    } else {
      result.add(object);
    }
    return result;
  }

  @override
  String toString() {
    return jsonEncode(toList());
  }
}

class _Reader {
  _Reader(String buffer, this.factories) {
    _encodedObjects = jsonDecode(buffer);
    _readObjects();
    _updateTransientProperties();
  }

  late List<dynamic> _encodedObjects;
  final Map<String, FactoryFunction>? factories;
  final Map<int, dynamic> _objectsById = {};
  final Map<int, List<dynamic>> _transientPropertiesById = {};

  dynamic get object {
    return _objectsById[0]!;
  }

  void _readObjects() {
    for (final encodedObject in _encodedObjects) {
      final id = encodedObject[0] as int;
      final typeName = encodedObject[1] as String;
      final factory = factories?[typeName];
      if (factory != null) {
        final finalProperties =
            encodedObject[2].map((e) => _objectsById[e]).toList();
        _objectsById[id] = factory(finalProperties);
        _transientPropertiesById[id] = encodedObject[3];
      } else if (typeName.startsWith('List<')) {
        _objectsById[id] = [];
        _transientPropertiesById[id] = encodedObject[3];
      } else if (typeName.startsWith('_Set<')) {
        _objectsById[id] = <dynamic>{};
        _transientPropertiesById[id] = encodedObject[3];
      } else if (typeName.startsWith('_Map<')) {
        _objectsById[id] = {};
        _transientPropertiesById[id] = encodedObject[3];
      } else {
        _objectsById[id] = encodedObject[2];
      }
    }
  }

  void _updateTransientProperties() {
    for (final id in _transientPropertiesById.keys) {
      final object = _objectsById[id];
      if (object is Serializable) {
        object.transientProperties =
            _transientPropertiesById[id]!.map((e) => _objectsById[e]!).toList();
      } else if (object is List) {
        object
            .addAll(_transientPropertiesById[id]!.map((e) => _objectsById[e]));
      } else if (object is Set) {
        object
            .addAll(_transientPropertiesById[id]!.map((e) => _objectsById[e]!));
      } else if (object is Map) {
        for (var i = 0; i < _transientPropertiesById[id]!.length; i += 2) {
          final key = _objectsById[_transientPropertiesById[id]![i]];
          final value = _objectsById[_transientPropertiesById[id]![i + 1]];
          object[key] = value;
        }
      }
    }
  }
}

class _Writer {
  _Writer(object) {
    _buildObjectList(object);
    _replaceObjectsWithObjectIds();
    _addToResult();
  }

  final List<dynamic> _result = [];
  final Set _queue = {};
  final Map<dynamic, int> _idsByObject = {};
  final List<dynamic> _objectsById = [];

  void _add(dynamic next) {
    final id = _objectsById.length;
    _idsByObject[next] = id;
    final List<dynamic> finalProperties = [];
    final List<dynamic> transientProperties = [];
    if (next is Serializable) {
      finalProperties.addAll(next.finalProperties);
      transientProperties.addAll(next.transientProperties);
    } else if (next is List) {
      transientProperties.addAll(next);
    } else if (next is Set<dynamic>) {
      transientProperties.addAll(next.toList());
    } else if (next is Map<dynamic, dynamic>) {
      for (final key in next.keys) {
        transientProperties.add(key);
        transientProperties.add(next[key]);
      }
    } else if (!(next is num ||
        next is String ||
        next is bool ||
        next == null)) {
      throw 'unknown type: ${next.runtimeType}';
    }
    _objectsById.add(_Object(id, next, finalProperties, transientProperties));
    _queue.addAll(finalProperties);
    _queue.addAll(transientProperties);
  }

  void _buildObjectList(dynamic object) {
    _queue.add(object);
    while (_queue.isNotEmpty) {
      final next = _queue.first;
      _queue.remove(next);
      if (_idsByObject[next] == null) {
        _add(next);
      }
    }
  }

  void _replaceObjectsWithObjectIds() {
    for (final object in _objectsById) {
      object!.finalProperties =
          object.finalProperties.map((e) => _idsByObject[e]).toList();
      object.transientProperties =
          object.transientProperties.map((e) => _idsByObject[e]).toList();
    }
    _idsByObject.clear();
  }

  @override
  String toString() {
    return jsonEncode(_result);
  }

  void _addToResult() {
    while (true) {
      var didWrite = false;
      final remaining = _objectsById.where((element) => element != null);
      if (remaining.isEmpty) {
        return;
      }
      for (final object in remaining) {
        var okToAdd = true;
        for (final id in object!.finalProperties) {
          if (_objectsById[id] != null) {
            okToAdd = false;
            break;
          }
        }
        if (okToAdd) {
          _result.add(object.toList());
          _objectsById[object.id] = null;
          didWrite = true;
        }
      }
      if (!didWrite) {
        throw StateError('Circular reference detected');
      }
    }
  }
}
