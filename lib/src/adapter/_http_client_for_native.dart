import 'dart:io';
import '../http.dart';
import '_http_request_for_native.dart';
import 'http_client.dart' as _httpClient;

class PassHttpClient implements _httpClient.PassHttpClient {
	
	PassHttpClient() : _httpClient = HttpClient();
	
	final HttpClient _httpClient;
	
	@override
	set connectionTimeout(Duration timeout) {
		_httpClient.connectionTimeout = timeout;
	}
	
	@override
	Duration get connectionTimeout => _httpClient.connectionTimeout;
	
	@override
	set idleTimeout(Duration timeout) {
		_httpClient.idleTimeout = timeout;
	}
	
	@override
	Duration get idleTimeout => _httpClient.idleTimeout;
	
	
	@override
	Future<PassHttpRequest> fetchHttpRequest(ChainRequestModifier modifier) async {
		final method = modifier.getRequestMethod();
		final url = modifier.getUrl();
		HttpClientRequest req;
		switch(method) {
			case RequestMethod.GET:
				req = await _httpClient.getUrl(Uri.parse(url));
				break;
			case RequestMethod.POST:
				req = await _httpClient.postUrl(Uri.parse(url));
				break;
			default:
				final otherMethod = modifier.getCustomRequestMethod();
				if(otherMethod != null) {
					req = await _httpClient.openUrl(otherMethod, Uri.parse(url));
				}
				break;
		}
		
		if(req != null) {
			return PassHttpRequest(req);
		}
		
		return null;
	}
	
	
	@override
	void close() {
		_httpClient.close(force: true);
	}
}