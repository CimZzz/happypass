import 'dart:io';

import 'package:happypass/happypass.dart';

/// 使用 `MultipartDataBody` 传递数据
/// MultipartDataBody : 可以上传流数据
void main() async {
//	File file = File("xxxx/temp.txt");
	File file = File("/Users/wangyanxiong/Desktop/1.js");
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("http://49.234.99.78/shop/test.php")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.POST(MultipartDataBody().addMultipartFile("file", file).addMultiPartText("cc", "ccz").addMultiPartText("aa", "aaz").addMultiPartText("bb", "bbbz"));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}