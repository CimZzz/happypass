import 'package:happypass/happypass.dart';

void main() async {
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
		return chain.waitResponse();
	}))
	// GET 请求
	.GET();

	// 发送请求并打印响应结果
	print(await request.doRequest());
}