part of 'http.dart';

/// Http 消息编码器基类
abstract class HttpMessageEncoder {
  const HttpMessageEncoder();

  dynamic encode(dynamic message);
}

/// GZip 编码器
class GZip2ByteEncoder extends HttpMessageEncoder {
  const GZip2ByteEncoder();

  @override
  dynamic encode(dynamic message) {
    if (message is List<int>) {
      return gzip.encode(message);
    }
    return message;
  }
}

/// Utf8 字符串 - Byte 编码器
class Utf8String2ByteEncoder extends HttpMessageEncoder {
  const Utf8String2ByteEncoder();

  @override
  dynamic encode(dynamic message) {
    if (message is String) {
      return utf8.encode(message);
    }

    return message;
  }
}

/// JSON - Utf8 字符串编码器
class JSON2Utf8StringEncoder extends HttpMessageEncoder {
  const JSON2Utf8StringEncoder();

  @override
  dynamic encode(dynamic message) {
    if (message is Map) {
      return json.encode(message);
    }
    return message;
  }
}
