import 'dart:async';

import 'package:happypass/happypass.dart';


final completer = Completer();

final list = List<String>();
void main() async {
	print(list is List);
	print(list is List<String>);
}

