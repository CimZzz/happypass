import 'package:happypass/happypass.dart';
import 'dart:async';

/// 模拟请求回调
/// 可以通过配置该回调，对指定 url 下的请求返回模拟结果
typedef MockRequestCallback = void Function(MockClientHandler handler, ChainRequestModifier modifier);

class MockClientHandler {
	/// 模拟结果
	/// 表示在 [MockRequestCallback] 中调用 [hold]、[success]、[error] 成功生成的响应结果
	/// 当该结果存在时，会将请求进行拦截，返回该结果作为最终的响应结果
	FutureOr<PassResponse> _result;


	void hold(FutureOr<PassResponse> passResponse) {
		this._result ??= passResponse;
	}

	void success({dynamic dataBody}) {
		this._result ??= SuccessPassResponse(body: dataBody);
	}

	void error({String msg, dynamic error, StackTrace stacktrace}) {
		this._result ??= ErrorPassResponse(msg: msg, error: error, stacktrace:  stacktrace);
	}
}

/// 模拟请求拦截器
///
class MockClientPassInterceptor extends PassInterceptor {
	Map<String, MockRequestCallback> _domainMockMap;
	Map<String, MockRequestCallback> _hostMockMap;
	Map<String, MockRequestCallback> _fullPathMockMap;

	@override
	Future<PassResponse> intercept(PassInterceptorChain chain) {
		final modifier = chain.modifier;
		modifier.getHttpUrl();
		return null;
	}
}