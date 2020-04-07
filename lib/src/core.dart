import 'dart:async';
import 'package:happypass/src/http_mock_interceptor.dart';

import 'adapter/http_client.dart';
import 'adapter/http_request.dart';
import 'adapter/http_response.dart';

import 'http_proxy.dart';
import 'http_utils.dart';
import 'http_interceptors.dart';
import 'request_builder.dart';
import 'http_encoders.dart';
import 'http_decoders.dart';

part 'http_mixins_builder.dart';
part 'http_mixins_getter.dart';
part 'http_mixins_operator.dart';

/// 请求执行代理回调接口
typedef AsyncRunProxyCallback<T, Q> = Future<Q> Function(T);

/// 请求执行代理接口
typedef AsyncRunProxy = Future Function<T, Q>(AsyncRunProxyCallback<T, Q>, T);

/// 接收响应报文进度回调接口
typedef HttpResponseDataUpdateCallback = void Function(int length, int totalLength);

/// 接收响应报文原始数据接口
typedef HttpResponseRawDataReceiverCallback = Future<dynamic> Function(Stream<List<int>> rawData);

/// 快速请求处理回调
typedef RequestConfigCallback = void Function(Request request);

/// for-each 回调
typedef ForeachCallback<T> = bool Function(T data);

/// 请求头部 for-each 回调
typedef HttpHeaderForeachCallback = void Function(String key, String value);

/// Future 构造回调
typedef FutureBuilder<T> = Future<T> Function();

/// 请求 body 编码回调
/// 经过编码的数据传递到该回调中
typedef RequestBodyEncodeCallback = void Function(dynamic message);

/// 请求状态
/// 1. Prepare 准备状态，在这个阶段中对请求进行一些配置
/// 2. Executing 执行状态，表示该请求正在执行中，但还没有获得结果
/// 3. Executed 执行结束状态，请求任务已经完成
enum RequestStatus { Prepare, Executing, Executed }

/// 请求方法
/// 1. GET 请求
/// 2. POST 请求
/// 3. 自定义请求方法
enum RequestMethod { GET, POST, CUSTOM }

/// 请求设置选项
class RequestOptions {
	/// 表示当前请求状态
	RequestStatus status = RequestStatus.Prepare;

	/// 检查当前状态是否处于准备状态
	/// 在这个状态下可以修改全部配置
	bool get checkPrepareStatus => status.index == RequestStatus.Prepare.index;

	/// 检查当前状态是否处于执行中状态
	/// 这里的执行中并不是真正执行，该状态表示 Request 已经交由拦截链处理，并未真正生成 Response
	/// 在这个状态下可以修改大部分配置
	bool get checkExecutingStatus => status.index <= RequestStatus.Executing.index;

	/// 请求 id
	/// 通常情况下为 null，但是为了满足特定需求需要知晓某个请求的信息，可以为请求设置 id 来进行区分
	dynamic reqId;

	/// 执行代理接口回调
	/// 请求中部分操作比较耗时，可以设置该代理来实现真实异步执行（比如借助 Isolate）
	AsyncRunProxy runProxy;

	/// 存放请求拦截器
	List<PassInterceptor> passInterceptorList = [const BusinessPassInterceptor()];

	/// 存放请求头 Map
	Map<String, String> headerMap;

	/// 判断是否已经存在 Url 参数
	/// 这个标志取决于拼接 Url 地址时是否追加 `?`
	bool hasUrlParams;

	/// 存放请求地址 Url
	String url;

	/// 判断 Url 是否发生变化，需要重新解析 [resolveUrl]
	/// 与 [resolveUrl] 组合使用
	bool needResolved;

	/// 存放解析过的 Url
	/// 每次 url 发生变化时，该值会重置为 null，下次使用时重新生成
	/// * 解析过程需要一些计算操作，这样的做的目的是为了缓存当前 url 对应的解析结果，优化了效率
	PassResolveUrl resolveUrl;

	/// 存放请求方法
	RequestMethod requestMethod;

	/// 存放自定义请求方法
	String customRequestMethod;

	/// 存放请求方法所需数据体
	dynamic body;

	/// 数据编码器
	List<HttpMessageEncoder> encoderList;

	/// 数据解码器
	List<HttpMessageDecoder> decoderList;

	/// 进度更新回调
	List<HttpResponseDataUpdateCallback> responseDataUpdateList;

	/// 接收原始数据回调
	HttpResponseRawDataReceiverCallback responseReceiverCallback;

	/// 请求中断器
	Set<RequestCloser> requestCloserSet;

	/// 请求 Http 代理
	List<PassHttpProxy> httpProxyList;

	/// 请求总超时时间
	/// 包括拦截器处理耗时也会计算到其中
	Duration totalTimeout;

	/// 请求连接超时时间
	Duration connectTimeout;

	/// 请求读取超时时间
	Duration readTimeout;

	/// HttpClient
	PassHttpClient passHttpClient;

	/// 创建克隆的请求对象
	/// 该方法只能由 [RequestPrototype.spawn] 方法调用。
	RequestOptions clone() {
		final cloneObj = RequestOptions();
		cloneObj.runProxy = runProxy;
		if (passInterceptorList != null) {
			cloneObj.passInterceptorList = List.from(passInterceptorList);
		}
		if (headerMap != null) {
			cloneObj.headerMap = Map.from(headerMap);
		}
		cloneObj.url = url;
		cloneObj.requestMethod = requestMethod;
		cloneObj.body = body;
		if (encoderList != null) {
			cloneObj.encoderList = List.from(encoderList);
		}
		if (decoderList != null) {
			cloneObj.decoderList = List.from(decoderList);
		}

		if (httpProxyList != null) {
			cloneObj.httpProxyList = List.from(httpProxyList);
		}

		cloneObj.totalTimeout = totalTimeout;
		cloneObj.connectTimeout = connectTimeout;
		cloneObj.readTimeout = readTimeout;

		cloneObj.passHttpClient = passHttpClient;

		return cloneObj;
	}
}

/// 请求操作混合基类
/// 用来操作请求配置参数
mixin RequestOperatorMixBase {
	/// 所构建的请求
	RequestOptions get _requestOptions;
}

/// 请求混合基类
mixin RequestMixinBase<ReturnType> implements RequestOperatorMixBase {
	/// 代理对象
	ReturnType get returnObj;
}

/// 请求对象基类，持有一个 RequestOptions
/// 全部请求对象都应该继承自此类
abstract class BaseRequestOperator implements RequestOperatorMixBase {
	BaseRequestOperator();

	BaseRequestOperator.createByOther(BaseRequestOperator operator): _options = operator._options;

	BaseRequestOperator.forkByOther(BaseRequestOperator operator): _options = operator._options.clone();

	RequestOptions _options;

	@override
	RequestOptions get _requestOptions => _options ??= RequestOptions();
}

