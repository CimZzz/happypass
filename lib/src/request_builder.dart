part of 'core.dart';

/// 请求对象
class Request extends _BaseRequestOperator
	with
		_RequestMixinBase<Request>,
		_RequestRunProxyBuilder<Request>,
		_RequestInterceptorBuilder<Request>,
		_RequestInterceptorClearBuilder<Request>,
		_RequestHeaderBuilder<Request>,
		_RequestUrlBuilder<Request>,
		_RequestMethodBuilder<Request>,
		_RequestEncoderBuilder<Request>,
		_RequestDecoderBuilder<Request>,
		_RequestChannelBuilder<Request>,
		_RequestResponseDataUpdateBuilder<Request>,
		_RequestResponseDataReceiverBuilder<Request>,
		_RequestCloserBuilder<Request>,
		_RequestIdBuilder<Request>,
		_RequestHttpProxyBuilder<Request>,
		_RequestTotalTimeoutBuilder<Request>,
		_RequestTimeoutBuilder<Request>,
		_RequestClientBuilder<Request>,
	/* 操作混合 */
		_RequestStatusChecker,
		_RequestExecutedChanger,
		_RequestIdGetter,
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter,
		_RequestProxyGetter,
		_RequestTimeoutGetter,
		_RequestClientGetter,
		_RequestInterceptorsGetter {
	
	Request();
	
	Request.forkByOther(_BaseRequestOperator operator): super.forkByOther(operator);
	
	@override
	Request get returnObj => this;

	/// 请求完成 Future
	Completer<ResultPassResponse> _requestCompleter;

	/// 执行请求
	/// 只有在 [_RequestStatus.Prepare] 状态下才会实际发出请求
	/// 其余条件下均返回第一次执行时的 Future
	Future<ResultPassResponse> doRequest() {
		if (!checkPrepareStatus()) {
			return _requestCompleter.future;
		}
		markRequestExecuting();
		_requestCompleter = Completer();
		_requestCompleter.complete(_execute());
		return _requestCompleter.future;
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
class RequestPrototype extends _BaseRequestOperator
	with
		_RequestMixinBase<RequestPrototype>,
		_RequestRunProxyBuilder<RequestPrototype>,
		_RequestInterceptorBuilder<RequestPrototype>,
		_RequestInterceptorClearBuilder<RequestPrototype>,
		_RequestHeaderBuilder<RequestPrototype>,
		_RequestUrlBuilder<RequestPrototype>,
		_RequestEncoderBuilder<RequestPrototype>,
		_RequestDecoderBuilder<RequestPrototype>,
		_RequestChannelBuilder<RequestPrototype>,
		_RequestHttpProxyBuilder<RequestPrototype>,
		_RequestTotalTimeoutBuilder<RequestPrototype>,
		_RequestTimeoutBuilder<RequestPrototype>,
		_RequestClientBuilder<RequestPrototype>,
		/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestProxyGetter,
		_RequestTimeoutGetter,
		_RequestClientGetter {
		
	RequestPrototype();
	
	RequestPrototype._fork(RequestPrototype requestPrototype) : super.forkByOther(requestPrototype);
	
	@override
	RequestPrototype get returnObj => this;
	
	/// 复制一个新的原型，配置与当前配置相同
	RequestPrototype clone() => RequestPrototype._fork(this);
	
	/// 根据当前配置生成一个 Request 对象
	Request spawn() {
		final request = Request.forkByOther(this);
		return request;
	}
}



/// 拦截链请求修改器
/// 可以在拦截过程中对请求进行一些修改
/// - 修改请求头
/// - 修改请求地址
/// - 修改请求方法
/// - 修改请求编码器
/// - 修改请求解码器
/// - 获取运行代理
/// - 新增响应数据接收回调
/// - 标记请求已经执行
/// - 配置请求中断器
/// - 配置 Cookie Manager
/// - 修改 HTTP 请求代理
/// - 修改请求超时时间
class ChainRequestModifier extends _BaseRequestOperator
	with _RequestMixinBase<ChainRequestModifier>,
		_RequestHeaderBuilder<ChainRequestModifier>,
		_RequestUrlBuilder<ChainRequestModifier>,
		_RequestMethodBuilder<ChainRequestModifier>,
		_RequestEncoderBuilder<ChainRequestModifier>,
		_RequestDecoderBuilder<ChainRequestModifier>,
		_RequestChannelBuilder<ChainRequestModifier>,
		_RequestResponseDataUpdateBuilder<ChainRequestModifier>,
		_RequestResponseDataReceiverBuilder<ChainRequestModifier>,
		_RequestCloserBuilder<ChainRequestModifier>,
		_RequestIdBuilder<ChainRequestModifier>,
		_RequestHttpProxyBuilder<ChainRequestModifier>,
		_RequestTimeoutBuilder<ChainRequestModifier>,
		_RequestClientBuilder<ChainRequestModifier>,
		/* 操作混合 */
		_RequestStatusChecker,
		_RequestIdGetter,
		_RequestProxyRunner,
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter,
		_RequestHeaderFiller,
		_RequestBodyFiller,
		_ResponseBodyDecoder,
		_ResponseDataUpdate,
		_RequestExecutedChanger,
		_ResponseRawDataTransfer,
		_RequestClose,
		_RequestEncoder,
		_ResponseDecoder,
		_RequestProxyGetter,
		_RequestTimeoutGetter,
		_RequestTotalTimeoutCaller,
		_RequestTimeoutCaller,
		_RequestTimeoutFiller,
		_RequestClientGetter {

	ChainRequestModifier(Request request): super.createByOther(request);

	@override
	ChainRequestModifier get returnObj => this;


	/// 添加请求中断器
	/// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
	@override
	ChainRequestModifier addRequestCloser(RequestCloser requestCloser) {
		super.addRequestCloser(requestCloser);
		if (checkExecutingStatus()) {
			// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
			requestCloser.assembleModifier(this);
		}
		return this;
	}

	/// 清理当前所持有的引用和状态
	@override
	void finish() {
		forEachRequestCloser((closer) {
			closer.finish(this);
		});
		super.finish();
	}

}