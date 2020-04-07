part of 'core.dart';

/*配置 Mixin 混合*/

/// 请求 id 配置混合
/// 用于配置 Request id
mixin _RequestIdBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置请求 id 方法
	/// 为当前请求设置 id
	/// * 请求 id 可以在任何时候设置
	/// * 需要注意的是，id 一经设置，不可更改
	ReturnType setRequestId(dynamic reqId) {
		_requestOptions.reqId ??= reqId;
		return returnObj;
	}
}

/// 请求运行代理配置混合
/// 用于配置 Request 运行代理
mixin _RequestRunProxyBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置执行请求的代理方法
	/// 应在代理接口中直接调用参数中的回调，不做其他任何操作
	ReturnType setRequestRunProxy(AsyncRunProxy proxy) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.runProxy = proxy;
		}
		
		return returnObj;
	}
}

/// 请求拦截器配置混合
/// 用于配置 Request 拦截器
mixin _RequestInterceptorBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 拦截器列表
	List<PassInterceptor> get _passInterceptors {
		if(_requestOptions.needCopyInterceptor) {
			if(_requestOptions.passInterceptorList != null) {
				_requestOptions.passInterceptorList = List.from(_requestOptions.passInterceptorList);
			}
			_requestOptions.needCopyInterceptor = false;
		}
		return _requestOptions.passInterceptorList ??= [];
	}
	
	/// 在首位添加拦截器
	/// 最后添加的拦截器最先被运行
	ReturnType addFirstInterceptor(PassInterceptor interceptor) {
		if (_requestOptions.checkPrepareStatus) {
			_passInterceptors.insert(0, interceptor);
		}
		return returnObj;
	}
}

/// 请求拦截器清空混合
/// 用于清空 Request 中所有的拦截器
mixin _RequestInterceptorClearBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 清空全部拦截器
	/// 注意的一点是，默认拦截器列表中存在 [BusinessPassInterceptor] 类作为基础的请求处理拦截器
	ReturnType clearInterceptors() {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.passInterceptorList = null;
		}
		return returnObj;
	}
}

/// 请求头部配置混合
/// 用于配置 Request 头部
mixin _RequestHeaderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {

	/// 头部表
	Map<String, String> get _header {
		if(_requestOptions.needCopyHeaderMap) {
			if(_requestOptions.headerMap != null) {
				_requestOptions.headerMap = Map.from(_requestOptions.headerMap);
			}
			_requestOptions.needCopyHeaderMap = false;
		}
		return _requestOptions.headerMap ??= {};
	}
	
	/// 设置请求头部
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeader(String key, String value) {
		if (key == null) return returnObj;
		if (_requestOptions.checkExecutingStatus) _header[key.toLowerCase()] = value;
		return returnObj;
	}
	
	/// 设置请求头部
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeaderByMap(Map<String, String> headerMap) {
		if (headerMap == null || headerMap.isEmpty) return returnObj;
		if (_requestOptions.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key.toLowerCase()] = value;
			});
		}
		return returnObj;
	}
	
	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeader(String key, String value) {
		if (key == null) return returnObj;
		if (_requestOptions.checkExecutingStatus) _header[key] = value;
		return returnObj;
	}
	
	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeaderByMap(Map<String, String> headerMap) {
		if (headerMap == null || headerMap.isEmpty) return returnObj;
		if (_requestOptions.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key] = value;
			});
		}
		return returnObj;
	}
}

/// 请求地址配置混合
/// 用于配置 Request Url
mixin _RequestUrlBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置请求地址
	ReturnType setUrl(String url) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.url = url;
			// Url 发生变化，需要重新解析
			_requestOptions.needResolved = true;
		}
		return returnObj;
	}
	
	/// 增加新的路径
	ReturnType addPath(String path) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.url += path;
			// Url 发生变化，需要重新解析
			_requestOptions.needResolved = true;
		}
		return returnObj;
	}
	
	/// 追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParams(String key, String value, {bool checkFirstParams = true, bool useEncode = true}) {
		if (_requestOptions.checkExecutingStatus) {
			if (key != null && key.isNotEmpty && value != null && value.isNotEmpty) {
				final realValue = useEncode ? Uri.encodeComponent('value') : value;
				
				if (checkFirstParams && _requestOptions.hasUrlParams == true) {
					_requestOptions.url += '?';
				} else {
					_requestOptions.url += '&';
				}
				_requestOptions.url += '$key=$realValue';
				// Url 发生变化，需要重新解析
				_requestOptions.needResolved = true;
				_requestOptions.hasUrlParams = true;
			}
		}
		return returnObj;
	}
	
	/// 以 Map 的形式追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParamsByMap(Map<String, String> map, {bool checkFirstParams = true, bool useEncode = true}) {
		if (_requestOptions.checkExecutingStatus) {
			if (map != null) {
				map.forEach((key, value) {
					appendQueryParams(key, value, checkFirstParams: checkFirstParams, useEncode: useEncode);
				});
			}
		}
		return returnObj;
	}
}

/// 请求方法配置混合
/// 用于配置 Request Method
mixin _RequestMethodBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置 GET 请求
	ReturnType GET() {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.customRequestMethod = null;
			_requestOptions.requestMethod = RequestMethod.GET;
			_requestOptions.body = null;
		}
		return returnObj;
	}
	
	/// 设置 POST 请求
	/// body 不能为 `null`
	ReturnType POST(dynamic body) {
		if (_requestOptions.checkExecutingStatus && body != null) {
			_requestOptions.customRequestMethod = null;
			_requestOptions.requestMethod = RequestMethod.POST;
			_requestOptions.body = body;
		}
		return returnObj;
	}
	
	/// 设置自定义请求方法
	/// 可以选择是否传送 body
	ReturnType CUSTOM(String method, {dynamic body}) {
		if (_requestOptions.checkExecutingStatus && body != null) {
			_requestOptions.customRequestMethod = method;
			_requestOptions.requestMethod = RequestMethod.CUSTOM;
			_requestOptions.body = body;
		}
		return returnObj;
	}
}

/// 请求编码器配置混合
/// 用于配置 Request Encoders
mixin _RequestEncoderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 编码器列表
	List<HttpMessageEncoder> get _encoders {
		if(_requestOptions.needCopyEncoderList) {
			if(_requestOptions.encoderList != null) {
				_requestOptions.encoderList = List.from(_requestOptions.encoderList);
			}
			_requestOptions.needCopyEncoderList = false;
		}
		return _requestOptions.encoderList ??= [];
	}
	
	/// 添加编码器
	/// 新添加的编码器会追加到首位
	/// 建议最好使用 [addLastEncoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstEncoder(HttpMessageEncoder encoder) {
		if (_requestOptions.checkExecutingStatus) {
			_encoders.insert(0, encoder);
		}
		return returnObj;
	}
	
	/// 添加编码器
	/// 新添加的编码器会追加到末位
	ReturnType addLastEncoder(HttpMessageEncoder encoder) {
		if (_requestOptions.checkExecutingStatus) {
			_encoders.add(encoder);
		}
		return returnObj;
	}
	
	/// 清空编码器
	ReturnType clearEncoder() {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.encoderList = null;
		}
		return returnObj;
	}
	
	/// 遍历编码器
	/// 返回 false，中断遍历
	void forEachEncoder(ForeachCallback<HttpMessageEncoder> callback) {
		if (_requestOptions.encoderList != null) {
			var count = _requestOptions.encoderList.length;
			for (var i = 0; i < count; i++) {
				final encoder = _requestOptions.encoderList[i];
				if (!callback(encoder)) {
					break;
				}
			}
		}
	}
}

/// 请求解码器配置混合
/// 用于配置 Request Decoders
mixin _RequestDecoderBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {

	/// 解码器列表
	List<HttpMessageDecoder> get _decoders {
		if(_requestOptions.needCopyDecoderList) {
			if(_requestOptions.decoderList != null) {
				_requestOptions.decoderList = List.from(_requestOptions.decoderList);
			}
			_requestOptions.needCopyDecoderList = false;
		}
		return _requestOptions.decoderList ??= [];
	}
	
	/// 添加解码器
	/// 新添加的解码器会追加到首位
	/// 建议最好使用 [addLastDecoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstDecoder(HttpMessageDecoder decoder) {
		if (_requestOptions.checkExecutingStatus) {
			_decoders.insert(0, decoder);
		}
		return returnObj;
	}
	
	/// 添加解码器
	/// 新添加的解码器会追加到末位
	ReturnType addLastDecoder(HttpMessageDecoder decoder) {
		if (_requestOptions.checkExecutingStatus) {
			_decoders.add(decoder);
		}
		return returnObj;
	}
	
	/// 清空解码器
	ReturnType clearDecoder() {
		if (_requestOptions.checkExecutingStatus) _requestOptions.decoderList = null;
		return returnObj;
	}
	
	/// 遍历解码器
	/// 返回 false，中断遍历
	void forEachDecoder(ForeachCallback<HttpMessageDecoder> callback) {
		if (_requestOptions.decoderList != null) {
			final count = _requestOptions.decoderList.length;
			for (var i = 0; i < count; i++) {
				final decoder = _requestOptions.decoderList[i];
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
		if (_requestOptions.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
		}
		return returnObj;
	}
	
	/// 配置 `json` 编解码器，形成 json 通道
	/// 该方法会将之前全部编解码器清空
	ReturnType jsonChannel() {
		if (_requestOptions.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastEncoder(const JSON2Utf8StringEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
			addLastDecoder(const Utf8String2JSONDecoder());
		}
		return returnObj;
	}
}

/// 请求响应数据接收进度回调接口配置
/// 可以用来通知当前响应数据接收进度
mixin _RequestResponseDataUpdateBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 响应数据更新回调列表
	List<HttpResponseDataUpdateCallback> get _responseDataUpdates {
		if(_requestOptions.needCopyResponseDataUpdateList) {
			if(_requestOptions.responseDataUpdateList != null) {
				_requestOptions.responseDataUpdateList = List.from(_requestOptions.responseDataUpdateList);
			}
			_requestOptions.needCopyResponseDataUpdateList = false;
		}
		return _requestOptions.responseDataUpdateList ??= [];
	}
	
	/// 添加新的回调
	/// 每当接收数据更新时，都会触发该回调接口，来通知当前数据获取的进度
	ReturnType addResponseDataUpdate(HttpResponseDataUpdateCallback callback) {
		if (_requestOptions.checkPrepareStatus) {
			_responseDataUpdates.add(callback);
		}
		return returnObj;
	}
}

/// 请求响应数据接收回调接口配置
/// 可以直接用来接收响应的原始数据
/// * 一旦设置该回调，就不再执行解码逻辑，默认执行响应数据处理的方法将会从 [ResponseBodyDecoder.analyzeResponse]
/// * 切换至 [ResponseBodyDecoder.analyzeResponseByReceiver]
mixin _RequestResponseDataReceiverBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 配置接收响应报文原始数据接口
	ReturnType setResponseRawDataReceiverCallback(HttpResponseRawDataReceiverCallback callback) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.responseReceiverCallback = callback;
		}
		return returnObj;
	}
	
	/// 判断是否存在接收响应报文原始数据接口
	bool existResponseRawDataReceiverCallback() => _requestOptions.responseReceiverCallback != null;
}

/// 请求中断配置
/// 可以立即中断并返回给定的响应结果
mixin _RequestCloserBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	
	/// 请求中断器列表
	Set<RequestCloser> get _requestClosers {
		if(_requestOptions.needCopyRequestCloserList) {
			if(_requestOptions.requestCloserSet != null) {
				_requestOptions.requestCloserSet = Set.from(_requestOptions.requestCloserSet);
			}
			_requestOptions.needCopyRequestCloserList = false;
		}
		return _requestOptions.requestCloserSet ??= <RequestCloser>{};
	}
	
	/// 添加请求中断器
	ReturnType addRequestCloser(RequestCloser requestCloser) {
		if (_requestOptions.checkExecutingStatus) {
			_requestClosers.add(requestCloser);
		}
		return returnObj;
	}
	
	/// 遍历编码器
	/// 返回 false，中断遍历
	void forEachRequestCloser(ForeachCallback2<RequestCloser> callback) {
		if (_requestOptions.requestCloserSet != null) {
			_requestOptions.requestCloserSet.forEach(callback);
		}
	}
}

/// 请求 Http 代理配置混合
/// 用来配置请求 Http 代理
mixin _RequestHttpProxyBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {

	/// 请求代理列表
	List<PassHttpProxy> get _httpProxies {
		if(_requestOptions.needCopyHttpProxyList) {
			if(_requestOptions.httpProxyList != null) {
				_requestOptions.httpProxyList = List.from(_requestOptions.httpProxyList);
			}
			_requestOptions.needCopyHttpProxyList = false;
		}
		return _requestOptions?.httpProxyList ??= [];
	}
	
	/// 添加请求 Http 代理
	ReturnType addHttpProxy(String host, int port) {
		if (_requestOptions.checkExecutingStatus) {
			final proxy = PassHttpProxy(host, port);
			if (!_httpProxies.contains(proxy)) {
				_httpProxies.add(proxy);
			}
		}
		
		return returnObj;
	}
	
	/// 移除指定的请求 Http 代理
	ReturnType removeHttpProxy(String host, int port) {
		if (_requestOptions.checkExecutingStatus && _requestOptions.httpProxyList != null) {
			final proxy = PassHttpProxy(host, port);
			_httpProxies.remove(proxy);
			if (_httpProxies.isEmpty) {
				_requestOptions.httpProxyList = null;
			}
		}
		
		return returnObj;
	}
	
	/// 移除全部相同 host 的请求 Http 代理
	ReturnType removeHttpProxyByHost(String host) {
		if (_requestOptions.checkExecutingStatus && _requestOptions.httpProxyList != null) {
			_httpProxies.removeWhere((proxy) {
				return proxy.host == host;
			});
			if (_httpProxies.isEmpty) {
				_requestOptions.httpProxyList = null;
			}
		}
		
		return returnObj;
	}
}

/// 配置请求总超时时间
/// 用于配置请求超时时间
mixin _RequestTotalTimeoutBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置请求总超时时间
	/// 包括拦截器处理耗时也会计算到其中
	ReturnType setTotalTimeOut(Duration timeOut) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.totalTimeout = timeOut;
		}
		return returnObj;
	}
}

/// 配置请求连接超时时间
/// 用于配置请求连接超时时间
mixin _RequestTimeoutBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {
	/// 设置连接超时时间
	ReturnType setConnectTimeOut(Duration timeOut) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.connectTimeout = timeOut;
		}
		return returnObj;
	}
	
	/// 设置读取超时时间
	ReturnType setReadTimeOut(Duration timeOut) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.readTimeout = timeOut;
		}
		return returnObj;
	}
}


/// 配置 PassHttpClient
/// 当配置了 PassHttpClient 时，以下几种配置将失效:
/// - 配置请求总超时时间
/// - 配置请求连接超时时间
/// - 配置请求 Http 代理
///
/// 如需配置以上内容，则要自行在 PassHttpClient 中设置
///
mixin _RequestClientBuilder<ReturnType> implements _RequestMixinBase<ReturnType> {

	/// 设置 PassHttpClient
	ReturnType setHttpClient(PassHttpClient client) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.passHttpClient = client;
		}
		return returnObj;
	}
}