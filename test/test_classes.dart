// Diamond relationship; do we have one 'D' or two?
import 'package:object_serialization/object_serialization.dart';

// An instance of `A` has final references to an instance of `B` and an instance of `C`.
class A extends Serializable {
  A(this.b, this.c);
  factory A.withFinalProperties(List<dynamic> finalProperties) {
    return A(finalProperties[0] as B, finalProperties[1] as C);
  }
  final B b;
  final C c;

  @override
  List<dynamic> get finalProperties => [b, c];
}

// The reference to `d` is `final`.
class B extends Serializable {
  B(this.d);
  factory B.withFinalProperties(List<dynamic> finalProperties) {
    return B(finalProperties[0] as D);
  }
  final D d;

  @override
  List<dynamic> get finalProperties => [d];
}

// The reference to `d` is not `final`.
class C extends Serializable {
  C(this.d);
  factory C.withFinalProperties(List<dynamic> finalProperties) {
    return C(D(0, ''));
  }
  D d;

  @override
  // ensure that lists are processed before Serializable objects
  List<dynamic> get transientProperties => [
        [d],
      ];

  @override
  set transientProperties(List<dynamic> properties) {
    d = properties[0][0] as D;
  }
}

// Here we have a couple of final properties.
class D extends Serializable {
  D(this.x, this.y);
  factory D.withFinalProperties(List<dynamic> finalProperties) {
    return D(finalProperties[0] as int, finalProperties[1] as String);
  }
  final int x;
  final String y;

  @override
  List<dynamic> get finalProperties => [x, y];
}

// Here we have a nullable properties.
class N extends Serializable {
  N(this.x);
  factory N.withFinalProperties(List<dynamic> finalProperties) {
    return N(finalProperties[0] as Object?);
  }
  final Object? x;
  Object? y;

  @override
  List<dynamic> get finalProperties => [x];

  @override
  List<dynamic> get transientProperties => [y];

  @override
  set transientProperties(List<dynamic> properties) {
    y = properties[0] as Object?;
  }
}
