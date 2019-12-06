import 'dart:io';

import 'package:happypass/happypass.dart';

void main() async {
	File file = File("/Users/wangyanxiong/Desktop/1.java");
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("http://49.234.99.78/shop/test.php")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	// GET 请求
	.POST(MultiPartDataBody().addMultipartFile("123", file));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}