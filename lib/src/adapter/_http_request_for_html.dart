import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import '_http_response_for_web.dart';

import 'http_request.dart' as _httpRequest;

class PassHttpRequest implements _httpRequest.PassHttpRequest {
 
	PassHttpRequest(this._request) {
		_init();
	}
	
	final HttpRequest _request;
	Map<String, String> _headerMap;
	
	bool isSendDataCompleted = false;
	
	final Completer<PassHttpResponse> _completer = Completer();
	
	void _init() {
		// 请求完成回调接口
		_request.onLoad.first.then((_) {
			if(!_completer.isCompleted) {
				final blob = _request.response ?? Blob([]);
				final reader = FileReader();
				reader.onLoad.first.then((_) {
					if(!_completer.isCompleted) {
						final body = reader.result as Uint8List;
						_completer.complete(PassHttpResponse(
							_request.status,
							_request.responseHeaders,
							Stream.value(body.toList()))
						);
					}
				});
				reader.onError.first.then((error) {
					if(!_completer.isCompleted) {
						_completer.completeError(error, StackTrace.current);
					}
				});
				reader.readAsArrayBuffer(blob);
			}
		});
		
		_request.onError.first.then((_) {
			if(!_completer.isCompleted) {
				_completer.completeError('Request failure', StackTrace.current);
			}
		});
	}
	
	@override
	void setRequestHeader(String key, String value) {
		_request.setRequestHeader(key, value);
		
		_headerMap ??= {};
		_headerMap[key] = value;
	}
	
	@override
	String getRequestHeader(String key) {
		return _headerMap == null ? null : _headerMap[key];
	}
	
	@override
	bool checkDataLegal(data) {
		return data is Blob || data is FormData || data is List<int> || data is Uint8List;
	}
	
	@override
	void sendData(data) {
		if(isSendDataCompleted) {
			throw UnsupportedError('XMLHttpRequest cannot send data twice');
		}
		if(checkDataLegal(data)) {
			_request.send(data);
			isSendDataCompleted = true;
		}
	}
	
	@override
	void close() {
		// 请求初始化之后，完成之前中断请求
		if(_request.readyState < 4 && _request.readyState > 0) {
			_request.abort();
		}
	}
}