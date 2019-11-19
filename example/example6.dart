import 'dart:io';
import 'dart:isolate';
import 'package:happypass/happypass.dart';


class _Receiver<T, Q> {
	_Receiver(this.message, this.callback, this.port);
	final T message;
	final AsyncRunProxyCallback<T, Q> callback;
	final SendPort port;
	
	Future<Q> execute() async {
		return await callback(message);
	}
}


void _doProxy(_Receiver receiver) async {
	try {
		final result = await receiver.execute();
		receiver.port.send(result);
	}
	catch(e) {
		receiver.port.send(ErrorPassResponse());
	}
}

void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("https://www.baidu.com/")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.setRequestRunProxy(<T, Q>(asyncCallback, message) async {
		final receiverPort = ReceivePort();
		final isolate = await Isolate.spawn(_doProxy, _Receiver(message, asyncCallback, receiverPort.sendPort));
		final result = await receiverPort.first;
		receiverPort.close();
		isolate.kill();
		if(result is ErrorPassResponse) {
			throw IOException;
		}
		return result;
	})
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.addFirstInterceptor(const LogUrlInterceptor())
	// GET 请求
	.GET();
	// 发送请求并打印响应结果
	print(await request.doRequest());
}
