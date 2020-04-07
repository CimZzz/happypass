import 'package:happypass/happypass.dart';
import 'package:happypass/src/stream_data.dart';

/// 本示例演示了如何使用 [StreamDataBody] 传递流数据
void main() async {
	// 这次我们使用 [Request.quickPost] 方法快速发起 `POST` 请求
	// 使用 `StreamDataBody` 作为请求体
	// 需要指定流数据的 ContentType
	final result = await happypass.post(url: 'xxxx', body: StreamDataBody(Stream.empty(), streamContentType: 'text/plain'));

	print(result);
}
