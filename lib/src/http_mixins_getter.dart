part of 'http.dart';

/// 获取请求 id 配置混合
mixin _RequestIdGetter implements _RequestOperatorMixBase {
	/// 获取当前请求设置的 id 信息
	dynamic getReqId() {
		return _buildRequest._reqId;
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
	PassResolveUrl getResolverUrl() {
		if (_buildRequest._needResolved != false) {
			_buildRequest._needResolved = false;
			_buildRequest._resolveUrl = PassHttpUtils.resolveUrl(_buildRequest._url);
		}
		return _buildRequest._resolveUrl;
	}
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
	void forEachRequestHeaders(HttpHeaderForeachCallback callback) {
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

/// 获取请求 Http 代理配置混合
mixin _RequestProxyGetter implements _RequestOperatorMixBase {
	/// 获取指定 Host 下全部的请求 Http 代理
	List<PassHttpProxy> getPassHttpProxiesByHost(String host) {
		List<PassHttpProxy> list;
		if (_buildRequest._httpProxyList != null) {
			_buildRequest._httpProxyList.forEach((proxy) {
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
		return List.from(_buildRequest._httpProxyList);
	}
	
	/// 遍历请求 Http 代理
	void forEachPassHttpProxies(ForeachCallback<PassHttpProxy> callback) {
		if (_buildRequest._httpProxyList != null) {
			final proxyList = _buildRequest._httpProxyList;
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
		return _buildRequest._totalTimeout;
	}
	
	/// 获取请求连接超时时间
	Duration getConnectTimeout() {
		return _buildRequest._connectTimeout;
	}
	
	/// 获取请求读取超时时间
	Duration getReadTimeout() {
		return _buildRequest._readTimeout;
	}
}