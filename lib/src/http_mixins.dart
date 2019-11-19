part of 'http.dart';

mixin _RequestOperatorMixBase {
	/// 所构建的请求
	Request get _buildRequest;
}

mixin _RequestMixinBase<ReturnType> implements _RequestOperatorMixBase {
	/// 代理对象
	ReturnType get _returnObj;
}


/*配置 Mixin 混合*/

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
		if (_buildRequest.checkExecutingStatus) {
			_encoders.insert(0, encoder);
		}
		return _returnObj;
	}

	/// 清空编码器
	ReturnType clearEncoder() {
		if (_buildRequest.checkExecutingStatus) {
			_buildRequest._encoderList = null;
		}
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

/*操作 Mixin 混合*/

/// 调用请求执行代理
/// 通过请求执行代理来执行回调
/// 注意的是，回调必须为 `static`
mixin _RequestProxyRunner implements _RequestOperatorMixBase {
	/// 通过配置的执行代理执行回调
	/// 注意的是，回调必须为 `static`
	Future<Q> proxy<T, Q>(AsyncRunProxyCallback<T, Q> callback, T message) async {
		final runProxy = _buildRequest._runProxy;
		if(runProxy != null) {
			return await runProxy(callback, message);
		}
		
		return callback(message);
	}
}

/// 获取请求方法配置混合
/// 用于获取 Request 的请求方法
mixin _RequestMethodGetter implements _RequestOperatorMixBase {
	/// 获取当前的请求方法
	RequestMethod getRequestMethod() {
		return _buildRequest._requestMethod;
	}
}

/// 获取请求 Url 配置混合
/// 用于获取 Request 的请求 Url
mixin _RequestUrlGetter implements _RequestOperatorMixBase {
	/// 获取请求地址
	String getUrl() => _buildRequest._url;
}

/// 获取请求 Url 配置混合
/// 用于获取 Request 的请求 Url
mixin _RequestHeaderGetter implements _RequestOperatorMixBase {
	/// 获取请求头部
	String getRequestHeader(String key) => _buildRequest?._headerMap[key];
	
	/// 遍历请求头
	void forEachRequestHeaders(void callback(String key, String value)) {
		if (_buildRequest._headerMap != null) {
			_buildRequest._headerMap.forEach(callback);
		}
	}
}

/// 获取请求体配置混合
/// 用于获取 Request 的请求 Body
mixin _RequestBodyGetter implements _RequestOperatorMixBase {
	/// 获取当前的请求 Body（只在 Post 方法下存在该值）
	dynamic getRequestBody() {
		return _buildRequest._body;
	}
}

/// 填充 Request 头部混合
/// 用于填充 Request Headers
mixin _RequestHeaderFiller implements _RequestOperatorMixBase {
	/// 将配置好的请求头部填充到 HttpClientRequest 中
	void fillRequestHeader(
		HttpClientRequest httpReq,
		ChainRequestModifier modifier,
		{ bool useProxy = true }
	) async {
		final headers = modifier._request._headerMap;
		if(headers != null && headers.isNotEmpty) {
			final bundle = _HeaderBundle(httpReq, headers);
			if(useProxy) {
				await modifier.proxy(_fillHeaders, bundle);
			}
			else {
				await _fillHeaders(bundle);
			}
		}
	}
	
	static Future _fillHeaders(_HeaderBundle bundle) async {
		final httpReq = bundle._request;
		final headers = bundle._requestHeaders;
		if(headers != null && headers.isNotEmpty) {
			headers.forEach((key, value) {
				httpReq.headers.add(key, value);
			});
		}
	}
}

/// 用于包装需要填充的请求和请求头的数据集
class _HeaderBundle {
	_HeaderBundle(this._request, this._requestHeaders);
	
	final HttpClientRequest _request;
	final Map<String, String> _requestHeaders;
}


/// 填充 Request 请求Body
/// 用于填充 Request Body，可选择进行代理和编码
mixin _RequestBodyFiller implements _RequestOperatorMixBase {
	/// 将配置好的 Body 填充到 HttpClientRequest 中
	/// 如果 Body 在处理过程中发生错误，则会直接返回 ErrorPassResponse，程序应直接将这个
	/// 结果返回
	/// 可以选择是否使用代理，编码
	/// 默认情况下，开始编码与代理
	Future<PassResponse> fillRequestBody(
		HttpClientRequest httpReq,
		ChainRequestModifier modifier,
		{ bool useEncode = true, bool useProxy = true }
	) async {
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
		if(useEncode) {
			final encoders = _buildRequest._encoderList;
			// 存在编码器，进行编码
			if(encoders != null) {
				final bundle = _EncodeBundle(message, _buildRequest._encoderList);
				if (useProxy) {
					message = await modifier.proxy(_encodeMessage, bundle);
				}
				else {
					message = await _encodeMessage(bundle);
				}
			}
		}

		if(message is! List<int>) {
			return ErrorPassResponse(msg: "[POST] 最后的编码结果类型不为 \"List<int>\"");
		}

		httpReq.add(message);

		return null;
	}

	/// 实际 encode 消息方法
	static Future<List<int>> _encodeMessage(_EncodeBundle bundle) async {
		var message = bundle._message;
		
		int count = bundle._encoderList.length;
		for (int i = 0; i < count; i++) {
			final encoder = bundle._encoderList[i];
			final oldMessage = message;
			message = encoder.encode(message);
			if (message == null) {
				message = oldMessage;
			}
		}
		
		return message;
	}
}

/// 用于包装需要编码的消息和编码器的数据集
class _EncodeBundle {
    const _EncodeBundle(this._message, this._encoderList);
	final dynamic _message;
	final List<HttpMessageEncoder> _encoderList;
}


/// 解析 Request 的 Response Body
/// 用于解析 Response Body，可选择进行代理和解码
mixin _ResponseBodyDecoder implements _RequestOperatorMixBase {
	/// 从 HttpClientRequest 中获取 HttpClientResponse，并读取其
	/// 全部 Byte 数据存入 List<int> 中
	/// 如果 Body 在处理过程中发生错误，则会直接返回 ErrorPassResponse，程序应直接将这个
	/// 结果返回
	/// 可以选择是否使用代理，编码
	/// 默认情况下，开始编码与代理
	Future<PassResponse> analyzeResponse(
		HttpClientRequest httpReq,
		ChainRequestModifier modifier,
		{ bool useDecode = true, bool useProxy = true }
	) async {
		HttpClientResponse httpResp = await httpReq.close();
		List<int> responseBody = List();
		await httpResp.forEach((byteList) {
			responseBody.addAll(byteList);
		});
		
		dynamic decodeObj = null;
		if(useDecode) {
			final decoders = _buildRequest._decoderList;
			// 存在编码器，进行编码
			if(decoders != null) {
				final bundle = _DecodeBundle(responseBody, _buildRequest._decoderList);
				if (useProxy) {
					decodeObj = await modifier.proxy(_decodeMessage, bundle);
				}
				else {
					decodeObj = await _decodeMessage(bundle);
				}
			}
		}
		
		return ProcessablePassResponse(httpResp, responseBody, decodeObj);
	}
	
	/// 实际 decode 消息方法
	static Future<dynamic> _decodeMessage(_DecodeBundle bundle) async {
		dynamic decoderMessage = bundle._message;
		List<HttpMessageDecoder> decoders = bundle._decoderList;
		
		int count = decoders.length;
		for(int i = 0 ; i < count ; i ++) {
			final decoder = decoders[i];
			decoderMessage = decoder.decode(decoderMessage);
			if(decoderMessage == null) {
				break;
			}
		}
		
		return decoderMessage;
	}
}

/// 用于包装需要解码的消息和解码器的数据集
class _DecodeBundle {
	const _DecodeBundle(this._message, this._decoderList);
	final dynamic _message;
	final List<HttpMessageDecoder> _decoderList;
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
		_RequestDecoderBuilder<Request>,
		/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter
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
		_RequestDecoderBuilder<RequestPrototype>,
		/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter
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
		/* 操作混合 */
		_RequestProxyRunner,
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter,
		_RequestHeaderFiller,
		_RequestBodyFiller,
		_ResponseBodyDecoder
{
	ChainRequestModifier(this._request);
	final Request _request;

	@override
	ChainRequestModifier get _returnObj => this;

	@override
	Request get _buildRequest => _request;
}