/// Http Url
/// 将 url 解析成一系列组成部分
class PassResolveUrl {
	PassResolveUrl({this.url, this.protocol, this.host, this.domain, this.port, this.path, this.queryParams});

	final String url;
	final String protocol;
	final String domain;
	final String host;
	final int port;
	final String path;
	final String queryParams;

	@override
	String toString() {
		return 'url: $url, domain: $domain, host: $host, port: $port, path: $path, queryParams: $queryParams';
	}
}

/// 终止解析对象
final Object _stopResolveObj = Object();

/// 用来返回解析完成的 Url 组成部分
class _ResolveResult {
	const _ResolveResult(this.result, this.doBackward);

	final String result;
	final bool doBackward;
}

/// 解析回调接口
typedef _ResolveCallback = dynamic Function(String concat, String c, bool isLastChar);

/// 解析 Url 协议部分
/// 目前支持识别的协议为
dynamic _resolveProtocol(String concat, String c, bool isLastChar) {
	if (isLastChar) {
		return _stopResolveObj;
	}

	if (c == ':') {
		switch (concat) {
		// 识别出为 http 请求
			case 'http':
				return const _ResolveResult('http', true);
		// 识别出为 https 请求
			case 'https':
				return const _ResolveResult('https', true);
		// 未识别协议，中断解析
			default:
				return _stopResolveObj;
		}
	} else {
		if (concat.length >= 5) {
			// 长度超过所支持协议的最长长度中断解析
			// https 长度为 5
			return _stopResolveObj;
		}
		return concat + c;
	}
}

/// 解析 Url 协议连接字符
dynamic _resolveProtocolConcat(String concat, String c, bool isLastChar) {
	if (isLastChar) {
		return _stopResolveObj;
	}

	if (c != ':' && c != '/') {
		return _stopResolveObj;
	}

	final newConcat = concat + c;
	if (newConcat.length == 3) {
		if (newConcat == '://') {
			return const _ResolveResult('://', false);
		} else {
			return _stopResolveObj;
		}
	}

	return newConcat;
}

/// 解析 Url Host
dynamic _resolveHost(String concat, String c, bool isLastChar) {
	if (c == ':' || c == '?' || c == '/' || isLastChar) {
		if (c == ':' || c == '?' || c == '/') {
			return _ResolveResult(concat, true);
		} else {
			return _ResolveResult(concat, false);
		}
	}
	return concat + c;
}

/// 解析 Url Port
dynamic _resolvePort(String concat, String c, bool isLastChar) {
	if (concat.isEmpty) {
		if (isLastChar) {
			return _ResolveResult(null, true);
		}
		if (c != ':') {
			return const _ResolveResult('', true);
		} else {
			return c;
		}
	}

	if (c == '?' || c == '/' || isLastChar) {
		if (RegExp('^:[0-9]+\$').hasMatch(concat)) {
			return _ResolveResult(concat.substring(1), !isLastChar);
		} else {
			return _stopResolveObj;
		}
	}

	if (concat.length == 6) {
		// 超过长度限制
		return _stopResolveObj;
	}

	return concat + c;
}

/// 解析 Url Path
/// 来着不拒
dynamic _resolvePath(String concat, String c, bool isLastChar) {
	if (concat.isEmpty) {
		if (isLastChar) {
			return _ResolveResult(null, true);
		}
		if (c != '/') {
			return _ResolveResult(concat, true);
		} else {
			return c;
		}
	}

	if (c == '?') {
		if (concat.length == 1) {
			return _stopResolveObj;
		}
		return _ResolveResult(concat, true);
	}

	if (isLastChar) {
		return _ResolveResult(concat + c, true);
	}
	return concat + c;
}

/// Http 工具类
/// 提供一系列便捷的方法来操作与 Http 相关的数据
class PassHttpUtils {
	PassHttpUtils._();

	static final List<_ResolveCallback> _resolveCallbackList = [_resolveProtocol, _resolveProtocolConcat, _resolveHost, _resolvePort, _resolvePath];

	/// 根据 Url 获取其组成信息
	/// 返回 HttpUrl 来承载这些信息
	static PassResolveUrl resolveUrl(String url) {
		try {
			if (url == null) {
				return null;
			}

			final urlLength = url.length;
			var callbackIdx = 0;
			var concatStr = '';
			List<String> resultList;
			var callback = _resolveCallbackList[callbackIdx++];
			for (var i = 0; i <= urlLength; i++) {
				final isEnd = i == urlLength;
				final childStr = isEnd ? '' : url[i];
				final result = callback(concatStr ?? '', childStr, isEnd);
				if (result is String) {
					concatStr = result;
				} else if (result is _ResolveResult) {
					resultList ??= [];
					resultList.add(result.result);
					concatStr = null;
					if (callbackIdx == _resolveCallbackList.length) {
						if (isEnd) {
							resultList.add(null);
							break;
						}
						if (childStr == '?') {
							// 存在 QueryParams
							resultList.add(url.substring(i));
							break;
						}
					}
					callback = _resolveCallbackList[callbackIdx++];
					if (result.doBackward || isEnd) {
						i -= 1;
					}
				} else if (result == _stopResolveObj) {
					print(callbackIdx);
					return null;
				}
			}

			if (resultList.length != 6) {
				return null;
			}

			final hostStr = resultList[2];
			var domainStr = hostStr;
			final domainEndPoint = domainStr.lastIndexOf('.');
			if (domainEndPoint == -1) {
				return null;
			}
			final domainStartPoint = domainStr.lastIndexOf('.', domainEndPoint - 1);
			if (domainStartPoint != -1) {
				domainStr = domainStr.substring(domainStartPoint + 1);
			}

			final portStr = resultList[3];
			return PassResolveUrl(url: url,
				protocol: resultList[0],
				host: hostStr,
				domain: domainStr,
				port: portStr != null ? int.tryParse(portStr) : null,
				path: resultList[4],
				queryParams: resultList[5]);
		} catch (e) {
			return null;
		}
	}
}
