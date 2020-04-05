import 'package:happypass/src/http_quick_access.dart';

/// 本示例用来演示如何使用 `happypass` 快速访问工具类
void main() async {
	print(await happypass.download(
		downloadUrl: "http://baichuan-sdk.cn-hangzhou.oss-pub.aliyun-inc.com/19/android/4.0.0.8/4.0.0.8.zip?spm=a3c0d.7662649.0.0.4ccabe488bbyHn&file=4.0.0.8.zip",
		storePath: "/usr/local/temp/123.app"
	));
}