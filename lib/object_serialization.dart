/// A serialization library that supports circular references and
/// preserves identity when objects are referenced via multiple paths.
///
/// This library provides the [ObjectSerialization] class that can be used to
/// `encode` and `decode` objects to and from JSON strings. Classes that
/// implement or extend [Serializable] can handle custom serialization and
/// deserialization.
///
/// This library's primary benefit is that it can handle circular references
/// and preserves object identity so that an object referenced from multiple
/// places in the object graph is only serialized once.
library;

export 'src/object_serialization_base.dart';
