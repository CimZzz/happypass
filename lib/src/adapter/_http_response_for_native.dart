import 'dart:io';

import 'http_response.dart' as _httpResponse;

/// Http 响应数据 Native 端实现
/// 使用的头部 Map 是 `HttpHeaders`
/// 数据流则是 `HttpClientResponse` 自身
class PassHttpResponse implements _httpResponse.PassHttpResponse {
	
	PassHttpResponse(this._statusCode, this._headers, this._bodyStream) {
		// 通过头部取得 Content-Length
		final contentLengthStr = _convertHeaderListToString(_headers['content-length']);
		if (contentLengthStr != null) {
			_contentLength = int.tryParse(contentLengthStr) ?? 0;
		}
		else {
			_contentLength = 0;
		}
	}
	
	final int _statusCode;
	
	final HttpHeaders _headers;
	
	final Stream<List<int>> _bodyStream;
	
	int _contentLength;
	
	/// 响应状态码
	int get statusCode => _statusCode;
	
	/// Content-Length
	int get contentLength => _contentLength;
	
	/// 数据流
	Stream<List<int>> get bodyStream => _bodyStream;
	
	/// 获取 Http 响应头部
	String getResponseHeader(String key) => _convertHeaderListToString(_headers[key]);
	
	
	String _convertHeaderListToString(List<String> headerList) {
		if (headerList == null) {
			return null;
		}
		
		return headerList.join(", ");
	}
}