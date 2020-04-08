import '../http_interceptor_chain.dart';
import '../http_responses.dart';
import '_request_process_for_native.dart'
if (dart.library.html) '_request_process_for_html.dart' as _processor;

/// Http 请求处理器
/// Native 和 Html 请求处理方式不同，支持的选项也有所不同，在这里区分逻辑处理
abstract class HttpProcessor {
	
	factory HttpProcessor() => _processor.processor;
	
	/// 实际执行 `Request` 获得 `Response`
	/// 提供了一些可选回调，最大限度满足自定义 Request 的自由
	/// 默认情况下，在只在编码与解码时使用了执行代理
	Future<PassResponse> request(ChainRequestModifier modifier);
}