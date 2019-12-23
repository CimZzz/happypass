import 'package:happypass/happypass.dart';

/// 下面实例展示了如何利用 `happypass`，快速的执行一次 `GET` 请求
void main() async {
	// 使用 [Request.quickGet] 方法执行请求
	final result = await Request.quickGet(
		url: 'https://www.baidu.com/',
		configCallback: (request) {
			// 这一步的作用是快捷配置字符串编解码器
			// 如果不进行配置，收的将会是 `byte` 数据
			request.stringChannel();
		});

	// 返回结果是 [ResultPassResponse] 的子类，分别是 [ErrorPassResponse] 和 [SuccessPassResponse]
	// 对应着请求结果的成功与失败
	print('result type: ${result.runtimeType}');
	print(result.toString());
}
