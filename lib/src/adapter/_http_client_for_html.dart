import 'dart:html';
import '../http.dart';
import '_http_request_for_html.dart';
import 'http_client.dart' as _httpClient;

final kHttpClient = PassHttpClient();

class PassHttpClient implements _httpClient.PassHttpClient {
	
	factory PassHttpClient() => kHttpClient;
	
	@override
	set connectionTimeout(Duration timeout) {
	}
	
	@override
	Duration get connectionTimeout => null;
	
	@override
	set idleTimeout(Duration timeout) {
	}
	
	@override
	Duration get idleTimeout => null;
	
	
	@override
	Future<PassHttpRequest> fetchHttpRequest(ChainRequestModifier modifier) {
		final method = modifier.getRequestMethod();
		final url = modifier.getUrl();
		HttpRequest req = HttpRequest();
		switch(method) {
			case RequestMethod.GET:
				req.open('GET', url);
				break;
			case RequestMethod.POST:
				req.open('POST', url);
				break;
			default:
				final otherMethod = modifier.getCustomRequestMethod();
				if(otherMethod != null) {
					req.open(otherMethod, url);
				}
				else {
					return null;
				}
				break;
		}
		
		return Future.value(PassHttpRequest(req));
	}
	
	@override
	void close() {
	}
}