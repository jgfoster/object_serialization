import 'dart:convert';

typedef FactoryFunction = Serializable Function(List<dynamic> finalProperties);

class ObjectSerialization {
  static String encode(Object object) {
    return _Writer(object).toString();
  }

  static Object decode(
    String buffer,
    Map<String, FactoryFunction>? factories,
  ) {
    return _Reader(buffer, factories).object;
  }
}

abstract class Serializable {
  Serializable();
  // Implementors of Serializable must provide a factory constructor
  // but since static methods are not allowed in interfaces and are
  // not inherited by subclasses, this is here as documentation.
  factory Serializable.withFinalProperties(List<dynamic> finalProperties) {
    throw UnimplementedError();
  }

  List<Object> get finalProperties {
    return [];
  }

  List<Object> get transientProperties {
    return [];
  }

  set transientProperties(List<Object> properties) {}
}

class _Object {
  _Object(this.id, this.object, this.finalProperties, this.transientProperties);
  final int id;
  final Object object;
  List<dynamic> finalProperties;
  List<dynamic> transientProperties;

  List<Object> toList() {
    final List<Object> result = [id, object.runtimeType.toString()];
    if (object is Serializable || object is List || object is Set) {
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
  final Map<int, Object> _objectsById = {};
  final Map<int, List<dynamic>> _transientPropertiesById = {};

  Object get object {
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
            .addAll(_transientPropertiesById[id]!.map((e) => _objectsById[e]!));
      } else if (object is Set) {
        object
            .addAll(_transientPropertiesById[id]!.map((e) => _objectsById[e]!));
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

  final List<Object> _result = [];
  final Set _queue = {};
  final Map<Object, int> _idsByObject = {};
  final List<_Object?> _objectsById = [];

  void _add(Object next) {
    final id = _objectsById.length;
    _idsByObject[next] = id;
    late List<Object> finalProperties;
    late List<Object> transientProperties;
    if (next is Serializable) {
      finalProperties = next.finalProperties;
      transientProperties = next.transientProperties;
    } else if (next is List<Object>) {
      finalProperties = [];
      transientProperties = next;
    } else if (next is Set<Object>) {
      finalProperties = [];
      transientProperties = next.toList();
    } else {
      finalProperties = [];
      transientProperties = [];
    }
    _objectsById.add(_Object(id, next, finalProperties, transientProperties));
    _queue.addAll(finalProperties);
    _queue.addAll(transientProperties);
  }

  void _buildObjectList(Object object) {
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
