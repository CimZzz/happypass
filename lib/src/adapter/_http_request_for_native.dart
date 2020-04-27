import 'dart:io';
import '../http_errors.dart';
import '_http_response_for_native.dart';
import 'http_request.dart' as _httpRequest;

class PassHttpRequest implements _httpRequest.PassHttpRequest {
	
	PassHttpRequest(this._request);
	
	final HttpClientRequest _request;

	/// 标识请求是否已经执行完毕
	bool _isClosed = false;

	/// 判断请求是否已经执行完毕
	@override
	bool get isClosed => _isClosed;

	/// 设置 Http 请求头部
	@override
	void setRequestHeader(String key, String value) {
		if(_isClosed) {
			throw const HappyPassError('HttpRequest is closed');
		}
		_request.headers.set(key, value);
	}

	/// 获取 Http 请求头部
	@override
	String getRequestHeader(String key) {
		return _request.headers.value(key);
	}

	/// 发送数据
	/// - 在 Native 中，data 类型应为 `List<int>`
	///
	/// * [checkDataLegal] 方法就是用来检查数据是否合法
	@override
	void sendData(data) {
		if(_isClosed) {
			throw const HappyPassError('HttpRequest is closed');
		}
		
		if(checkDataLegal(data)) {
			_request.add(data);
		}
	}

	/// 检查请求数据是否合法
	/// - 在 Native 中，data 类型应为 `List<int>`
	@override
	bool checkDataLegal(data) {
		return data is List<int>;
	}


	/// 获取请求响应
	/// 这里的响应对象不是 `PassResponse` 的子类，而是用来包装原始 Http 响应数据的 `PassHttpResponse`
	/// `PassHttpResponse` 已经对跨平台做了兼容
	Future<PassHttpResponse> fetchHttpResponse() async {
		if(_isClosed) {
			throw const HappyPassError('HttpRequest is closed');
		}
		 final rawResponse = await _request.close();
		 if(rawResponse != null) {
		 	return PassHttpResponse (
			    rawResponse.statusCode,
			    rawResponse.headers,
			    rawResponse
		    );
		 }
		 return null;
	}
	

	/// 关闭请求
	@override
	void close() {
		if(!_isClosed) {
			_isClosed = true;
			// 屏蔽报错
			_request.close().catchError((e) {
			
			});
		}
	}
}