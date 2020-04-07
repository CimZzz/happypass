part of 'core.dart';

/// 获取请求 id 配置混合
mixin _RequestIdGetter implements _RequestOperatorMixBase {
	/// 获取当前请求设置的 id 信息
	dynamic getReqId() {
		return _requestOptions.reqId;
	}
}

/// 获取请求方法配置混合
/// 用于获取 Request 的请求方法
mixin _RequestMethodGetter implements _RequestOperatorMixBase {
	/// 获取当前的请求方法
	RequestMethod getRequestMethod() {
		return _requestOptions.requestMethod;
	}
	
	/// 获取自定义的请求方法
	String getCustomRequestMethod() => _requestOptions.customRequestMethod;
}

/// 获取请求 Url 配置混合
/// 用于获取 Request 的请求 Url
mixin _RequestUrlGetter implements _RequestOperatorMixBase {
	/// 获取请求地址
	String getUrl() => _requestOptions.url;
	
	/// 获取 Url 转换过的 HttpUrl 对象
	PassResolveUrl getResolverUrl() {
		if (_requestOptions.needResolved != false) {
			_requestOptions.needResolved = false;
			_requestOptions.resolveUrl = PassHttpUtils.resolveUrl(_requestOptions.url);
		}
		return _requestOptions.resolveUrl;
	}
}

/// 获取请求 Url 配置混合
/// 用于获取 Request 的请求 Url
mixin _RequestHeaderGetter implements _RequestOperatorMixBase {
	/// 获取请求头部
	/// 该方法会将 `Key` 值转化为小写形式
	String getRequestHeader(String key) => key != null ? _requestOptions?.headerMap[key.toLowerCase()] : null;
	
	/// 获取请求头部
	/// 该方法保留 `Key` 值的大小写形式
	String getCustomRequestHeader(String key) => key != null ? _requestOptions?.headerMap[key] : null;
	
	/// 遍历请求头
	void forEachRequestHeaders(HttpHeaderForeachCallback callback) {
		if (_requestOptions.headerMap != null) {
			_requestOptions.headerMap.forEach((String key, String value) => callback(key, value));
		}
	}
}


/// 获取请求体配置混合
/// 用于获取 Request 的请求 Body
mixin _RequestBodyGetter implements _RequestOperatorMixBase {
	/// 获取当前的请求 Body（只在 Post 方法下存在该值）
	dynamic getRequestBody() {
		return _requestOptions.body;
	}
}

/// 获取请求 Http 代理配置混合
mixin _RequestProxyGetter implements _RequestOperatorMixBase {
	/// 获取指定 Host 下全部的请求 Http 代理
	List<PassHttpProxy> getPassHttpProxiesByHost(String host) {
		List<PassHttpProxy> list;
		if (_requestOptions.httpProxyList != null) {
			_requestOptions.httpProxyList.forEach((proxy) {
				if (proxy.host == host) {
					list ??= [];
					list.add(proxy);
				}
			});
		}
		
		return list;
	}
	
	/// 获取全部请求 Http 代理
	List<PassHttpProxy> getPassHttpProxies() {
		if(_requestOptions.httpProxyList != null) {
			return List.from(_requestOptions.httpProxyList);
		}
		else {
			return null;
		}
	}
	
	/// 遍历请求 Http 代理
	void forEachPassHttpProxies(ForeachCallback<PassHttpProxy> callback) {
		if (_requestOptions.httpProxyList != null) {
			final proxyList = _requestOptions.httpProxyList;
			final count = proxyList.length;
			for (var i = 0; i < count; i ++) {
				if (!callback(proxyList[i])) {
					break;
				}
			}
		}
	}
}


/// 获取 Request 超时时间混合
mixin _RequestTimeoutGetter implements _RequestOperatorMixBase {
	/// 获取请求连接超时时间
	/// 包括拦截器处理耗时也会计算到其中
	Duration getTotalTimeout() {
		return _requestOptions.totalTimeout;
	}
	
	/// 获取请求连接超时时间
	Duration getConnectTimeout() {
		return _requestOptions.connectTimeout;
	}
	
	/// 获取请求读取超时时间
	Duration getReadTimeout() {
		return _requestOptions.readTimeout;
	}
}

/// 获取 PassHttpClient 混合
mixin _RequestClientGetter implements _RequestOperatorMixBase {

	/// 获取 PassHttpClient
	/// 仅返回配置的 HttpClient
	PassHttpClient getHttpClient() {
		return _requestOptions.passHttpClient;
	}
}

/// 获取请求拦截器配置混合
mixin _RequestInterceptorsGetter implements _RequestOperatorMixBase {

	/// 获取请求拦截器
	List<PassInterceptor> getPassInterceptors() {
		return List.from(_requestOptions.passInterceptorList);
	}

	/// 获取请求拦截器数量
	int getPassInterceptorCount() => _requestOptions.passInterceptorList?.length ?? 0;
}