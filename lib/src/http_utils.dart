part of 'http.dart';

/// Http Url
/// 将 url 解析成一系列组成部分
class PassHttpUrl {
  PassHttpUrl({this.url, this.host, this.domain, this.port, this.path});

  final String url;
  final String domain;
  final String host;
  final int port;
  final String path;

  @override
  String toString() {
    return "url: $url, domain: $domain, host: $host, port: $port, path: $path";
  }
}

/// Http 工具类
/// 提供一系列便捷的方法来操作与 Http 相关的数据
class PassHttpUtils {
  PassHttpUtils._();

  /// 根据 Url 获取其组成信息
  /// 返回 HttpUrl 来承载这些信息
  static PassHttpUrl resolveUrl(String url) {
    if (url == null) {
      return null;
    }


    final httpRegex = RegExp("^(http|https)://([a-zA-Z\.]*?[\.]?)?([a-zA-Z]+[\.][a-zA-Z]+)+?[:]?(\\d+)?[/]?(.*)");
    final matcher = httpRegex.firstMatch(url);
    if (matcher == null || matcher.groupCount != 5) {
      return null;
    }

    for(var i = 1; i < 6 ; i ++) {
      print(matcher.group(i));
    }

    final portStr = matcher.group(3);
    return PassHttpUrl(url: matcher.group(0), host: matcher.group(2), port: portStr != null ? int.tryParse(portStr) : null, path: matcher.group(4));
  }
}
