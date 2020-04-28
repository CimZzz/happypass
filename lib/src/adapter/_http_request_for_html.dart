import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import '../http_errors.dart';
import '_http_response_for_html.dart';

import 'http_request.dart' as _httpRequest;

class PassHttpRequest implements _httpRequest.PassHttpRequest {
	
	PassHttpRequest(this._request) {
		_init();
	}
	
	/// XMLHttpRequest 对象，是该类主要的包装对象
	final HttpRequest _request;
	
	/// 请求头部表
	Map<String, String> _headerMap;
	
	/// 表示请求是否已经发送过数据
	bool isSendDataCompleted = false;
	
	/// 标识请求是否已经执行完毕
	bool _isClosed = false;
	
	/// 请求执行结果的 Completer
	final Completer<PassHttpResponse> _completer = Completer();
	
	
	/// 对 XMLHttpRequest 请求回调初始化
	void _init() {
		// 请求完成回调接口
		_request.onLoad.first.then((_) {
			if (!_completer.isCompleted) {
				if (_request.response is String) {
					_isClosed = true;
					_completer.complete(PassHttpResponse(
						_request.status,
						_request.responseHeaders,
						Stream.value(utf8.encode(_request.response))
					));
					return;
				}
				final blob = _request.response ?? Blob([]);
				final reader = FileReader();
				reader.onLoad.first.then((_) {
					if (!_completer.isCompleted) {
						final body = reader.result as Uint8List;
						_isClosed = true;
						_completer.complete(PassHttpResponse(
							_request.status,
							_request.responseHeaders,
							Stream.value(body.toList()))
						);
					}
				});
				reader.onError.first.then((error) {
					if (!_completer.isCompleted) {
						_isClosed = true;
						_completer.completeError(error, StackTrace.current);
					}
				});
				reader.readAsArrayBuffer(blob);
			}
		});
		
		_request.onError.first.then((_) {
			if (!_completer.isCompleted) {
				_isClosed = true;
				_completer.completeError('Request failure', StackTrace.current);
			}
		});
	}
	
	
	/// 判断请求是否已经执行完毕
	@override
	bool get isClosed => _isClosed;
	
	@override
	void setRequestHeader(String key, String value) {
		if (_isClosed) {
			throw const HappyPassError('XMLHttpRequest is closed');
		}
		_request.setRequestHeader(key, value);
		
		_headerMap ??= {};
		_headerMap[key] = value;
	}
	
	@override
	String getRequestHeader(String key) {
		return _headerMap == null ? null : _headerMap[key];
	}
	
	/// 检查请求数据是否合法
	/// - 在 Html 中，data 类型应为 `Blob`、`FormData`、`List<int>`、`Uint8List` 中的一种
	@override
	bool checkDataLegal(data) {
		return data is Blob || data is FormData || data is List<int> || data is Uint8List;
	}
	
	@override
	void sendData(data) {
		if (_isClosed) {
			throw const HappyPassError('XMLHttpRequest is closed');
		}
		if (isSendDataCompleted) {
			throw const HappyPassError('XMLHttpRequest cannot send data twice');
		}
		if (checkDataLegal(data)) {
			_request.send(data);
			isSendDataCompleted = true;
		}
	}
	
	/// 获取请求响应
	/// 这里的响应对象不是 `PassResponse` 的子类，而是用来包装原始 Http 响应数据的 `PassHttpResponse`
	/// `PassHttpResponse` 已经对跨平台做了兼容
	@override
	Future<PassHttpResponse> fetchHttpResponse() async {
		if (_isClosed) {
			throw const HappyPassError('XMLHttpRequest is closed');
		}
		return _completer.future;
	}
	
	/// 关闭请求
	@override
	void close() {
		if (_isClosed) {
			return;
		}
		_isClosed = true;
		// 请求初始化之后，完成之前中断请求
		if (_request.readyState < 4 && _request.readyState > 0) {
			_request.abort();
		}
	}
	
}