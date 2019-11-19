part of 'http.dart';

mixin _RequestMixinBase<ReturnType> {
	/// 所构建的请求
	Request get _buildRequest;
	/// 代理对象
	ReturnType get _returnObj;
}

/// 请求运行代理配置混合
/// 用于配置 Request 运行代理
mixin _RequestRunProxySetBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置执行请求的代理方法
	/// 应在代理接口中直接调用参数中的回调，不做其他任何操作
	ReturnType setRequestRunProxy(AsyncRunProxy proxy) {
		if (_buildRequest.checkPrepareStatus) {
			_buildRequest._runProxy = proxy;
		}

		return _returnObj;
	}
}

/// 获取请求运行代理配置混合
/// 用于获取 Request 运行代理
mixin _RequestRunProxyGetBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 获取请求的代理方法
	AsyncRunProxy getRequestRunProxy() {
		return _buildRequest._runProxy;
	}
}


/// 请求拦截器配置混合
/// 用于配置 Request 拦截器
mixin _RequestInterceptorBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 拦截器列表
	List<PassInterceptor> get _passInterceptors {
		return _buildRequest._passInterceptorList ??= List();
	}

	/// 在首位添加拦截器
	/// 最后添加的拦截器最先被运行
	ReturnType addFirstInterceptor(PassInterceptor interceptor) {
		if (_buildRequest.checkPrepareStatus) {
			_passInterceptors.insert(0, interceptor);
		}
		return _returnObj;
	}
}

/// 请求拦截器清空混合
/// 用于清空 Request 中所有的拦截器
mixin _RequestInterceptorClearBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 清空全部拦截器
	/// 注意的一点是，默认拦截器列表中存在 [BusinessPassInterceptor] 类作为基础的请求处理拦截器
	ReturnType clearInterceptors() {
		if (_buildRequest.checkPrepareStatus) {
			_buildRequest._passInterceptorList = null;
		}
		return _returnObj;
	}
}

/// 请求头部配置混合
/// 用于配置 Request 头部
mixin _RequestHeaderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 头部表
	Map<String, String> get _header {
		return _buildRequest._headerMap ??= Map();
	}

	/// 设置请求头部
	ReturnType setRequestHeader(String key, String value) {
		if (_buildRequest.checkExecutingStatus) _header[key] = value;
		return _returnObj;
	}

	/// 获取请求头部
	String getRequestHeader(String key) => _header[key];

	/// 遍历请求头
	void forEachRequestHeaders(void callback(String key, String value)) {
		if (_buildRequest._headerMap != null) {
			_header.forEach(callback);
		}
	}
}

/// 请求地址配置混合
/// 用于配置 Request Url
mixin _RequestUrlBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置请求地址
	ReturnType setUrl(String url) {
		if (_buildRequest.checkExecutingStatus) {
			_buildRequest._url = url;
		}
		return _returnObj;
	}

	/// 获取请求地址
	String getUrl() => _buildRequest._url;
}

/// 请求方法配置混合
/// 用于配置 Request Method
mixin _RequestMethodBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置 GET 请求
	ReturnType GET() {
		if (_buildRequest.checkExecutingStatus) {
			_buildRequest._requestMethod = RequestMethod.GET;
			_buildRequest._body = null;
		}
		return _returnObj;
	}

	/// 设置 POST 请求
	/// body 不能为 `null`
	ReturnType POST(dynamic body) {
		if (_buildRequest.checkExecutingStatus && body != null) {
			_buildRequest._requestMethod = RequestMethod.POST;
			_buildRequest._body = body;
		}
		return _returnObj;
	}

	/// 获取当前的请求方法
	RequestMethod getRequestMethod() {
		return _buildRequest._requestMethod;
	}

	/// 获取当前的请求 Body（只在 Post 方法下存在该值）
	dynamic getRequestBody() {
		return _buildRequest._body;
	}
}

/// 请求编码器配置混合
/// 用于配置 Request Encoders
mixin _RequestEncoderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 编码器列表
	List<HttpMessageEncoder> get _encoders {
		return _buildRequest._encoderList ??= List();
	}

	/// 添加编码器
	/// 新添加的编码器会追加到首位
	ReturnType addFirstEncoder(HttpMessageEncoder encoder) {
		if (_buildRequest.checkExecutingStatus) _encoders.insert(0, encoder);
		return _returnObj;
	}

	/// 清空编码器
	ReturnType clearEncoder() {
		if (_buildRequest.checkExecutingStatus) _buildRequest._encoderList = null;
		return _returnObj;
	}
}


/// 请求解码器配置混合
/// 用于配置 Request Decoders
mixin _RequestDecoderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 解码器列表
	List<HttpMessageDecoder> get _decoders {
		return _buildRequest._decoderList ??= List();
	}

	/// 添加解码器
	/// 新添加的解码器会追加到末位
	/// 这样时为了保证和编码器配置的顺序保持一致
	ReturnType addLastDecoder(HttpMessageDecoder decoder) {
		if (_buildRequest.checkExecutingStatus) _decoders.add(decoder);
		return _returnObj;
	}

	/// 清空解码器
	ReturnType clearDecoder() {
		if (_buildRequest.checkExecutingStatus) _buildRequest._decoderList = null;
		return _returnObj;
	}

	/// 遍历解码器
	/// 返回 false，中断遍历
	void forEachDecoder(bool callback(HttpMessageDecoder encoder)) {
		if (_buildRequest._decoderList != null) {
			int count = _buildRequest._decoderList.length;
			for (int i = 0; i < count; i++) {
				final decoder = _buildRequest._decoderList[i];
				if (!callback(decoder)) {
					break;
				}
			}
		}
	}
}

/*填充 Mixin 混合*/

/// 填充 Request 头部混合
/// 用于填充 Request Headers
mixin _RequestHeaderFiller<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 将配置好的请求头部填充到 HttpClientRequest 中
	ReturnType fillRequestHeader(HttpClientRequest httpReq) {
		final headers = _buildRequest._headerMap;
		if(headers != null && headers.isNotEmpty) {
			headers.forEach((key, value) {
				httpReq.headers.add(key, value);
			});
		}
		return _returnObj;
	}
}

/// 填充 Request 请求Body
/// 用于填充经过编码器的 Request Body
mixin _RequestBodyFiller<ReturnType> implements _RequestMethodBuilder<ReturnType> {
	/// 将配置好的 Body 填充到 HttpClientRequest 中
	/// 如果 Body 在处理过程中发生错误，则会直接返回 ErrorPassResponse，程序应直接将这个
	/// 结果返回
	Future<PassResponse> fillRequestBody(HttpClientRequest httpReq, { bool useProxy = true }) async {
		// 目前只有 POST 方法会发送请求体
		if(_buildRequest._requestMethod != RequestMethod.POST) {
			return null;
		}
		dynamic body = _buildRequest._body;
		// POST 方法的 body 不能为 null
		if(body == null) {
			return ErrorPassResponse(msg: "[POST] \"body\" 不能为 \"null\"");
		}

		dynamic message = body;
		final proxy = _buildRequest._runProxy;
		if(proxy != null && useProxy) {
			message = await proxy(_encodeMessage, _EncodeBundle(message, _buildRequest._encoderList));
		}

		if(message is! List<int>) {
			return ErrorPassResponse(msg: "[POST] 最后的编码结果类型不为 \"List<int>\"");
		}

		httpReq.add(message);

		return null;
	}

	static Future<dynamic> _encodeMessage(_EncodeBundle bundle) async {
		var message = bundle._message;

		if (bundle._encoderList != null) {
			int count = bundle._encoderList.length;
			for (int i = 0; i < count; i++) {
				final encoder = bundle._encoderList[i];
				final oldMessage = message;
				message = encoder.encode(message);
				if (message == null) {
					message = oldMessage;
				}
			}
		}
		return message;
	}
}

class _EncodeBundle {
    const _EncodeBundle(this._message, this._encoderList);
	final dynamic _message;
	final List<HttpMessageEncoder> _encoderList;
}



/*组合 Mixin 基类*/

/// 请求基类
abstract class _BaseRequest with _RequestMixinBase<Request>,
		_RequestRunProxySetBuilder<Request>,
		_RequestInterceptorBuilder<Request>,
		_RequestInterceptorClearBuilder<Request>,
		_RequestHeaderBuilder<Request>,
		_RequestUrlBuilder<Request>,
		_RequestMethodBuilder<Request>,
		_RequestEncoderBuilder<Request>,
		_RequestDecoderBuilder<Request>
{
	@override
	Request get _returnObj => this;

	@override
	Request get _buildRequest => this;
}

/// 请求原型基类
/// 原型不能构造请求方法，防止因为持有大量请求体 (body) 而导致内存问题
abstract class _BaseRequestPrototype<RequestPrototype> with _RequestMixinBase<RequestPrototype>,
		_RequestRunProxySetBuilder<RequestPrototype>,
		_RequestInterceptorBuilder<RequestPrototype>,
		_RequestInterceptorClearBuilder<RequestPrototype>,
		_RequestHeaderBuilder<RequestPrototype>,
		_RequestUrlBuilder<RequestPrototype>,
		_RequestEncoderBuilder<RequestPrototype>,
		_RequestDecoderBuilder<RequestPrototype>
{
}

/// 拦截链请求修改器
/// 可以在拦截过程中对请求进行一些修改
/// - 修改请求头
/// - 修改请求地址
/// - 修改请求方法
/// - 修改请求编码器
/// - 修改请求解码器
/// - 获取运行代理
class ChainRequestModifier with _RequestMixinBase<ChainRequestModifier>,
		_RequestHeaderBuilder<ChainRequestModifier>,
		_RequestUrlBuilder<ChainRequestModifier>,
		_RequestMethodBuilder<ChainRequestModifier>,
		_RequestEncoderBuilder<ChainRequestModifier>,
		_RequestDecoderBuilder<ChainRequestModifier>,
		_RequestRunProxyGetBuilder<ChainRequestModifier>,
		/* 填充混合 */
		_RequestHeaderFiller<ChainRequestModifier>,
		_RequestBodyFiller<ChainRequestModifier>
{
	ChainRequestModifier(this._request);
	final Request _request;

	@override
	ChainRequestModifier get _returnObj => this;

	@override
	Request get _buildRequest => _request;
}