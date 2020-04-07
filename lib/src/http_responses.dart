import 'adapter/http_response.dart';

/// 获取原始响应信息混合
/// 可以获取原始响应数据中的头部、状态码等信息
mixin ResponseMixinBase {
	/// 原始响应数据
	PassHttpResponse _rawResponse;

	/// 装配原始响应对象
	void assembleResponse(PassHttpResponse response) {
		this._rawResponse = response;
	}

	/// 传递原始响应数据
	void passResponse(ResponseMixinBase mixinBase) {
		mixinBase.assembleResponse(_rawResponse);
	}

	/// 获取状态码
	int get statusCode => _rawResponse?.statusCode;

	/// 获取内容长度
	int get contentLength => _rawResponse?.contentLength;

	/// 获取响应头部
	String getResponseHeaders(String key) {
		return _rawResponse?.getResponseHeader(key);
	}
}

/// Http 请求响应体的基类
abstract class PassResponse {
	const PassResponse();
}

/// 结果响应体
abstract class ResultPassResponse extends PassResponse {
	const ResultPassResponse(this.isSuccess);

	final bool isSuccess;
}

/// Http 请求失败时返回的响应体
class ErrorPassResponse extends ResultPassResponse {
	const ErrorPassResponse({this.msg, this.error, this.stacktrace}) : super(false);
	final String msg;
	final dynamic error;
	final StackTrace stacktrace;

	@override
	String toString() => msg ?? 'null';
}

/// Http 请求成功是返回的响应体
class SuccessPassResponse extends ResultPassResponse with ResponseMixinBase {
	SuccessPassResponse({this.body}) : super(true);
	final dynamic body;
	
	@override
	String toString() => '$body';
}

/// Http 加工的响应体
class ProcessablePassResponse extends PassResponse with ResponseMixinBase {
	ProcessablePassResponse(this.bodyData, this.body);
	
	final List<int> bodyData;
	final dynamic body;
}
