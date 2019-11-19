import 'dart:isolate';
import 'package:happypass/happypass.dart';

class _Receiver {
	_Receiver(this.executor, this.port);

	final RequestExecutor executor;
	final SendPort port;
}

Future<ResultPassResponse> _proxy(RequestExecutor executor) async {
	// 创建 Isolate
	final receiverPort = ReceivePort();
	final isolate = await Isolate.spawn(_doProxy, _Receiver(executor, receiverPort.sendPort));
	final result = await receiverPort.first;
	isolate.kill();
	return result;
}

void _doProxy(_Receiver receiver) async {
	final result = await receiver.executor.execute();
	receiver.port.send(result);
}

void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("https://www.baidu.com/")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.setRequestRunProxy(_proxy)
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.addFirstInterceptor(const LogUrlInterceptor())
	// GET 请求
	.GET();
	// 发送请求并打印响应结果
	print(await request.doRequest());
}
