//import 'core.dart';
//import 'adapter/http_response.dart';
//import 'request_builder.dart';

//mixin RequestOperatorMixBase {
//	/// 所构建的请求
//	RequestOptions get buildRequest;
//}
//
//mixin RequestMixinBase<ReturnType> implements RequestOperatorMixBase {
//	/// 代理对象
//	ReturnType get returnObj;
//}
//
//mixin ResponseMixinBase {
//	/// 原始响应数据
//	PassHttpResponse rawResponse;
//
//	void assembleResponse(PassHttpResponse response) {
//		this.rawResponse = response;
//	}
//
//	void passResponse(ResponseMixinBase mixinBase) {
//		mixinBase.assembleResponse(rawResponse);
//	}
//
//	PassHttpResponse get httpResponse => rawResponse;
//}
//
///// for-each 回调
//typedef ForeachCallback<T> = bool Function(T data);
//
///// 请求头部 for-each 回调
//typedef HttpHeaderForeachCallback = void Function(String key, String value);
//
///// Future 构造回调
//typedef FutureBuilder<T> = Future<T> Function();
//
///// 请求 body 编码回调
///// 经过编码的数据传递到该回调中
//typedef RequestBodyEncodeCallback = void Function(dynamic message);
//
///// 请求基类
//abstract class RequestBuilderMixin
//	with
//		RequestMixinBase<RequestBuilder>,
//		RequestRunProxyBuilder<RequestBuilder>,
//		RequestInterceptorBuilder<RequestBuilder>,
//		RequestInterceptorClearBuilder<RequestBuilder>,
//		RequestHeaderBuilder<RequestBuilder>,
//		RequestUrlBuilder<RequestBuilder>,
//		RequestMethodBuilder<RequestBuilder>,
//		RequestEncoderBuilder<RequestBuilder>,
//		RequestDecoderBuilder<RequestBuilder>,
//		RequestChannelBuilder<RequestBuilder>,
//		RequestResponseDataUpdateBuilder<RequestBuilder>,
//		RequestResponseDataReceiverBuilder<RequestBuilder>,
//		RequestCloserBuilder<RequestBuilder>,
//		RequestIdBuilder<RequestBuilder>,
//		RequestHttpProxyBuilder<RequestBuilder>,
//		RequestTotalTimeoutBuilder<RequestBuilder>,
//		RequestTimeoutBuilder<RequestBuilder>,
//		RequestClientBuilder<RequestBuilder>,
///* 操作混合 */
//		RequestIdGetter,
//		RequestUrlGetter,
//		RequestMethodGetter,
//		RequestHeaderGetter,
//		RequestBodyGetter,
//		RequestProxyGetter,
//		RequestTimeoutGetter,
//		RequestClientGetter{
//}
//
///// 请求原型基类(原型基类应为 `static` 类型供全局共享)
///// 原型不能构造请求方法，防止因为持有大量请求体 (body) 而导致内存问题
///// 原型不能构造请求数据更新进度接口，防止持有大量引用导致内存问题
///// 原型无法设置请求 id 和获取请求 id，因为请求 id 只针对某个请求，不能泛化
//abstract class _BaseRequestPrototype<RequestPrototype>
//	with
//		RequestMixinBase<RequestPrototype>,
//		RequestRunProxyBuilder<RequestPrototype>,
//		RequestInterceptorBuilder<RequestPrototype>,
//		RequestInterceptorClearBuilder<RequestPrototype>,
//		RequestHeaderBuilder<RequestPrototype>,
//		RequestUrlBuilder<RequestPrototype>,
//		RequestEncoderBuilder<RequestPrototype>,
//		RequestDecoderBuilder<RequestPrototype>,
//		RequestChannelBuilder<RequestPrototype>,
//		RequestHttpProxyBuilder<RequestPrototype>,
//		RequestTotalTimeoutBuilder<RequestPrototype>,
//		RequestTimeoutBuilder<RequestPrototype>,
//		RequestClientBuilder<RequestPrototype>,
//	/* 操作混合 */
//		RequestUrlGetter,
//		RequestMethodGetter,
//		RequestHeaderGetter,
//		RequestProxyGetter,
//		RequestTimeoutGetter,
//		RequestClientGetter {}
//
///// 拦截链请求修改器
///// 可以在拦截过程中对请求进行一些修改
///// - 修改请求头
///// - 修改请求地址
///// - 修改请求方法
///// - 修改请求编码器
///// - 修改请求解码器
///// - 获取运行代理
///// - 新增响应数据接收回调
///// - 标记请求已经执行
///// - 配置请求中断器
///// - 配置 Cookie Manager
///// - 修改 HTTP 请求代理
///// - 修改请求超时时间
//class ChainRequestModifier
//	with
//		RequestMixinBase<ChainRequestModifier>,
//		RequestHeaderBuilder<ChainRequestModifier>,
//		RequestUrlBuilder<ChainRequestModifier>,
//		RequestMethodBuilder<ChainRequestModifier>,
//		RequestEncoderBuilder<ChainRequestModifier>,
//		RequestDecoderBuilder<ChainRequestModifier>,
//		RequestChannelBuilder<ChainRequestModifier>,
//		RequestResponseDataUpdateBuilder<ChainRequestModifier>,
//		RequestResponseDataReceiverBuilder<ChainRequestModifier>,
//		RequestCloserBuilder<ChainRequestModifier>,
//		RequestIdBuilder<ChainRequestModifier>,
//		RequestHttpProxyBuilder<ChainRequestModifier>,
//		RequestTimeoutBuilder<ChainRequestModifier>,
//		RequestClientBuilder<ChainRequestModifier>,
//	/* 操作混合 */
//		RequestIdGetter,
//		RequestProxyRunner,
//		RequestUrlGetter,
//		RequestMethodGetter,
//		RequestHeaderGetter,
//		RequestBodyGetter,
//		RequestHeaderFiller,
//		RequestBodyFiller,
//		ResponseBodyDecoder,
//		ResponseDataUpdate,
//		RequestExecutedChanger,
//		ResponseRawDataTransfer,
//		RequestClose,
//		RequestEncoder,
//		ResponseDecoder,
//		RequestProxyGetter,
//		RequestTimeoutGetter,
//		RequestTotalTimeoutCaller,
//		RequestTimeoutCaller,
//		RequestTimeoutFiller,
//		RequestClientGetter {
//	ChainRequestModifier(this._request);
//
//	final Request _request;
//
//	@override
//	ChainRequestModifier get _returnObj => this;
//
//	@override
//	Request get _buildRequest => _request;
//
//	/// 添加请求中断器
//	/// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
//	@override
//	ChainRequestModifier addRequestCloser(RequestCloser requestCloser) {
//		super.addRequestCloser(requestCloser);
//		if (_buildRequest.checkExecutingStatus) {
//			// 在 `ChainRequestModifier` 生成后，每添加一个新的 `RequestCloser` 都会立即进行装配
//			requestCloser._assembleModifier(this);
//		}
//		return this;
//	}
//
//	/// 清空全部请求中断器
//	/// 在 `ChainRequestModifier` 生成后，每次清空都会将自身从旧中断器中卸载
//	/// * 因为 `ChainRequestModifier` 确保每个中断器都装配了自身
//	@override
//	ChainRequestModifier clearRequestCloser() {
//		_buildRequest.requestCloserSet?.forEach((closer) {
//			closer._finish(this);
//		});
//		return super.clearRequestCloser();
//	}
//
//	/// 清理当前所持有的引用和状态
//	@override
//	void _finish() {
//		_buildRequest.requestCloserSet?.forEach((closer) {
//			closer._finish(this);
//		});
//		super._finish();
//	}
//}
