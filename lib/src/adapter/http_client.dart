import 'http_request.dart';
import '../core.dart';
import '../http_proxy.dart';

import '_http_client_for_native.dart'
if (dart.library.html) '_http_client_for_html.dart' as _httpClient;

/// HappyPass HttpClient
abstract class PassHttpClient {
	
	factory PassHttpClient() => _httpClient.PassHttpClient();
	
	/// 连接超时时间
	/// * 只在 Native 端生效
	set connectionTimeout(Duration timeout);
	Duration get connectionTimeout;
	
	/// 空闲超时时间
	/// * 只在 Native 端生效
	set idleTimeout(Duration timeout);
	Duration get idleTimeout;

	/// 设置 Http 代理
	/// * 只在 Native 端生效
	set httpProxy(List<PassHttpProxy> passHttpProxy);

	/// 开启指定方法的 Http 请求
	Future<PassHttpRequest> fetchHttpRequest(RequestMethod requestMethod, String url, {String otherMethod});
	
	/// 关闭 HttpClient
	/// * 只在 Native 端生效
	void close();
}