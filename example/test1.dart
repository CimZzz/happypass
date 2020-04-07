import 'test2.dart';

class A {
	B b;

	@override
	String toString() => b.runtimeType.toString();
}