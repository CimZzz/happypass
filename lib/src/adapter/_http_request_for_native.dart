import 'dart:io';
import 'http_request.dart' as _httpRequest;

class PassHttpRequest implements _httpRequest.PassHttpRequest {
	
	PassHttpRequest(this._request);
	
	final HttpClientRequest _request;
	
	@override
	void setRequestHeader(String key, String value) {
		_request.headers.set(key, value);
	}
	
	@override
	String getRequestHeader(String key) {
		return _request.headers.value(key);
	}
	
	@override
	bool checkDataLegal(data) {
		return data is List<int>;
	}
	
	@override
	void sendData(data) {
		if(checkDataLegal(data)) {
			_request.add(data);
		}
	}
	
	@override
	void close() {
		_request.close();
	}
}