part of 'http.dart';


typedef HttpClientBuilder = HttpClient Function(ChainRequestModifier modifier);

typedef HttpReqBuilder = Future<HttpClientRequest> Function(HttpClient client, ChainRequestModifier modifier);

typedef HttpReqInfoBuilder = Future<PassResponse> Function(HttpClientRequest httpReq, ChainRequestModifier modifier);

typedef ResponseBuilder = Future<PassResponse> Function(HttpClientRequest httpReq, ChainRequestModifier modifier);

/// 拦截器处理链
/// 通过该类完成拦截器的全部工作: 拦截 -> 修改请求 -> 完成请求 -> 返回响应的操作
/// 拦截器采取的方式是首位插入，所以最先添加的拦截器最后执行
/// 正常情况下，拦截器的工作应该如下
/// pass request : E -> D -> C -> B -> A -> BusinessPassInterceptor
/// return response : BusinessPassInterceptor -> A -> B -> C -> D -> E
/// 上述完成了一次拦截工作，Request 的处理和 Response 的构建都在 BusinessPassInterceptor 这个拦截器中完成
/// 如果在特殊情况下，某个拦截器（假设 B）意图自己完成请求处理，那么整个流程如下:
/// pass request : E -> D -> C -> B
/// return response : B -> C -> D -> E
/// 上述在 B 的位置直接拦截，请求并未传递到 [BusinessPassInterceptor]，所以 Request 的处理和 Response 的构建都应由 B 完成
///
/// 需要注意的是，如果拦截器只是对 Request 进行修改或者观察，并不想实际处理的话，请调用
/// [PassInterceptorChain.waitResponse] 方法，表示将 Request 向下传递，然后将其结果返回表示将 Response 向上返回。
///
/// 便捷方法:
/// [PassInterceptorChain.requestForPassResponse] 将构建好的 Request 通过 HttpClient 的方式转换为 Response(PassResponse)
/// [PassInterceptorChain.modifier] 可以对 Request 进行修改
class PassInterceptorChain {
	PassInterceptorChain._(Request request)
		: assert(request != null),
			_chainRequestModifier = ChainRequestModifier(request),
			_interceptors = request._passInterceptorList,
			_totalInterceptorCount = request._passInterceptorList.length ?? 0;
	
	final ChainRequestModifier _chainRequestModifier;
	final List<PassInterceptor> _interceptors;
	final int _totalInterceptorCount;
	int _currentIdx = -1;
	
	Future<ResultPassResponse> _intercept() async {
		// 首次将 `ChainRequestModifier` 装配给 `RequestCloser`（请求中断器）
		_chainRequestModifier._assembleCloser(_chainRequestModifier);
		// 如果请求在执行前已经被中断，则直接返回中断的响应结果
		if (_chainRequestModifier.isClosed) {
			final response = _chainRequestModifier._finishResponse;
			_chainRequestModifier._finish();
			return response;
		}
		final response = await _chainRequestModifier._requestProxy(_chainRequestModifier.runInTotalTimeout(_waitResponse(0)));
		_chainRequestModifier._finish();
		// 没有生成 Response，表示拦截器将请求
		if (response == null) {
			return ErrorPassResponse(msg: '未能生成 Response');
		}
		
		if (response is ResultPassResponse) {
			return response;
		}
		
		if (response is ProcessablePassResponse) {
			final successResp = SuccessPassResponse(body: response.body ?? response.bodyData);
			response.passResponse(successResp);
			return successResp;
		}
		
		return ErrorPassResponse(msg: '无法识别该 Response');
	}
	
	Future<PassResponse> _waitResponse(int idx) async {
		if (idx >= _totalInterceptorCount || _currentIdx >= idx) {
			return null;
		}
		_currentIdx = idx;
		final currentInterceptor = _interceptors[idx];
		final response = await currentInterceptor.intercept(this);
		return response;
	}
	
	/// 获取拦截链请求修改器
	/// 可以在拦截器中修改请求的大部分参数，直到有 `PassResponse` 返回
	ChainRequestModifier get modifier => _chainRequestModifier;
	
	/// 等待其他拦截器返回 `Response`
	Future<PassResponse> waitResponse() async {
		if (modifier.isClosed) {
			// 如果请求已经取消，则直接返回 null
			return null;
		}
		return await _waitResponse(_currentIdx + 1);
	}
	
	/// 实际执行 `Request` 获得 `Response`
	Future<PassResponse> requestForPassResponse() async {
		return await HttpProcessor().request(modifier);
	}
}