import 'http_response.dart';

abstract class PassHttpRequest {

	/// 判断请求是否已经执行完毕
	bool get isClosed;

	/// 设置 Http 请求头部
	void setRequestHeader(String key, String value);
	
	/// 获取 Http 请求头部
	String getRequestHeader(String key);
	
	/// 发送数据
	/// - 在 Native 中，data 类型应为 `List<int>`
	/// - 在 Html 中，data 类型应为 `Blob`、`FormData`、`List<int>`、`Uint8List` 中的一种
	///
	/// * [checkDataLegal] 方法就是用来检查数据是否合法
	void sendData(dynamic data);
	
	/// 检查请求数据是否合法
	/// - 在 Native 中，data 类型应为 `List<int>`
	/// - 在 Html 中，data 类型应为 `Blob`、`FormData`、`List<int>`、`Uint8List` 中的一种
	bool checkDataLegal(dynamic data);
	
	/// 获取请求响应
	/// 这里的响应对象不是 `PassResponse` 的子类，而是用来包装原始 Http 响应数据的 `PassHttpResponse`
	/// `PassHttpResponse` 已经对跨平台做了兼容
	Future<PassHttpResponse> fetchHttpResponse();
	
	/// 关闭请求
	void close();
}