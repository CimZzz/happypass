

import 'http_response.dart';

abstract class PassHttpRequest {
	
	/// 设置 Http 请求头部
	void setRequestHeader(String key, String value);
	
	/// 获取 Http 请求头部
	String getRequestHeader(String key);
	
	/// 发送数据
	/// - 在 Native 中，data 类型应为 `List<int>`
	/// - 在 Html 中，data 类型应为 `Blob` 或 `List<int>`
	///
	/// 由于 Html 无法分段发送，所以该方法只能调用一次；在 Native 中无限制
	///
	/// * [checkDataLegal] 方法就是用来检查数据是否合法
	void sendData(dynamic data);
	
	/// 检查请求数据是否合法
	/// - 在 Native 中，data 类型应为 `List<int>`
	/// - 在 Html 中，data 类型应为 `Blob` 或 `List<int>`
	bool checkDataLegal(dynamic data);
	
	/// 获取请求响应
	Future<PassHttpResponse> fetchHttpResponse();
	
	/// 关闭请求
	void close();
}