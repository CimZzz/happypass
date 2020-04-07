import 'dart:async';

import 'core.dart';
import 'http_interceptor_chain.dart';
import 'http_responses.dart';

/// 请求对象
///
class Request extends BaseRequestOperator
	with
		RequestMixinBase<Request>,
		RequestRunProxyBuilder<Request>,
		RequestInterceptorBuilder<Request>,
		RequestInterceptorClearBuilder<Request>,
		RequestHeaderBuilder<Request>,
		RequestUrlBuilder<Request>,
		RequestMethodBuilder<Request>,
		RequestEncoderBuilder<Request>,
		RequestDecoderBuilder<Request>,
		RequestChannelBuilder<Request>,
		RequestResponseDataUpdateBuilder<Request>,
		RequestResponseDataReceiverBuilder<Request>,
		RequestCloserBuilder<Request>,
		RequestIdBuilder<Request>,
		RequestHttpProxyBuilder<Request>,
		RequestTotalTimeoutBuilder<Request>,
		RequestTimeoutBuilder<Request>,
		RequestClientBuilder<Request>,
	/* 操作混合 */
		RequestStatusChecker,
		RequestExecutedChanger,
		RequestIdGetter,
		RequestUrlGetter,
		RequestMethodGetter,
		RequestHeaderGetter,
		RequestBodyGetter,
		RequestProxyGetter,
		RequestTimeoutGetter,
		RequestClientGetter,
		RequestInterceptorsGetter {

	@override
	Request get returnObj => this;

	/// 请求完成 Future
	Completer<ResultPassResponse> _requestCompleter;

	/// 执行请求
	/// 只有在 [RequestStatus.Prepare] 状态下才会实际发出请求
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
		final interceptorChain = PassInterceptorChain._(this);
		try {
			return await interceptorChain._intercept();
		} catch (e) {
			return ErrorPassResponse(msg: '拦截发生异常: $e', error: e);
		}
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
class ChainRequestModifier extends BaseRequestOperator
	with RequestMixinBase<ChainRequestModifier>,
		RequestHeaderBuilder<ChainRequestModifier>,
		RequestUrlBuilder<ChainRequestModifier>,
		RequestMethodBuilder<ChainRequestModifier>,
		RequestEncoderBuilder<ChainRequestModifier>,
		RequestDecoderBuilder<ChainRequestModifier>,
		RequestChannelBuilder<ChainRequestModifier>,
		RequestResponseDataUpdateBuilder<ChainRequestModifier>,
		RequestResponseDataReceiverBuilder<ChainRequestModifier>,
		RequestCloserBuilder<ChainRequestModifier>,
		RequestIdBuilder<ChainRequestModifier>,
		RequestHttpProxyBuilder<ChainRequestModifier>,
		RequestTimeoutBuilder<ChainRequestModifier>,
		RequestClientBuilder<ChainRequestModifier>,
	/* 操作混合 */
		RequestStatusChecker,
		RequestIdGetter,
		RequestProxyRunner,
		RequestUrlGetter,
		RequestMethodGetter,
		RequestHeaderGetter,
		RequestBodyGetter,
		RequestHeaderFiller,
		RequestBodyFiller,
		ResponseBodyDecoder,
		ResponseDataUpdate,
		RequestExecutedChanger,
		ResponseRawDataTransfer,
		RequestClose,
		RequestEncoder,
		ResponseDecoder,
		RequestProxyGetter,
		RequestTimeoutGetter,
		RequestTotalTimeoutCaller,
		RequestTimeoutCaller,
		RequestTimeoutFiller,
		RequestClientGetter {

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
			requestCloser._assembleModifier(this);
		}
		return this;
	}

	/// 清空全部请求中断器
	/// 在 `ChainRequestModifier` 生成后，每次清空都会将自身从旧中断器中卸载
	/// * 因为 `ChainRequestModifier` 确保每个中断器都装配了自身
	@override
	ChainRequestModifier clearRequestCloser() {
		_buildRequest.requestCloserSet?.forEach((closer) {
			closer._finish(this);
		});
		return super.clearRequestCloser();
	}

	/// 清理当前所持有的引用和状态
	@override
	void _finish() {
		_buildRequest.requestCloserSet?.forEach((closer) {
			closer._finish(this);
		});
		super._finish();
	}

}