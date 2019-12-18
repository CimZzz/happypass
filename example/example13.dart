import 'dart:io';

import 'package:happypass/happypass.dart';

/// 本示例演示了如何使用 [MultipartDataBody] 传递 `Multipart` 表单数据
void main() async {
	// 这次我们使用 [Request.quickPost] 方法快速发起 `POST` 请求
	// 使用 `MultipartDataBody` 作为请求体
	final result = await Request.quickPost(
		url: "xxxx",
		body: MultipartDataBody()
		// 添加文本
		// - fileName: 可以指定文件名。如果指定了文件名，那么该文本将会被视为文件
		// - contentType: 可以指定 `ContentType`。如果指定了文件名，那么该文本将会被视为文件，并根据指定文件名的后缀自行判断其文件类型
		.addMultipartText("hello", "world", fileName: null, contentType: null)
		// 添加文件
		// - fileName: 可以指定文件名。如果不指定，那么将会以当前文件名作为其最终文件名
		// - contentType: 可以指定 `ContentType`。如果不指定，那么将会根据文件后缀自行判断其文件类型
		.addMultipartFile("file", File("xxxxx"), fileName: null, contentType: "text/plain")
		// 添加流
		// - fileName: 可以指定文件名。如果指定了文件名，那么该流将会被视为文件流
		// - contentType: 可以指定 `ContentType`。如果指定了文件名，那么该流将会被视为文件流，并根据指定文件名的后缀自行判断其文件类型
		.addMultipartStream("stream", Stream.empty(), fileName: null, contentType: null)
	);

	print(result);
}