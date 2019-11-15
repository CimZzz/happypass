import 'package:happypass/happypass.dart';

void main() async {
	await interceptAtB();
}


void generalIntercept() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();

	// 设置 Request 路径
	request.setUrl("https://www.baidu.com/")
	// 设置 Request 头部
	.setRequestHeader("Hello", "World")
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 添加拦截器
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain A");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain B");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain C");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain D");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain E");
		return chain.waitResponse();
	}))
	// GET 请求
	.GET();

	// 发送请求并打印响应结果
	print(await request.doRequest());
}



void interceptAtB() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();

	// 设置 Request 路径
	request.setUrl("https://www.baidu.com/")
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 添加拦截器
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain A");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain B");
		// 这次我们在 B 点直接执行请求
		return chain.requestForPassResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain C");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain D");
		return chain.waitResponse();
	}))
	.addFirstInterceptor(SimplePassInterceptor((chain) {
		print("chain E");
		return chain.waitResponse();
	}))
	// GET 请求
	.GET();

	// 发送请求并打印响应结果
	print(await request.doRequest());
}