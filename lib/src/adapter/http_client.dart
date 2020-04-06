import 'package:happypass/src/adapter/http_request.dart';
import '../http.dart';

import '_http_client_for_native.dart'
if (dart.library.html) '_http_client_for_html.dart' as _httpClient;

import 'dart:io'
if (dart.library.html) 'dart:html' as _platform;

/// HappyPass HttpClient
abstract class PassHttpClient {
	
	factory PassHttpClient() => _httpClient.PassHttpClient();
	
	/// 连接超时时间
	set connectionTimeout(Duration timeout);
	Duration get connectionTimeout;
	
	/// 空闲超时时间
	set idleTimeout(Duration timeout);
	Duration get idleTimeout;
	
	/// 开启指定方法的 Http 请求
	Future<PassHttpRequest> fetchHttpRequest(ChainRequestModifier modifier);
	
	/// 关闭 HttpClient
	void close();
}