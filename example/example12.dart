import 'package:happypass/happypass.dart';

/// 本示例演示了如何使用 [FormDataBody] 传递标准表单数据
void main() async {
	// 这次我们使用快速发起 `POST` 请求
	// 发送的表单数据形式为:
	// hello=world&......
	final result = await happypass.post(url: 'xxxx', body: FormDataBody.createByMap({'hello': 'world'}));

	print(result);
}
