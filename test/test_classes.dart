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
  List<Object> get finalProperties => [b, c];
}

// The reference to `d` is `final`.
class B extends Serializable {
  B(this.d);
  factory B.withFinalProperties(List<dynamic> finalProperties) {
    return B(finalProperties[0] as D);
  }
  final D d;

  @override
  List<Object> get finalProperties => [d];
}

// The reference to `d` is not `final`.
class C extends Serializable {
  C(this.d);
  factory C.withFinalProperties(List<dynamic> finalProperties) {
    return C(D(0, ''));
  }
  D d;

  @override
  List<Object> get transientProperties => [d];

  @override
  set transientProperties(List<Object> properties) {
    d = properties[0] as D;
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
  List<Object> get finalProperties => [x, y];
}
