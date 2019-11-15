import 'package:happypass/happypass.dart';

void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	RequestPrototype requestPrototype = RequestPrototype();

	// 设置 Request 路径
	requestPrototype.setUrl("https://www.baidu.com/")
	// 设置 Request 头部
	.setRequestHeader("Hello", "World")
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 添加拦截器
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		return chain.waitResponse();
	}));
	// 不允许原型配置请求方法
	//.GET();

	// 由原型孵化出 Request
	final request1 = requestPrototype.spawn();
	final request2 = requestPrototype.spawn();
	final request3 = requestPrototype.spawn();
	// 异步执行所有请求
	request1.GET().doRequest();
	request2.GET().doRequest();
	request3.GET().doRequest();
	// 发送请求并打印响应结果
	print("request1 : ${await request1.doRequest()}");
	print("request2 : ${await request2.doRequest()}");
	print("request3 : ${await request3.doRequest()}");
}