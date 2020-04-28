import 'dart:async';

import 'core.dart';
import 'http_interceptor_chain.dart';
import 'http_responses.dart';

/// 请求对象
class Request extends RequestBuilder<Request> with RequestOptionMixin<Request>, RequestBodyMixin<Request> {
	
	Request();
	
	Request._forkByOther(RequestBuilder request) : super.forkByOther(request);
	
	/// 请求完成 Future
	Completer<ResultPassResponse> RequestCompleter;
	
	/// 执行请求
	/// 只有在 [RequestStatus.Prepare] 状态下才会实际发出请求
	/// 其余条件下均返回第一次执行时的 Future
	Future<ResultPassResponse> doRequest() {
		if (!checkPrepareStatus()) {
			return RequestCompleter.future;
		}
		markRequestExecuting();
		RequestCompleter = Completer();
		RequestCompleter.complete(_execute());
		return RequestCompleter.future;
	}
	
	/// 实际执行请求逻辑
	/// 借助 [PassInterceptorChain] 完成请求
	/// 缺省情况下，由 [BusinessPassInterceptor] 拦截器完成请求处理逻辑
	Future<ResultPassResponse> _execute() async {
		final interceptorChain = PassInterceptorChain(this);
		try {
			return await interceptorChain.intercept();
		} catch (e) {
			return ErrorPassResponse(msg: '拦截发生异常: $e', error: e);
		}
	}
}


/// 请求原型
/// 作为请求的模板，可以快速生成请求对象无需重复配置
/// [RequestPrototype.spawn] 方法可以快速生成配置好的请求参数
/// [RequestPrototype.clone] 方法可以复制一个相同配置的新的请求原型对象
class RequestPrototype extends RequestBuilder<RequestPrototype> with RequestOptionMixin<RequestPrototype> {
	
	RequestPrototype();
	
	RequestPrototype._fork(RequestPrototype requestPrototype) : super.forkByOther(requestPrototype);
	
	/// 复制一个新的原型，配置与当前配置相同
	RequestPrototype clone() => RequestPrototype._fork(this);
	
	/// 根据当前配置生成一个 Request 对象
	Request spawn() {
		final request = Request._forkByOther(this);
		return request;
	}
}


