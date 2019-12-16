part of 'http.dart';

class HttpUrl {
    HttpUrl({this.url, this.host, this.port, this.path});
    
	final String url;
	final String host;
	final int port;
	final String path;
}

/// Http 工具类
/// 提供一系列便捷的方法来操作与 Http 相关的数据
class HttpUtils {
	HttpUtils._();
	
	/// 根据 Url 获取其组成信息
	/// 返回 HttpUrl 来承载这些信息
	static HttpUrl resolveUrl(String url) {
		final httpRegex = RegExp("^(http|https)://([a-zA-Z\.]+)[:]?(\\d+)?[/]?(.*)");
		final matcher = httpRegex.firstMatch(url);
		if(matcher == null || matcher.groupCount != 4) {
			return null;
		}
		
		final portStr = matcher.group(3);
		return HttpUrl(
			url: matcher.group(0),
			host: matcher.group(2),
			port: portStr != null ? int.tryParse(portStr) : null,
			path: matcher.group(4)
		);
	}
}