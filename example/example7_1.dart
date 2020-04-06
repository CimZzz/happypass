import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:happypass/happypass.dart';

/// 本示例演示了如何利用拦截器实现自定义请求
void main() async {
	print(await happypass.post(url: 'http://localhost:4444/shop/test.php', body: FormDataBody.createByMap({'a': 'b'}),
	configCallback: (request) {
		request.stringChannel();
	}));
}

