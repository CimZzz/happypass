part of 'http.dart';

mixin _RequestOperatorMixBase {
	/// 所构建的请求
	Request get _buildRequest;
}

mixin _RequestMixinBase<ReturnType> implements _RequestOperatorMixBase {
	/// 代理对象
	ReturnType get _returnObj;
}

mixin _ResponseMixinBase {
	/// 原始响应数据
	HttpClientResponse _rawResponse;
	
	void assembleResponse(HttpClientResponse response) {
		this._rawResponse = response;
	}
	
	void passResponse(_ResponseMixinBase mixinBase) {
		mixinBase.assembleResponse(_rawResponse);
	}
	
	HttpClientResponse get _httpResponse => _rawResponse;
}

/// for-each 回调
typedef ForeachCallback<T> = bool Function(T data);

/// 请求头部 for-each 回调
typedef HttpHeaderForeachCallback = void Function(String key, String value);

/// Future 构造回调
typedef FutureBuilder<T> = Future<T> Function();

/// 请求基类
abstract class _BaseRequest
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
		_RequestCookieManagerBuilder<Request>,
		_RequestIdBuilder<Request>,
		_RequestHttpProxyBuilder<Request>,
		_RequestTotalTimeoutBuilder<Request>,
		_RequestTimeoutBuilder<Request>,
/* 操作混合 */
		_RequestIdGetter,
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter,
		_RequestProxyGetter,
		_RequestTimeoutGetter {
	@override
	Request get _returnObj => this;

	@override
	Request get _buildRequest => this;
}

/// 请求原型基类(原型基类应为 `static` 类型供全局共享)
/// 原型不能构造请求方法，防止因为持有大量请求体 (body) 而导致内存问题
/// 原型不能构造请求数据更新进度接口，防止持有大量引用导致内存问题
/// 原型无法设置请求 id 和获取请求 id，因为请求 id 只针对某个请求，不能泛化
abstract class _BaseRequestPrototype<RequestPrototype>
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
		_RequestCookieManagerBuilder<RequestPrototype>,
		_RequestHttpProxyBuilder<RequestPrototype>,
		_RequestTotalTimeoutBuilder<RequestPrototype>,
		_RequestTimeoutBuilder<RequestPrototype>,
	/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestProxyGetter,
		_RequestTimeoutGetter {}

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
class ChainRequestModifier
	with
		_RequestMixinBase<ChainRequestModifier>,
		_RequestHeaderBuilder<ChainRequestModifier>,
		_RequestUrlBuilder<ChainRequestModifier>,
		_RequestMethodBuilder<ChainRequestModifier>,
		_RequestEncoderBuilder<ChainRequestModifier>,
		_RequestDecoderBuilder<ChainRequestModifier>,
		_RequestChannelBuilder<ChainRequestModifier>,
		_RequestResponseDataUpdateBuilder<ChainRequestModifier>,
		_RequestResponseDataReceiverBuilder<ChainRequestModifier>,
		_RequestCloserBuilder<ChainRequestModifier>,
		_RequestCookieManagerBuilder<ChainRequestModifier>,
		_RequestIdBuilder<ChainRequestModifier>,
		_RequestHttpProxyBuilder<ChainRequestModifier>,
		_RequestTimeoutBuilder<ChainRequestModifier>,
	/* 操作混合 */
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
		_ResponseCookieManager,
		_RequestEncoder,
		_ResponseDecoder,
		_RequestHttpProxyFiller,
		_RequestProxyGetter,
		_RequestTimeoutGetter,
		_RequestTotalTimeoutCaller,
		_RequestTimeoutCaller,
		_RequestTimeoutFiller {
	ChainRequestModifier(this._request);

	final Request _request;

	@override
	ChainRequestModifier get _returnObj => this;

	@override
	Request get _buildRequest => _request;

	/// 添加请求中断器
	/// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
	@override
	ChainRequestModifier addRequestCloser(RequestCloser requestCloser) {
		super.addRequestCloser(requestCloser);
		if (_buildRequest.checkExecutingStatus) {
			// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
			requestCloser._assembleModifier(this);
		}
		return this;
	}

	/// 清空全部请求中断器
	/// 在 `ChainRequestModifier` 生成后，每次清空都会将自身从旧中断器中卸载
	/// * 因为 `ChainRequestModifier` 确保每个中断器都装配了自身
	@override
	ChainRequestModifier clearRequestCloser() {
		_buildRequest._requestCloserSet?.forEach((closer) {
			closer._finish(this);
		});
		return super.clearRequestCloser();
	}

	/// 清理当前所持有的引用和状态
	@override
	void _finish() {
		_buildRequest._requestCloserSet?.forEach((closer) {
			closer._finish(this);
		});
		super._finish();
	}
}
