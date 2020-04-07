import 'dart:io';
import 'dart:isolate';

import 'package:happypass/happypass.dart';

/// 本示例演示如何配置请求运行代理
/// 概念上可能会与 HTTP 代理混淆，这里详细解释一下:
/// - 请求运行代理: 在请求配置与解析时，可能会发生一些比较耗时的操作（例如解析 JSON），官方建议使用 `Isolate` 来单独处理这些操作，以防止造成
/// 卡顿等情况，而请求运行代理就是为了解决这个问题而生的。你可以在请求代理中使用一个 `Isolate` 去执行参数中的回调，然后将其结果返回。
///
/// - 请求 HTTP 代理: 使用指定的 HTTP 代理服务器发送请求。
///
/// * 目前在默认情况下，只有填充请求头部、编码请求消息和解码响应数据时会借助请求运行代理执行
/// * `happypass` 支持拦截器使用请求运行代理执行任意自定义方法，仅需通过 [ChainRequestModifier.runProxy] 方法即可
///
void main() async {
	// 快速进行一个 `GET` 请求
	final result = await happypass.get(
		url: 'https://www.baidu.com',
		configCallback: (request) {
			request.stringChannel();
			// 给请求配置一个运行代理请求
			// 使用 [_Receiver] 对象作为消息回调、消息和 `SendPort` 的数据载体
			// 指定 `Isolate` 运行回调为 [_doProxy] 方法
			// 大致流程如下:
			// 启动 Isolate，指定运行回调为 [_doProxy]，配置参数为 [_Receiver]。在 [_doProxy] 方法里调用 [_Receiver.execute] 获取结果，
			// 然后通过 [_Receiver.port] 发送结果
			request.setRequestRunProxy(<T, Q>(AsyncRunProxyCallback<T, Q> callback, T message) async {
				final receiverPort = ReceivePort();
				final isolate = await Isolate.spawn(_doProxy, _Receiver(message, callback, receiverPort.sendPort));
				final result = await receiverPort.first;
				receiverPort.close();
				isolate.kill();
				if (result is ErrorPassResponse) {
					throw IOException;
				}
				return result;
			});
		});

	print(result);

	// 在 `Flutter` 中，执行回调与 `Flutter` 提供的 `compute` 方法完美契合，可以参考如下配置
	/*
	*  setRequestRunProxy(<T, Q>(asyncCallback, message) async {
    *    return await compute(asyncCallback, message);
	*  });
	* */
}

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
	} catch (e) {
		receiver.port.send(ErrorPassResponse());
	}
}
