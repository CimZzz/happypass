import 'package:happypass/happypass.dart';

/// 下面列举了请求原型可以配置的全部参数
/// 相比于 [Request]，[RequestPrototype] 可以配置的请求参数相对较少，具体原因下面会列举，
/// 但请求原型目前可以配置的信息几乎可以应对全部泛化配置，
void main() async {
	RequestPrototype prototype = RequestPrototype();

	// 设置请求 Id
	// 请求 id 针对特定请求，无法进行泛化设置
	// prototype.setRequestId('request1');

	// 设置 Request Url
	prototype.setUrl('http://www.helloworld.com');
	// 添加请求地址路径
	// 如果之前使用 [setUrl] 方法设置了 url ，则会将该方法添加的路径追加在 Url 之后
	// 如使用 setUrl 设置 url 为 'http://www.helloworld.com'，然后调用 addPath 添加路径 '/money'
	// 那么最终的 Url 地址为 'http://www.helloworld.com/money'
	prototype.addPath('/money');

	// 设置总超时时间
	// 总时长超过超时时间将会抛出异常
	// * 拦截器处理时间也算在总时长之内
	prototype.setTotalTimeOut(const Duration(seconds: 5));

	// 设置连接超时时间
	// 连接时长超过超时时间将会抛出异常
	prototype.setConnectTimeOut(const Duration(seconds: 5));

	// 设置读取超时时间
	// 读取时长超过超时时间将会抛出异常
	prototype.setReadTimeOut(const Duration(seconds: 5));

	// 添加请求 Url 参数
	// 如果当前 Url 地址为 `http://www.helloworld.com/money`，那么添加 Url 参数过后，整个 Url 地址为
	// `http://www.helloworld.com/money?tech=neverend`。
	// 参数 checkFirstParams 表示是否检查参数是第一参数（首个参数头部会添加 `?` 而不是 `&`）
	// useEncode 表示是否进行 `uri encode`
	prototype.appendQueryParams('tech', 'neverend', checkFirstParams: true, useEncode: true);

	// 以 Map 的形式添加请求 Url 参数
	// 如果当前 Url 地址为 `http://www.helloworld.com/money`，那么添加 Url 参数过后，整个 Url 地址为
	// `http://www.helloworld.com/money?tech=neverend`。
	// 参数 checkFirstParams 表示是否检查参数是第一参数（首个参数头部会添加 `?` 而不是 `&`）
	// useEncode 表示是否进行 `uri encode`
	prototype.appendQueryParamsByMap({
		'happy': 'pass',
		'task': 'pipeline',
	}, checkFirstParams: true, useEncode: false);

	// 设置请求头
	// 需要注意的是，通过该方法设置的 `key` 值均会被转换为小写格式
	// 比如设置 `prototype.setRequestHeader('CONTENT-TYPE', 'text/plain')`，实际上等同于
	// `prototype.setRequestHeader('content-type', 'text/plain')`
	prototype.setRequestHeader('CONTENT-TYPE', 'text/plain');
	// 设置自定义请求头
	// 如果小写 `key` 不足以满足需求的话，你可以使用该方法设置你想要的请求头
	// 通过该方法设置的 `key` 值会保留其大小写形式
	prototype.setCustomRequestHeader('TOKEN', 'wishper');
	// 以 Map 的形式设置请求头部
	prototype.setRequestHeaderByMap({
		'CONTENT-TYPE': 'text/plain',
	});
	// 以 Map 的形式设置自定义请求头部
	prototype.setCustomRequestHeaderByMap({'TOKEN': 'wishper'});
	// 设置 Cookie 管理器
	// `happypass` 提供的 Cookie 管理器有:
	// - MemoryCacheCookieManager: 内存缓存 Cookie 管理器
	//
	// 如果使用以上 Cookie 管理器不能满足你的需求，那么就去自定义一个吧
	// 定义一个继承自 [CookieManager] 的子类即可实现 Cookie 的自定义管理
	prototype.setCookieManager(MemoryCacheCookieManager());

	// 请求原型不允许设置中断器
	// 因为请求原型应对的场景是全局，而中断器只是用于局部逻辑
	// final requestCloser = RequestCloser();
	// prototype.setRequestCloser(requestCloser);

	// 设置消息的编码器和解码器
	// 在列表末位添加编码器和解码器
	// - 编码器: 将某种格式数据结构进行转换，最终转换为 `List<int>` 类型的 byte 数据，作为最终的请求数据。
	// - 解码器: 将响应数据 `List<int>` 类型的 byte 数据进行解码，最终转换成某种格式的数据结构作为请求结果数据
	// `happypass` 提供的编码器有:
	// - GZip2ByteEncoder: GZIP 编码器。转换模式为: List<int> -> List<int>（byte 转 byte）
	// - Utf8String2ByteEncoder: utf8 字符串编码器。转换模式为: String -> List<int>（字符串转 `utf8` 格式的 byte 数据）
	// - JSON2Utf8StringEncoder: JSON 编码器。转换模式为: Map -> String（Map 转字符串）
	//
	//
	// `happypass` 提供的解码器有:
	// - Byte2GZipDecoder: GZIP 解码器。转换模式为: List<int> -> List<int>（byte 转 byte）
	// - Byte2Utf8StringDecoder: utf8 字符串解码器。转换模式为: List<int> -> String（`utf8` 格式的 byte 数据转字符串）
	// - Utf8String2JSONDecoder: JSON 解码器。转换模式为: String -> Map（字符串转 Map）
	//
	//
	// 如果以上编码器或者解码器不能满足你的需要，可以定义一个继承自 [HttpMessageEncoder] 或 [HttpMessageDecoder]
	// 继承实现自定义的编解码器
	prototype.addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
	prototype.addLastEncoder(const Utf8String2ByteEncoder());

	// 设置 utf8 字符串编解码器
	// 便捷配置 utf8 字符串的编码器和解码器
	prototype.stringChannel();

	// 设置 JSON 编解码器
	// 便捷配置 JSON 编解码器和 utf8 编解码器
	prototype.jsonChannel();

	// 清空全部解码器
	prototype.clearDecoder();

	// 清空全部编码器
	prototype.clearEncoder();

	// 在首位插入一个 Http 拦截器
	// 拦截器涉及内容较多，请在专门介绍拦截器的示例中了解更多
	//
	// `happypass` 提供的拦截器有:
	// - LogUrlInterceptor: 打印请求 Url 拦截器，仅仅打印请求 Url，不会对请求进行拦截与修改
	// - SimplePassInterceptor: 简易拦截器，将具体的拦截逻辑委托到其回调闭包中执行
	// - BusinessPassInterceptor: 请求逻辑拦截器，实际处理请求的拦截器，会对请求进行拦截并真正发送请求，并生成响应结果
	//
	// 如果以上编码器或者解码器不能满足你的需要，可以定义一个继承自 [PassInterceptor] 实现自定义的拦截器
	prototype.addFirstInterceptor(const LogUrlInterceptor());

	// 清空全部拦截器
	prototype.clearInterceptors();

	// 设置执行代理
	// 在一次完整的 HTTP 请求中，可能会有一些耗时操作（比如 JSON 字符串的编解码），造成线程卡顿，
	// 所以我们可以设置请求执行代理（如建立一个 `Isolate` 去完成耗时操作），这样即可避免这个问题
	// * 在 `Flutter` 中，我们可以使用线程的 `compute` 方法，很简单地完成上面一系列操作，而该方法和
	// * `compute` 方法完美契合，仅需这样设置即可:
	//
	// setRequestRunProxy(<T, Q>(asyncCallback, message) async {
	//      return await compute(asyncCallback, message);
	// });
	//
	// * `happypass` 会自动将可能存在耗时操作的方法放到执行代理中去运行（如数据的编解码）
	prototype.setRequestRunProxy(null);

	// 请求原型不能设置响应原始数据接收回调。
	// 通常设置了该回调的请求为了满足某些特殊的需求，不应该应用到每个请求
	// prototype.setResponseRawDataReceiverCallback(null);

	// 请求原型不能设置响应数据接收进度回调
	// 通常设置了该回调的请求为了满足某些特殊的需求，不应该应用到每个请求
	// prototype.addResponseDataUpdate(null);

	// 添加请求 Http 代理
	prototype.addHttpProxy('localhost', 8888);

	// 请求原型不能设置请求方法
	// 因为 `POST` 方法会使用请求 Body 作为参数传递，而这个 Body 对于每个请求都是特定地，并且
	// 如果为原型设置了这个 body，意味着该数据将会被全局持有不能回收，不利于内存的优化
	// prototype.GET();
	// prototype.POST(null);
}
