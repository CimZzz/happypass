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
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeader(String key, String value) {
		if(key == null)
			return _returnObj;
		if (_buildRequest.checkExecutingStatus) _header[key.toLowerCase()] = value;
		return _returnObj;
	}
	
	/// 设置请求头部
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeaderByMap(Map<String, String> headerMap) {
		if(headerMap == null || headerMap.isEmpty)
			return _returnObj;
		if (_buildRequest.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key.toLowerCase()] = value;
			});
		}
		return _returnObj;
	}

	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeader(String key, String value) {
		if(key == null)
			return _returnObj;
		if (_buildRequest.checkExecutingStatus) _header[key] = value;
		return _returnObj;
	}
	
	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeaderByMap(Map<String, String> headerMap) {
		if(headerMap == null || headerMap.isEmpty)
			return _returnObj;
		if (_buildRequest.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key] = value;
			});
		}
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

	/// 增加新的路径
	ReturnType addPath(String path) {
		if (_buildRequest.checkExecutingStatus) {
			_buildRequest._url += path;
		}
		return _returnObj;
	}

	/// 追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParams(String key, String value, {bool checkFirstParams = true, bool useEncode = true}) {
		if (_buildRequest.checkExecutingStatus) {
			if (key != null && key.isNotEmpty && value != null && value.isNotEmpty) {
				final realValue = useEncode ? Uri.encodeComponent("value") : value;

				if (checkFirstParams && !_buildRequest._hasUrlParams) {
					_buildRequest._url += "?";
				} else {
					_buildRequest._url += "&";
				}
				_buildRequest._url += "$key=$realValue";
				_buildRequest._hasUrlParams = true;
			}
		}
		return _returnObj;
	}

	/// 以 Map 的形式追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParamsByMap(Map<String, String> map, {bool checkFirstParams = true, bool useEncode = true}) {
		if(_buildRequest.checkExecutingStatus) {
			if(map != null) {
				map.forEach((key, value) {
					appendQueryParams(key, value, checkFirstParams: checkFirstParams, useEncode: useEncode);
				});
			}
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
	/// 建议最好使用 [addLastEncoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstEncoder(HttpMessageEncoder encoder) {
		if (_buildRequest.checkExecutingStatus) {
			_encoders.insert(0, encoder);
		}
		return _returnObj;
	}

	/// 添加编码器
	/// 新添加的编码器会追加到末位
	ReturnType addLastEncoder(HttpMessageEncoder encoder) {
		if (_buildRequest.checkExecutingStatus) {
			_encoders.add(encoder);
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
	/// 新添加的解码器会追加到首位
	/// 建议最好使用 [addLastDecoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstDecoder(HttpMessageDecoder decoder) {
		if (_buildRequest.checkExecutingStatus) {
			_decoders.insert(0, decoder);
		}
		return _returnObj;
	}

	/// 添加解码器
	/// 新添加的解码器会追加到末位
	ReturnType addLastDecoder(HttpMessageDecoder decoder) {
		if (_buildRequest.checkExecutingStatus) {
			_decoders.add(decoder);
		}
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


/// 请求加密配置快捷混合
/// 可以帮助我们便捷的配置常用的编解码器
mixin _RequestChannelBuilder<ReturnType> implements _RequestDecoderBuilder<ReturnType>, _RequestEncoderBuilder<ReturnType> {

	/// 配置 `utf8` 字符串编解码器，形成字符串通道
	/// 该方法会将之前全部编解码器清空
	ReturnType stringChannel() {
		if (_buildRequest.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
		}
		return _returnObj;
	}


	/// 配置 `json` 编解码器，形成 json 通道
	/// 该方法会将之前全部编解码器清空
	ReturnType jsonChannel() {
		if (_buildRequest.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastEncoder(const JSON2Utf8StringEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
			addLastDecoder(const Utf8String2JSONDecoder());
		}
		return _returnObj;
	}
}

/// 请求响应数据接收进度回调接口配置
/// 可以用来通知当前响应数据接收进度
mixin _RequestResponseDataUpdateBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	List<HttpResponseDataUpdateCallback> get _responseDataUpdates {
		return _buildRequest._responseDataUpdateList ??= List();
	}
	
	/// 添加新的回调
	/// 每当接收数据更新时，都会触发该回调接口，来通知当前数据获取的进度
	ReturnType addResponseDataUpdate(HttpResponseDataUpdateCallback callback) {
		if(_buildRequest.checkPrepareStatus) {
			_responseDataUpdates.add(callback);
		}
		return _returnObj;
	}
}

/// 请求响应数据接收回调接口配置
/// 可以直接用来接收响应的原始数据
/// * 一旦设置该回调，就不再执行解码逻辑，默认执行响应数据处理的方法将会从 [_ResponseBodyDecoder.analyzeResponse]
/// * 切换至 [_ResponseBodyDecoder.analyzeResponseByReceiver]
mixin _RequestResponseDataReceiverBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 配置接收响应报文原始数据接口
	ReturnType setResponseRawDataReceiverCallback(HttpResponseRawDataReceiverCallback callback) {
		if(_buildRequest.checkPrepareStatus) {
			_buildRequest._responseReceiverCallback = callback;
		}
		return _returnObj;
	}
	
	/// 判断是否存在接收响应报文原始数据接口
	bool existResponseRawDataReceiverCallback() => _buildRequest._responseReceiverCallback != null;
}

/// 请求中断配置
/// 可以立即中断并返回给定的响应结果
mixin _RequestCloserBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 配置请求中断器
	ReturnType setRequestCloser(RequestCloser requestCloser) {
		if(_buildRequest.checkExecutingStatus) {
			this._buildRequest._requestCloser = requestCloser;
		}
		return _returnObj;
	}
}

/// 请求 Cookie Manager 配置
/// 用来配置 Cookie Manager
mixin _RequestCookieManagerBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 配置请求中断器
	ReturnType setCookieManager(CookieManager cookieManager) {
		if(_buildRequest.checkExecutingStatus) {
			this._buildRequest._cookieManager = cookieManager;
		}
		return _returnObj;
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
		if (runProxy != null) {
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

	/// 获取 Url 转换过的 HttpUrl 对象
	HttpUrl getHttpUrl() => HttpUtils.resolveUrl(_buildRequest._url);
}

/// 获取请求 Url 配置混合
/// 用于获取 Request 的请求 Url
mixin _RequestHeaderGetter implements _RequestOperatorMixBase {
	/// 获取请求头部
	/// 该方法会将 `Key` 值转化为小写形式
	String getRequestHeader(String key) => key != null ? _buildRequest?._headerMap[key.toLowerCase()] : null;

	/// 获取请求头部
	/// 该方法保留 `Key` 值的大小写形式
	String getCustomRequestHeader(String key) => key != null ? _buildRequest?._headerMap[key] : null;

	/// 遍历请求头
	void forEachRequestHeaders(void callback(String key, String value)) {
		if (_buildRequest._headerMap != null) {
			_buildRequest._headerMap.forEach((String key, String value) => callback(key, value));
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
	void fillRequestHeader(HttpClientRequest httpReq, ChainRequestModifier modifier, {bool useProxy = true}) async {
		final headers = modifier._request._headerMap;
		if (headers != null && headers.isNotEmpty) {
			final bundle = _HeaderBundle(httpReq, headers);
			if (useProxy) {
				await modifier.proxy(_fillHeaders, bundle);
			} else {
				await _fillHeaders(bundle);
			}
		}
	}

	static Future _fillHeaders(_HeaderBundle bundle) async {
		final httpReq = bundle._request;
		final headers = bundle._requestHeaders;
		if (headers != null && headers.isNotEmpty) {
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
	/// 默认情况下，使用编码与代理
	Future<PassResponse> fillRequestBody(HttpClientRequest httpReq, ChainRequestModifier modifier, {bool useEncode = true, bool useProxy = true}) async {
		// 目前只有 POST 方法会发送请求体
		if (_buildRequest._requestMethod != RequestMethod.POST) {
			return null;
		}
		dynamic body = _buildRequest._body;
		// POST 方法的 body 不能为 null
		if (body == null) {
			return ErrorPassResponse(msg: "[POST] \"body\" 不能为 \"null\"");
		}

		if(body is RequestBody) {
			// 当请求体是 RequestBody 时
			RequestBody requestBody = body;
			String contentType = requestBody.contentType;
			if(contentType != null) {
				bool overrideContentType = requestBody.overrideContentType;
				if(overrideContentType == true || httpReq.headers.value("content-type") == null) {
					httpReq.headers.set("content-type", contentType);
				}
			}

			await for(var message in body.provideBodyData()) {
				if(message is RawBodyData) {
					message = message.rawData;
				}
				else if (useEncode) {
					final encoders = _buildRequest._encoderList;
					// 存在编码器，进行编码
					if (encoders != null) {
						final bundle = _EncodeBundle(message, _buildRequest._encoderList);
						if (useProxy) {
							message = await modifier.proxy(_encodeMessage, bundle);
						} else {
							message = await _encodeMessage(bundle);
						}
					}
				}

				if (message is! List<int>) {
					return ErrorPassResponse(msg: "[POST] 最后的编码结果类型不为 \"List<int>\"");
				}

				httpReq.add(message);

				message = await body.provideBodyData();
			}

		}
		else {
			// 当请求体不是 RequestBody 时
			dynamic message = body;
			if (useEncode) {
				final encoders = _buildRequest._encoderList;
				// 存在编码器，进行编码
				if (encoders != null) {
					final bundle = _EncodeBundle(message, _buildRequest._encoderList);
					if (useProxy) {
						message = await modifier.proxy(_encodeMessage, bundle);
					} else {
						message = await _encodeMessage(bundle);
					}
				}
			}

			if (message is! List<int>) {
				return ErrorPassResponse(msg: "[POST] 最后的编码结果类型不为 \"List<int>\"");
			}

			httpReq.add(message);
		}




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
	/// - useDecode: 表示是否使用解码器处理数据
	/// - useProxy: 表示使用使用请求执行代理来解码数据
	/// - doNotify: 表示是否通知响应数据接收进度
	Future<PassResponse> analyzeResponse(
		HttpClientRequest httpReq,
		ChainRequestModifier modifier,
		{
			bool useDecode = true,
			bool useProxy = true,
			bool doNotify = true
		}) async {
		HttpClientResponse httpResp = await httpReq.close();
		// 存储 Cookie
		modifier.storeCookies(modifier.getUrl(), httpResp.cookies);
		// 标记当前请求已经执行完成
		modifier.markRequestExecuted();
		List<int> responseBody = List();
		if(doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final contentLengthList = httpResp.headers["content-length"];
			int totalLength = -1;
			if (contentLengthList?.isNotEmpty == true) {
				totalLength = int.tryParse(contentLengthList[0]) ?? -1;
			}
			int curLength = 0;
			// 接收之前先触发一次空进度通知
			modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
			await httpResp.forEach((byteList) {
				responseBody.addAll(byteList);
				// 每当接收到新数据时，进行通知更新
				curLength += byteList.length;
				modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
			});
		}
		else {
			// 不进行通知，直接获取响应数据
			await httpResp.forEach((byteList) {
				responseBody.addAll(byteList);
			});
		}

		dynamic decodeObj = null;
		if (useDecode) {
			final decoders = _buildRequest._decoderList;
			// 存在编码器，进行编码
			if (decoders != null) {
				final bundle = _DecodeBundle(responseBody, _buildRequest._decoderList);
				if (useProxy) {
					decodeObj = await modifier.proxy(_decodeMessage, bundle);
				} else {
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
		for (int i = 0; i < count; i++) {
			final decoder = decoders[i];
			decoderMessage = decoder.decode(decoderMessage);
			if (decoderMessage == null) {
				break;
			}
		}

		return decoderMessage;
	}
	
	
	/// 从 HttpClientRequest 中获取 HttpClientResponse，并读取其
	/// 全部 Byte 数据全部传输到 [HttpResponseRawDataReceiverCallback] 中处理
	/// 如果 Body 在处理过程中发生错误，则会直接返回 ErrorPassResponse，程序应直接将这个
	/// 结果返回
	/// - doNotify: 表示是否通知响应数据接收进度
	Future<PassResponse> analyzeResponseByReceiver(
		HttpClientRequest httpReq,
		ChainRequestModifier modifier,
		{
			bool doNotify = true
		}
	) async {
		HttpClientResponse httpResp = await httpReq.close();
		// 存储 Cookie
		modifier.storeCookies(modifier.getUrl(), httpResp.cookies);
		Stream<List<int>> rawByteDataStream;
		// 标记当前请求已经执行完成
		modifier.markRequestExecuted();
		if(doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final contentLengthList = httpResp.headers["content-length"];
			int totalLength = -1;
			if (contentLengthList?.isNotEmpty == true) {
				totalLength = int.tryParse(contentLengthList[0]) ?? -1;
			}
			int curLength = 0;
			// 接收之前先触发一次空进度通知
			modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
			Stream<List<int>> rawByteStreamWrap(Stream<List<int>> rawStream) async* {
				await for(var byteList in rawStream) {
					// 每当接收到新数据时，进行通知更新
					curLength += byteList.length;
					modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
					yield byteList;
				}
			}
			rawByteDataStream = rawByteStreamWrap(httpResp.asBroadcastStream());
		}
		else {
			// 不进行通知，直接获取响应数据
			rawByteDataStream = httpResp.asBroadcastStream();
		}
		
		PassResponse passResponse;
		final result = await modifier.transferRawDataForRawDataReceiver(rawByteDataStream);
		
		if(result is PassResponse) {
			passResponse = result;
		}
		else {
			passResponse = ProcessablePassResponse(httpResp, null, result);
		}
		
		// 如果接收完毕但没有返回应有的响应对象，那么会返回一个 `ErrorPassResponse` 表示处理出错
		return passResponse;
	}
}

/// 用于包装需要解码的消息和解码器的数据集
class _DecodeBundle {
	const _DecodeBundle(this._message, this._decoderList);

	final dynamic _message;
	final List<HttpMessageDecoder> _decoderList;
}


/// 通知当前 Response Body 接收进度
/// 用于解析 Response Body，可选择进行代理和解码
mixin _ResponseDataUpdate implements _RequestOperatorMixBase {
	
	/// 通知相应数据接收进度
	/// 每当接收到新的数据时，都应触发该方法
	/// 如果总长度未知，则不应传总长度参数
	void notifyResponseDataUpdate(int length, {int totalLength = -1}) {
		// 除非总长度总长度未知，否则接收的数据长度不应超过总长度
		if(length > totalLength && totalLength != -1) {
			throw Exception("recv length over total length");
		}
		
		_buildRequest._responseDataUpdateList?.forEach((callback){
			callback(length, totalLength);
		});
	}
}

/// 直接传输 Request 的 Response Body 数据
/// 从响应中获取数据，不做任何处理交给接收响应原始数据回调处理
mixin _ResponseRawDataTransfer implements _RequestOperatorMixBase {
	
	/// 调用接收响应原始数据接口，将 Future 直接返回
	/// 该方法并未在执行代理中执行
	Future<dynamic> transferRawDataForRawDataReceiver(Stream<List<int>> rawDataStream) {
		return this._buildRequest._responseReceiverCallback(rawDataStream);
	}
}



/// 切换当前请求状态为已执行
/// 按照规范，当 `HttpClientRequest` 执行完 `close` 方法后，
/// 应该主动调用该方法，以防止一些请求前的配置信息遭到修改
mixin _RequestExecutedChanger implements _RequestOperatorMixBase {
	
	/// 将当前请求状态标记为已执行
	void markRequestExecuted() {
		_buildRequest._status = _RequestStatus.Executed;
	}
}

/// 中断请求
/// 可以强制中断请求结束，并返回指定的响应结果
mixin _RequestClose {
	/// 判断当前请求是否已经结束
	bool _isClosed = false;
	bool get isClosed => this._isClosed || _finishResponse != null;
	
	/// 用来承载在请求中断的中断结果
	ResultPassResponse _finishResponse;
	/// 用来中断的 `HttpClient`
	HttpClient _client;
	/// 用来执行实际处理逻辑的 Completer
	Completer<PassResponse> _realBusinessCompleter = Completer();
	/// 用来处理内部中断逻辑的 Completer
	/// 保证在调用 `close` 之后可以立即返回响应数据
	Completer<PassResponse> _innerCompleter = Completer();
	/// 内部 Completer 的流订阅
	StreamSubscription<PassResponse> _innerSubscription;
	
	/// 代理执行请求逻辑
	/// 大致流程如下:
	///
	/// A ----- C
	///         |
	/// B -------
	///
	/// A - 表示实际请求处理逻辑
	/// B - 表示中断逻辑
	/// C - 表示最后返回的处理结果
	/// A 或 B 首先触发的一方任意结果都会成为 C 的最终结果
	FutureOr<PassResponse> _requestProxy(Future<PassResponse> realFuture) {
		if(_finishResponse != null) {
			return _finishResponse;
		}
		_realBusinessCompleter = Completer();
		_innerCompleter = Completer();
		_innerSubscription = _realBusinessCompleter.future.asStream().listen((data) {
			this._innerCompleter.complete(data);
		});
		_realBusinessCompleter.complete(realFuture);
		return this._innerCompleter.future;
	}
	
	/// 装配 HttpClient，用来强制中断逻辑
	void assembleHttpClient(HttpClient client) {
		this._client = client;
		if(this._isClosed) {
			client.close(force: true);
		}
	}
	
	/// 强制中断当前请求
	/// - finishResponse: 中断请求所返回的最终响应结果
	void close({ResultPassResponse finishResponse = const ErrorPassResponse(msg: "request interrupted!")}) {
		this._client?.close(force: true);
		this._innerCompleter?.complete(finishResponse);
	}
	
	/// 清理当前所持有的引用和状态
	void _finish() {
		_isClosed = true;
		_finishResponse = null;
		_innerSubscription?.cancel();
		_innerSubscription = null;
		_innerCompleter = null;
		_realBusinessCompleter = null;
		_client = null;
	}
}

/// 用来将 HttpClientResponse 中的 Cookies 保存到 CookieManager
mixin _ResponseCookieManager implements _RequestOperatorMixBase {
	
	/// 缓存 Cookie
	/// 将 Url 和 Cookie 交给 CookieManager 来存储
	void storeCookies(String url, List<Cookie> cookies) {
		if(url == null || cookies == null || _buildRequest._cookieManager == null) {
			return;
		}
		
		final httpUrl = HttpUtils.resolveUrl(url);
		if(httpUrl == null) {
			return;
		}
		
		_buildRequest._cookieManager.storeCookies(httpUrl, cookies);
	}
	
	/// 根据给定的 Url，从 CookieManager 中获取 Cookie
	List<Cookie> getCookies(String url) {
		if(url == null || _buildRequest._cookieManager == null) {
			return null;
		}
		
		final httpUrl = HttpUtils.resolveUrl(url);
		if(httpUrl == null) {
			return null;
		}
		
		return _buildRequest._cookieManager.getCookies(httpUrl);
	}
}

/*组合 Mixin 基类*/

/// 请求基类
abstract class _BaseRequest
	with
		_RequestMixinBase<Request>,
		_RequestRunProxySetBuilder<Request>,
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
/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter,
		_RequestBodyGetter {
	@override
	Request get _returnObj => this;

	@override
	Request get _buildRequest => this;
}

/// 请求原型基类(原型基类应为 `static` 类型供全局共享)
/// 原型不能构造请求方法，防止因为持有大量请求体 (body) 而导致内存问题
/// 原型不能构造请求数据更新进度接口，防止持有大量引用导致内存问题
abstract class _BaseRequestPrototype<RequestPrototype>
	with
		_RequestMixinBase<RequestPrototype>,
		_RequestRunProxySetBuilder<RequestPrototype>,
		_RequestInterceptorBuilder<RequestPrototype>,
		_RequestInterceptorClearBuilder<RequestPrototype>,
		_RequestHeaderBuilder<RequestPrototype>,
		_RequestUrlBuilder<RequestPrototype>,
		_RequestEncoderBuilder<RequestPrototype>,
		_RequestDecoderBuilder<RequestPrototype>,
		_RequestChannelBuilder<RequestPrototype>,
		_RequestCookieManagerBuilder<RequestPrototype>,
	/* 操作混合 */
		_RequestUrlGetter,
		_RequestMethodGetter,
		_RequestHeaderGetter {}

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
	/* 操作混合 */
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
		_ResponseCookieManager {
	ChainRequestModifier(this._request);

	final Request _request;

	@override
	ChainRequestModifier get _returnObj => this;

	@override
	Request get _buildRequest => _request;
}

