import 'package:happypass/happypass.dart';

/// 本示例主要演示请求中断器 [RequestCloser] 的使用
/// * `RequestCloser` 可以被多个请求同时使用，当主动调用中断时，多个请求将会被同时中断并且强制返回统一结果
void main() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();

	// 发送 GET 请求，并使用拦截器，在执行完成请求后中断
	final result = await Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置请求中断器
		request.addRequestCloser(requestCloser);
	});

	print(result);
}