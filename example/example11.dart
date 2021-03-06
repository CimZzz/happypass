import 'package:happypass/happypass.dart';

/// 本示例演示了如何设置请求超时时间，并对各个超时进行详细解释
/// * totalTimeOut: 总超时时间。从请求开始一瞬间开始计算，包括请求过程中拦截器的操作耗时
/// * connectTimeout: 连接超时时间。表示 `HttpClient` 生成 `HttpClientRequest` 的耗时时间
/// * readTimeout: 读取(解析)响应数据超时时间。表示解析响应数据的耗时时间
/// 我们分别使用多个方法，演示每个超时时间生效的场景:
///
/// [method1] : 模拟请求超过总超时时间的场景
/// [method2] : 模拟请求连接超过连接超时时间的场景
/// [method3] : 模拟请求解析超过读取超时时间的场景
///
void main() async {
//	method1();
//	method2();
	method3();
}

void method1() async {
	// 我们使用拦截器模拟一下超过总超时时间的场景
	// 仍然使用 [Request.quickGet] 方法快速发送请求，在请求配置时添加一个用来耗时的拦截器
	final result = await happypass.get(
		url: 'https://www.baidu.com',
		configCallback: (request) {
			// 设置总超时时间为 3 秒
			request.setTotalTimeOut(const Duration(seconds: 3));
			request.addFirstInterceptor(SimplePassInterceptor((chain) async {
				// 等待延迟时间模拟耗时操作
				await Future.delayed(const Duration(seconds: 5));
				return chain.waitResponse();
			}));
		});

	// 三秒之后，打印结果为 `total time out` 表示执行时间超过总超时时间，
	// 被强制中断
	print('method1: $result');
}

void method2() async {
	// 我们使用拦截器模拟一下连接超时时间的场景
	// 仍然快速发送 GET 请求，使用拦截器拦截请求，并 `hock` 生成 `PassResponse` 的流程
	final result = await happypass.get(
		url: 'https://www.baidu.com',
		configCallback: (request) {
			// 设置连接超时时间为 3 秒
			request.setConnectTimeOut(const Duration(seconds: 3));
			request.addFirstInterceptor(SimplePassInterceptor((chain) async {
				return chain.modifier.runInConnectTimeoutByClosure(() async {
					// 等待延迟时间模拟耗时操作
					await Future.delayed(const Duration(seconds: 5));
					return chain.waitResponse();
				});
			}));
		});

	// 三秒之后，打印结果为 `content time out` 表示执行时间超过连接超时时间，
	// 被强制中断
	print('method2: $result');
}

void method3() async {
	// 我们使用拦截器模拟一下读取超时时间的场景
	// 仍然使用 [Request.quickGet] 方法快速发送请求，使用拦截器拦截请求，并 `hock` 生成 `PassResponse` 的流程
	final result = await happypass.get(
		url: 'https://www.baidu.com',
		configCallback: (request) {
			// 设置连接超时时间为 3 秒
			request.setConnectTimeOut(const Duration(seconds: 1));
			request.addFirstInterceptor(SimplePassInterceptor((chain) async {
				return chain.modifier.runInConnectTimeoutByClosure(() async {
					await Future.delayed(const Duration(seconds: 2));
					return await chain.requestForPassResponse();
				});
			}));
		});

	// 三秒之后，打印结果为 `read time out` 表示执行时间超过读取超时时间，
	// 被强制中断
	print('method3: $result');
}
