part of 'http.dart';

/// Http 消息编码器基类
abstract class HttpMessageEncoder {
    const HttpMessageEncoder();

    dynamic encode(dynamic message);
}

/// Utf8 字符串 - Byte 编码器
class Utf8String2ByteEncoder extends HttpMessageEncoder {
    const Utf8String2ByteEncoder();

    @override
    dynamic encode(dynamic message) {
        if(message is String) {
            return utf8.encode(message);
        }

        return null;
    }
}

/// JSON - Utf8 字符串编码器
class JSON2Utf8StringEncoder extends HttpMessageEncoder {
    const JSON2Utf8StringEncoder();

    @override
    dynamic encode(dynamic message) {
        if(message is Map) {
            return json.encode(message);
        }
        return null;
    }
}