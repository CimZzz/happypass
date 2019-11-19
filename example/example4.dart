import 'package:happypass/happypass.dart';

void main() async {
	await interceptAtB();
}

class SimpleIntercept1 extends PassInterceptor {
	const SimpleIntercept1(this.name);

	final String name;

	@override
	Future<PassResponse> intercept(PassInterceptorChain chain) {
		print(name);
		return chain.waitResponse();
	}
}

class SimpleIntercept2 extends PassInterceptor {
	const SimpleIntercept2(this.name);

	final String name;

	@override
	Future<PassResponse> intercept(PassInterceptorChain chain) {
		print(name);
		return chain.requestForPassResponse();
	}
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
	.addFirstInterceptor(const SimpleIntercept1("Chain A"))
	.addFirstInterceptor(const SimpleIntercept1("Chain B"))
	.addFirstInterceptor(const SimpleIntercept1("Chain C"))
	.addFirstInterceptor(const SimpleIntercept1("Chain D"))
	.addFirstInterceptor(const SimpleIntercept1("Chain E"))
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
	.addFirstInterceptor(const SimpleIntercept1("Chain A"))
	.addFirstInterceptor(const SimpleIntercept2("Chain B"))
	.addFirstInterceptor(const SimpleIntercept1("Chain C"))
	.addFirstInterceptor(const SimpleIntercept1("Chain D"))
	.addFirstInterceptor(const SimpleIntercept1("Chain E"))
	// GET 请求
	.GET();

	// 发送请求并打印响应结果
	print(await request.doRequest());
}