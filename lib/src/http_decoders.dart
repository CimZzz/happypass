part of 'http.dart';

/// Http 消息解码器基类
abstract class HttpMessageDecoder {
    const HttpMessageDecoder();

    dynamic decode(dynamic message);
}

/// GZip
class GZip2ByteEncoder extends HttpMessageEncoder {
    const GZip2ByteEncoder();
    
    @override
    dynamic encode(dynamic message) {
        if(message is List<int>) {
            return gzip.encode(message);
        }
        return message;
    }
}


class Byte2GZipDecoder extends HttpMessageDecoder {
    const Byte2GZipDecoder();
    
    @override
    dynamic decode(dynamic message) {
        if(message is List<int>) {
            return gzip.decode(message);
        }
        return message;
    }
    
}

/// Byte - Utf8 字符串编码器
class Byte2Utf8StringDecoder extends HttpMessageDecoder {
    const Byte2Utf8StringDecoder({this.isAllowMalformed});
    
    final bool isAllowMalformed;
    
    @override
    dynamic decode(dynamic message) {
        if(message is List<int>) {
            return utf8.decode(message, allowMalformed: this.isAllowMalformed);
        }
        
        return message;
    }
}

/// Utf8 字符串 - JSON 编码器
class Utf8String2JSONDecoder extends HttpMessageDecoder {
    const Utf8String2JSONDecoder();

    @override
    dynamic decode(dynamic message) {
        if(message is String) {
            return json.decode(message);
        }
        return message;
    }
}