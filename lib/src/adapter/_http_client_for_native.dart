import 'dart:io';
import '../http_proxy.dart';
import '../http_errors.dart';
import '../core.dart';

import '_http_request_for_native.dart';
import 'http_client.dart' as _httpClient;

class PassHttpClient implements _httpClient.PassHttpClient {
	
	PassHttpClient() : _httpClient = HttpClient();
	
	final HttpClient _httpClient;

	/// 连接超时时间
	@override
	set connectionTimeout(Duration timeout) {
		_httpClient.connectionTimeout = timeout;
	}
	
	@override
	Duration get connectionTimeout => _httpClient.connectionTimeout;

	/// 空闲超时时间
	@override
	set idleTimeout(Duration timeout) {
		_httpClient.idleTimeout = timeout;
	}
	
	@override
	Duration get idleTimeout => _httpClient.idleTimeout;


	/// 设置 Http 代理
	@override
	set httpProxy(List<PassHttpProxy> passHttpProxy) {
		if(passHttpProxy == null || passHttpProxy.length == 0) {
			_httpClient.findProxy = null;
		}
		else {
			var proxyStr = 'DIRECT';
			passHttpProxy.forEach((proxy) {
				proxyStr = 'PROXY ${proxy.host}:${proxy.port}; ' + proxyStr;
			});
			_httpClient.findProxy = (url) => proxyStr;
		}

	}

	/// 开启指定方法的 Http 请求
	/// 在 Native 中，PassHttpRequest 包装的是 `HttpClientRequest` 对象
	@override
	Future<PassHttpRequest> fetchHttpRequest(RequestMethod requestMethod, String url, {String otherMethod}) async {
		HttpClientRequest req;
		switch(requestMethod) {
			case RequestMethod.GET:
				req = await _httpClient.getUrl(Uri.parse(url));
				break;
			case RequestMethod.POST:
				req = await _httpClient.postUrl(Uri.parse(url));
				break;
			default:
				if(otherMethod != null) {
					req = await _httpClient.openUrl(otherMethod, Uri.parse(url));
				}
				break;
		}
		
		if(req != null) {
			return PassHttpRequest(req);
		}

		throw const HappyPassError('Unsupport request method');
	}

	/// 关闭 HttpClient
	@override
	void close() {
		_httpClient.close(force: true);
	}
}