
import 'dart:convert';
import 'dart:io';

import 'package:happypass/happypass.dart';

/// 测试强制中断请求
void main() async {
	final request = Request.construct();
	final file = File("/Users/cimzzz/Desktop/1.txt");
	final requestCloser = RequestCloser();
	final result = await request.setUrl("https://new.qq.com/omn/SJD20191/SJD2019121500365600.html")
		.GET()
		.setRequestCloser(requestCloser)
		.addResponseDataUpdate((int length, int totalLength) {
		print("$length / $totalLength");
//		if(length >= totalLength / 2) {
//			requestCloser.close(finishResponse: ErrorPassResponse(msg: "哈哈 被我强行中断了"));
//		}
		
	})
		.setResponseRawDataReceiverCallback((stream) async {
		final output = file.openWrite(encoding: Encoding.getByName("gb2312"));
		await for(var byteList in stream) {
			await output.add(byteList);
		}
		return SuccessPassResponse();
	})
		.doRequest();
	
	print(result);
}