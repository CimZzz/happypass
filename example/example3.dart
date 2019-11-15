import 'package:happypass/happypass.dart';

void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("http://xxxxxx")
	// 设置请求方法为 POST
	// body 是一个 Map，所以需要配置编码器将 Map 转化为 List<int> 数据
	// 假设服务端需要的数据时 JSON 字符串
	.POST({
		"data": "helloworld"
	})
	// 首先将 Map 转化为 JSON 字符串
	.addFirstEncoder(const JSON2Utf8StringEncoder())
	// 然后将 String 转化为 List<int>
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 将响应数据 List<int> 转化为 String
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 然后 String 转化为 Map
	.addLastDecoder(const Utf8String2JSONDecoder());
	// 发送请求并打印响应结果
	print(await request.doRequest());
}