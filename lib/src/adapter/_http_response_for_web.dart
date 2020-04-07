import 'dart:html';

import 'http_response.dart' as _httpResponse;

class PassHttpResponse implements _httpResponse.PassHttpResponse {
	
	PassHttpResponse(this._statusCode, this._headers, this._bodyStream) {
		final contentLengthStr = _headers['content-length'];
		if(contentLengthStr != null) {
			_contentLength = int.tryParse(contentLengthStr) ?? 0;
		}
		else {
			_contentLength = 0;
		}
	}
	
	final int _statusCode;
	
	final Map<String, String> _headers;
	
	final Stream<List<int>> _bodyStream;
	
	int _contentLength;
	
	/// 响应状态码
	int get statusCode => _statusCode;
	
	/// Content-Length
	int get contentLength => _contentLength;
	
	/// 数据流
	Stream<List<int>> get bodyStream => _bodyStream;
	
	/// 获取 Http 响应头部
	String getResponseHeader(String key) => _headers[key];
}