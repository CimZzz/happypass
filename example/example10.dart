import 'dart:convert';
import 'dart:io';

import 'package:happypass/happypass.dart';

/// 测试响应原始数据接收回调
/// 下载文件保存至本地
void main() async {
	final request = Request.construct();
//	request.addHttpProxy("localhost", 1087);
	final file = File("/Users/cimzzz/Desktop/1.txt");
	await request.setUrl("https://xiazai.qishus.com/txt/%E5%89%91%E7%8E%8B%E6%9C%9D.txt")
		.GET()
		.addResponseDataUpdate((int length, int totalLength) {
			print("$length / $totalLength");
		})
		.setResponseRawDataReceiverCallback((stream) async {
			final output = file.openWrite(encoding: Encoding.getByName("gb2312"));
			await for(var byteList in stream) {
				await output.add(byteList);
			}
		})
		.doRequest();
}