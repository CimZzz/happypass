
import 'test1.dart';
import 'test2.dart';

void main() {
	final a = A();
	final b = B();
	a.b = b;
	b.a = a;

	print(a);
	print(b);
}