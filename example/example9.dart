import 'package:happypass/happypass.dart';

/// 测试响应数据进度接收回调
void main() async {
	final request = Request.construct();
	
	await request.setUrl("http://fastsoft.onlinedown.net/down/IDM_ald.exe")
		.GET()
		.addResponseDataUpdate((int length, int totalLength) {
			print("$length / $totalLength");
		})
		.doRequest();
}