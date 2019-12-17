import 'dart:io';
import 'dart:isolate';
import 'package:happypass/happypass.dart';

/// 拦截器是 `happypass` 的核心，全部的请求逻辑都是由末端拦截器 [BusinessPassInterceptor] 进行处理
/// 本示例列举了拦截器的具体原理与使用场景，逐步了解 `happypass` 中拦截器的特点
void main() async {
	// 在详细介绍之前，先看一个简单的拦截器例子
	// 为了方便演示，我们采用 [SimplePassInterceptor] 类，只需传递回调闭包即可实现拦截的功能
	final interceptor = SimplePassInterceptor((chain) async {
		final httpUrl = chain.modifier.getHttpUrl();
		if(httpUrl != null && httpUrl.host == "www.baidu.com") {
			return ErrorPassResponse(msg: "block www.baidu.com request");
		}

		return chain.waitResponse();
	});

	final result = await Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置一个拦截器
		request.addFirstInterceptor(interceptor);
	});

	// 这里我们可以看到，最终打印的结果是 `block www.baidu.com request`，正是我们拦截器所配置的返回结果
	print(result);

	// 首先解释下在 [SimplePassInterceptor] 回调闭包中 `chain` 的作用
	// 拦截器可以视为请求的一条拦路，而 chain 表示的 [PassInterceptorChain] 类则是将这些拦截器
	// 串在一起的关键
	// * 如果拦截器实际上不会真正地拦截请求，那么必须调用 [PassInterceptorChain.waitResponse()] 并将其结果返回
	//
	// 通过该类完成拦截器的全部工作: 拦截 -> 修改请求 -> 完成请求 -> 返回响应的操作
	// 拦截器采取的方式是首位插入，所以最先添加的拦截器最后执行
	// 正常情况下，拦截器的工作应该如下
	// pass request : E -> D -> C -> B -> A -> BusinessPassInterceptor
	// return response : BusinessPassInterceptor -> A -> B -> C -> D -> E
	// 上述完成了一次拦截工作，Request 的处理和 Response 的构建都在 BusinessPassInterceptor 这个拦截器中完成
	// 如果在特殊情况下，某个拦截器（假设 B）意图自己完成请求处理，那么整个流程如下:
	// pass request : E -> D -> C -> B
	// return response : B -> C -> D -> E
	// 上述在 B 的位置直接拦截，请求并未传递到 [BusinessPassInterceptor]，所以 Request 的处理和 Response 的构建都应由 B 完成
	// 之前我们展示的小例子就是本质上就是 B 点所作相同
	// 下面我们用更多的拦截器，来验证拦截器的工作流程
	// 给每个拦截器命名，分别在收到请求与收到响应数据时打印信息

	Request.quickGet(url: "http://www.baidu.com", configCallback: (request) {
		request.addFirstInterceptor(SimplePassInterceptor((chain) async {
			// 拦截器 A
			print("interceptor A receiver request");
			final resp = await chain.waitResponse();
			print("interceptor A handle response");

			// 不要忘记返回响应数据给上一个拦截器!
			return resp;
		}));
		request.addFirstInterceptor(SimplePassInterceptor((chain) async {
			// 拦截器 B
			print("interceptor B receiver request");
			final resp = await chain.waitResponse();
			print("interceptor B handle response");
			return resp;
		}));
		request.addFirstInterceptor(SimplePassInterceptor((chain) async {
			// 拦截器 C
			print("interceptor C receiver request");
			final resp = await chain.waitResponse();
			print("interceptor C handle response");
			return resp;
		}));
		request.addFirstInterceptor(SimplePassInterceptor((chain) async {
			// 拦截器 D
			print("interceptor D receiver request");
			final resp = await chain.waitResponse();
			print("interceptor D handle response");
			return resp;
		}));
	});
}
//
//class _Receiver<T, Q> {
//	_Receiver(this.message, this.callback, this.port);
//	final T message;
//	final AsyncRunProxyCallback<T, Q> callback;
//	final SendPort port;
//
//	Future<Q> execute() async {
//		return await callback(message);
//	}
//}
//
//
//void _doProxy(_Receiver receiver) async {
//	try {
//		final result = await receiver.execute();
//		receiver.port.send(result);
//	}
//	catch(e) {
//		receiver.port.send(ErrorPassResponse());
//	}
//}
//
//void main2() async {
//	// 通过 [Request.construct] 方法直接创建实例
//	Request request = Request.construct();
//	// 设置 Request 路径
//	request.setUrl("https://www.baidu.com/")
//	// 设置 Request 运行环境，放置到 Isolate 中执行
//	.setRequestRunProxy(<T, Q>(asyncCallback, message) async {
//		final receiverPort = ReceivePort();
//		final isolate = await Isolate.spawn(_doProxy, _Receiver(message, asyncCallback, receiverPort.sendPort));
//		final result = await receiverPort.first;
//		receiverPort.close();
//		isolate.kill();
//		if(result is ErrorPassResponse) {
//			throw IOException;
//		}
//		return result;
//	})
//	// 设置解码器
//	.addLastDecoder(const Byte2Utf8StringDecoder())
//	// 设置拦截器
//	.addFirstInterceptor(const LogUrlInterceptor())
//	// GET 请求
//	.GET();
//	// 发送请求并打印响应结果
//	print(await request.doRequest());
//}
