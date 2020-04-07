/// Http 原始 Response 的包装类
/// 为了跨平台而设计，提供通用的访问响应数据的方法
abstract class PassHttpResponse {
	/// 响应状态码
	int get statusCode;
	
	/// 响应数据长度
	int get contentLength;

	/// 响应数据流
	Stream<List<int>> get bodyStream;
	
	/// 获取 Http 响应头部
	String getResponseHeader(String key);
}