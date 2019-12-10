import 'dart:io';

import 'package:happypass/happypass.dart';

/// 使用 `MultipartDataBody` 传递数据
/// MultipartDataBody : 可以上传流数据
void main() async {
	File file = File("xxxx/temp.txt");
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("xxx")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.POST(MultipartDataBody().addMultipartFile("file", file));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}