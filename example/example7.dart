import 'package:happypass/happypass.dart';

/// 使用 `FormDataBody` 作为请求体数据发送
/// FormDataBody : 标准表单数据格式
void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("xxxxx")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.POST(FormDataBody().addPair("hello", "world").addPair("happy", "everyday"));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}