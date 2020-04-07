import 'package:happypass/happypass.dart';

/// 下面列举了请求可以配置的全部参数
void main() async {
	// 创建请求实例
	Request request = Request();

	// 设置请求 Id
	// 为当前请求添加唯一标识符，以便于在特殊情况下区分请求
	request.setRequestId('request1');

	// 设置 Request Url
	request.setUrl('http://www.helloworld.com');
	// 添加请求地址路径
	// 如果之前使用 [setUrl] 方法设置了 url ，则会将该方法添加的路径追加在 Url 之后
	// 如使用 setUrl 设置 url 为 'http://www.helloworld.com'，然后调用 addPath 添加路径 '/money'
	// 那么最终的 Url 地址为 'http://www.helloworld.com/money'
	request.addPath('/money');

	// 设置总超时时间
	// 总时长超过超时时间将会抛出异常
	// * 拦截器处理时间也算在总时长之内
	request.setTotalTimeOut(const Duration(seconds: 5));

	// 设置连接超时时间
	// 连接时长超过超时时间将会抛出异常
	request.setConnectTimeOut(const Duration(seconds: 5));

	// 设置读取超时时间
	// 读取时长超过超时时间将会抛出异常
	request.setReadTimeOut(const Duration(seconds: 5));

	// 添加请求 Url 参数
	// 如果当前 Url 地址为 `http://www.helloworld.com/money`，那么添加 Url 参数过后，整个 Url 地址为
	// `http://www.helloworld.com/money?tech=neverend`。
	// 参数 checkFirstParams 表示是否检查参数是第一参数（首个参数头部会添加 `?` 而不是 `&`）
	// useEncode 表示是否进行 `uri encode`
	request.appendQueryParams('tech', 'neverend', checkFirstParams: true, useEncode: true);

	// 以 Map 的形式添加请求 Url 参数
	// 如果当前 Url 地址为 `http://www.helloworld.com/money`，那么添加 Url 参数过后，整个 Url 地址为
	// `http://www.helloworld.com/money?tech=neverend`。
	// 参数 checkFirstParams 表示是否检查参数是第一参数（首个参数头部会添加 `?` 而不是 `&`）
	// useEncode 表示是否进行 `uri encode`
	request.appendQueryParamsByMap({
		'happy': 'pass',
		'task': 'pipeline',
	}, checkFirstParams: true, useEncode: false);

	// 设置请求头
	// 需要注意的是，通过该方法设置的 `key` 值均会被转换为小写格式
	// 比如设置 `request.setRequestHeader('CONTENT-TYPE', 'text/plain')`，实际上等同于
	// `request.setRequestHeader('content-type', 'text/plain')`
	request.setRequestHeader('CONTENT-TYPE', 'text/plain');
	// 设置自定义请求头
	// 如果小写 `key` 不足以满足需求的话，你可以使用该方法设置你想要的请求头
	// 通过该方法设置的 `key` 值会保留其大小写形式
	request.setCustomRequestHeader('TOKEN', 'wishper');
	// 以 Map 的形式设置请求头部
	request.setRequestHeaderByMap({
		'CONTENT-TYPE': 'text/plain',
	});
	// 以 Map 的形式设置自定义请求头部
	request.setCustomRequestHeaderByMap({'TOKEN': 'wishper'});
	
	// 设置请求中断器
	// 可以强制中断请求，并且立即返回给定的响应结果
	// 使用 [RequestCloser.close] 方法即可
	// * 调用 [RequestCloser.close] 方法可以指定一个响应结果，作为最终的请求结果
	// * [RequestCloser.close] 可以在任何时间调用，且不会引起异常
	// * 一个 RequestCloser 可以用于多个请求
	// * 一个请求可以拥有多个 RequestCloser
	final requestCloser = RequestCloser();
	request.addRequestCloser(requestCloser);

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
	request.addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
	request.addLastEncoder(const Utf8String2ByteEncoder());

	// 设置 utf8 字符串编解码器
	// 便捷配置 utf8 字符串的编码器和解码器
	request.stringChannel();

	// 设置 JSON 编解码器
	// 便捷配置 JSON 编解码器和 utf8 编解码器
	request.jsonChannel();

	// 清空全部解码器
	request.clearDecoder();

	// 清空全部编码器
	request.clearEncoder();

	// 在首位插入一个 Http 拦截器
	// 拦截器涉及内容较多，请在专门介绍拦截器的示例中了解更多
	//
	// `happypass` 提供的拦截器有:
	// - LogUrlInterceptor: 打印请求 Url 拦截器，仅仅打印请求 Url，不会对请求进行拦截与修改
	// - SimplePassInterceptor: 简易拦截器，将具体的拦截逻辑委托到其回调闭包中执行
	// - BusinessPassInterceptor: 请求逻辑拦截器，实际处理请求的拦截器，会对请求进行拦截并真正发送请求，并生成响应结果
	//
	// 如果以上编码器或者解码器不能满足你的需要，可以定义一个继承自 [PassInterceptor] 实现自定义的拦截器
	request.addFirstInterceptor(const LogUrlInterceptor());

	// 清空全部拦截器
	request.clearInterceptors();

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
	request.setRequestRunProxy(null);

	// 设置响应原始数据接收回调
	// 如果该请求用于下载文件，显然是无需对接收到的数据进行解码，并且将整个下载的文件放入内存，读取完成之后
	// 再对文件进行处理，对于内存来说有很大压力，这是我们需要进行流处理:
	//
	//           one time read data
	// Response --------------------> File
	//
	// 这种场景，我们可以设置响应原始数据接收回调来完美地实现:
	//
	//           one time read data                             write to file
	// Response --------------------> ResponseRawDataReceiver ------------------> File
	//
	// 在这个流程里，每次读取的响应数据不会被保留在内存
	request.setResponseRawDataReceiverCallback(null);

	// 添加响应数据接收进度回调
	// 每当从接收到响应原始数据的时候，都会触发该回调来通知当前已经接收的数据总数
	// 如果开发者需要知晓响应数据接收进度（如通过接收进度来更新进度条等），可以设置该回调来实现这个功能
	request.addResponseDataUpdate(null);

	// 添加请求 Http 代理
	request.addHttpProxy('localhost', 8888);

	// 设置当前请求方法为 `GET`
	request.GET();

	// 设置当前请求方法为 `POST`
	// `POST` 方法需要额外传 body 参数，且不能为空
	// body 参数有两种选择:
	// 1. 某种类型数据。该类型数据会经过编码器层层编码，最终转换为 `List<int>` 类型的 byte 数据（如果通过编码器转换的最终数据不为 `List<int>`，则会抛出异常中断请求）
	// 2. [RequestBody] 子类
	//
	// * [RequestBody] 子类会按照一定的规则提供请求数据，具体可以参考相关示例。
	// 下面列举一下 `happypass` 提供的 RequestBody
	// - FormDataBody: 表单键值对请求数据，如 'key1=value1&key2=value2' 这种标准表单结构
	// - MultipartDataBody: Multipart 表单请求数据，可以传递文件与流数据
	// - StreamDataBody: 流数据请求数据，直接读取流中数据作为请求数据
	//
	// * 如果以上请求体数据不能满足你的需求，那么去定义一个继承自 [RequestBody] 的类作为属于你自己的自定义 [RequestBody] 吧！
	request.POST(null);
}
