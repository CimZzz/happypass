import 'package:happypass/happypass.dart';

/// 下面列举了请求可以配置的全部参数
/// * 请求无法直接实例化，而是通过 [Request.construct] 方法来进行实例化
void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request Url
	request.setUrl("http://www.helloworld.com");
	// 添加请求地址路径
	// 如果之前使用 [setUrl] 方法设置了 url ，则会将该方法添加的路径追加在 Url 之后
	// 如使用 setUrl 设置 url 为 "http://www.helloworld.com"，然后调用 addPath 添加路径 "/money"
	// 那么最终的 Url 地址为 "http://www.helloworld.com/money"
	request.addPath("/money");
	// 设置请求头
	// 需要注意的是，通过该方法设置的 `key` 值均会被转换为小写格式
	// 比如设置 `request.setRequestHeader("CONTENT-TYPE", "text/plain")`，实际上等同于
	// `request.setRequestHeader("content-type", "text/plain")`
	request.setRequestHeader("CONTENT-TYPE", "text/plain");
	// 设置自定义请求头
	// 如果小写 `key` 不足以满足需求的话，你可以使用该方法设置你想要的请求头
	// 通过该方法设置的 `key` 值会保留其大小写形式
	request.setCustomRequestHeader("TOKEN", "wishper");
	// 以 Map 的形式设置请求头部
	request.setRequestHeaderByMap({
		"CONTENT-TYPE": "text/plain",
	});
	// 以 Map 的形式设置自定义请求头部
	request.setCustomRequestHeaderByMap({
		"TOKEN": "wishper"
	});
	// 设置 Cookie 管理器
	// 本库提供的 Cookie 管理器有:
	// - MemoryCacheCookieManager: 内存缓存 Cookie 管理器
	//
	// 如果使用以上 Cookie 管理器不能满足你的需求，那么就去自定义一个吧
	// 定义一个继承自 [CookieManager] 的子类即可实现 Cookie 的自定义管理
	request.setCookieManager(MemoryCacheCookieManager());
	// 设置请求中断器
	// 可以强制中断请求，并且立即返回给定的响应结果
	// 使用 [RequestCloser.close] 方法即可
	// * 调用 [RequestCloser.close] 方法可以指定一个响应结果，作为最终的请求结果
	// * [RequestCloser.close] 可以在任何时间调用，且不会引起异常
	final requestCloser = RequestCloser();
	request.setRequestCloser(requestCloser);
	
	// 设置消息的编码器和解码器
	// - 编码器: 将某种格式数据结构进行转换，最终转换为 `List<int>` 类型的 byte 数据
	// - 解码器: 将某种类型
	request.addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
	request.addLastEncoder(const Utf8String2ByteEncoder())
	
	// 设置请求方法为 POST
	// body 是一个 Map，所以需要配置编码器将 Map 转化为 List<int> 数据
	// 假设服务端需要的数据时 JSON 字符串
	.POST({
		"data": "helloworld"
	})
	// 首先将 Map 转化为 JSON 字符串
	.addFirstEncoder(const JSON2Utf8StringEncoder())
	// 然后将 String 转化为 List<int>
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 将响应数据 List<int> 转化为 String
	.addLastDecoder(const Byte2Utf8StringDecoder());

	// 发送请求并打印响应结果
	print(await request.doRequest());
}