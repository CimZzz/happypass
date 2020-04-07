import 'dart:html';
import '../http.dart';
import '../http_errors.dart';
import '_http_request_for_html.dart';
import 'http_client.dart' as _httpClient;

final kHttpClient = PassHttpClient();

class PassHttpClient implements _httpClient.PassHttpClient {
	
	factory PassHttpClient() => kHttpClient;

	/// 连接超时时间
	/// * 只在 Native 端生效
	@override
	set connectionTimeout(Duration timeout) {
	}
	
	@override
	Duration get connectionTimeout => null;

	/// 空闲超时时间
	/// * 只在 Native 端生效
	@override
	set idleTimeout(Duration timeout) {
	}
	
	@override
	Duration get idleTimeout => null;


	/// 设置 Http 代理
	/// * 只在 Native 端生效
	@override
	set httpProxy(List<PassHttpProxy> passHttpProxy) {
	}

	/// 开启指定方法的 Http 请求
	@override
	Future<PassHttpRequest> fetchHttpRequest(RequestMethod requestMethod, String url, {String otherMethod}) async {
		HttpRequest req = HttpRequest();
		switch(requestMethod) {
			case RequestMethod.GET:
				req.open('GET', url);
				break;
			case RequestMethod.POST:
				req.open('POST', url);
				break;
			default:
				if(otherMethod != null) {
					req.open(otherMethod, url);
				}
				else {
					throw const HappyPassError('Unsupport request method');
				}
				break;
		}
		
		return PassHttpRequest(req);
	}

	/// 关闭 HttpClient
	/// * 只在 Native 端生效
	@override
	void close() {
	}
}