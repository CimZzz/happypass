import 'package:happypass/happypass.dart';

/// 本示例介绍请求原型简单的使用
void main() async {
	// 实例化一个请求原型
	RequestPrototype prototype = RequestPrototype();
	// 为请求原型设置请求 Url
	prototype.setUrl('https://www.baidu.com');
	// 为请求原型设置字符串编解码器
	prototype.stringChannel();

	// 快速孵化请求，量化执行
	for (int i = 0; i < 10; i++) {
		print(await prototype.spawn().GET().doRequest());
	}
}
