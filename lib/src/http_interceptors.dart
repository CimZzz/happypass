import 'dart:async';
import 'http_interceptor_chain.dart';
import 'http_responses.dart';

/// 请求拦截器
/// 用来接收并处理 Request
abstract class PassInterceptor {
	const PassInterceptor();
	
	FutureOr<PassResponse> intercept(PassInterceptorChain chain);
}

/// 打印请求 Url 拦截器
class LogUrlInterceptor extends PassInterceptor {
	const LogUrlInterceptor();
	
	@override
	FutureOr<PassResponse> intercept(PassInterceptorChain chain) {
		print('current request url : ' + chain.modifier.getUrl());
		return chain.waitResponse();
	}
}

/// 拦截器接口回调
typedef SimplePassInterceptorCallback = Future<PassResponse> Function(PassInterceptorChain chain);

/// 简单的请求拦截器
/// 将拦截的逻辑放到回调闭包中实现
/// 需要注意的是，闭包必须是 `static` 的
class SimplePassInterceptor extends PassInterceptor {
	SimplePassInterceptor(this._callback);
	
	final SimplePassInterceptorCallback _callback;
	
	@override
	FutureOr<PassResponse> intercept(PassInterceptorChain chain) => _callback(chain);
}

/// 业务逻辑拦截器
/// 默认实际处理 Request 和生成 Response 的拦截器
class BusinessPassInterceptor extends PassInterceptor {
	const BusinessPassInterceptor();
	
	@override
	FutureOr<PassResponse> intercept(PassInterceptorChain chain) async {
		return await chain.requestForPassResponse();
	}
}
