import 'dart:async';

import 'adapter/http_client.dart';
import 'adapter/http_request.dart';

import 'http_proxy.dart';
import 'http_utils.dart';
import 'http_interceptors.dart';
import 'http_encoders.dart';
import 'http_decoders.dart';
import 'http_responses.dart';
import 'http_closer.dart';
import 'http_errors.dart';
import 'request_body.dart';
import 'request_builder.dart';


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

/// for-each 回调2，无法中断循环
typedef ForeachCallback2<T> = void Function(T data);

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
	RequestOptions();
	
	factory RequestOptions.fetch(RequestBuilder builder) => builder._requestOptions;
	
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
	RequestMethod requestMethod = RequestMethod.GET;
	
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
	
	
	/*Copy flag*/
	
	/// 判断是否需要复制拦截器列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝拦截器列表，只有在修改拦截器列表的时候才会先进行拷贝
	bool needCopyInterceptor = false;
	
	/// 判断是否需要复制编码器列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝编码器列表，只有在修改编码器列表的时候才会先进行拷贝
	bool needCopyEncoderList = false;
	
	/// 判断是否需要复制解码器列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝解码器列表，只有在修改解码器列表的时候才会先进行拷贝
	bool needCopyDecoderList = false;
	
	/// 判断是否需要复制头部表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝头部表，只有在修改头部表的时候才会先进行拷贝
	bool needCopyHeaderMap = false;
	
	/// 判断是否需要复制请求代理列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝请求代理列表，只有在修改请求代理列表的时候才会先进行拷贝
	bool needCopyHttpProxyList = false;
	
	/// 判断是否需要复制请求中断器列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝请求中断器列表，只有在修改请求中断器列表的时候才会先进行拷贝
	bool needCopyRequestCloserList = false;
	
	/// 判断是否需要复制响应数据更新回调列表
	/// 当请求从请求原型孵化出来时，出于性能优化并未拷贝响应数据更新回调列表，只有在修改响应数据更新回调列表的时候才会先进行拷贝
	bool needCopyResponseDataUpdateList = false;
	
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
		cloneObj.resolveUrl = resolveUrl;
		cloneObj.hasUrlParams = hasUrlParams;
		cloneObj.needResolved = needResolved;
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
		
		cloneObj.needCopyInterceptor = true;
		cloneObj.needCopyEncoderList = true;
		cloneObj.needCopyDecoderList = true;
		cloneObj.needCopyHeaderMap = true;
		cloneObj.needCopyHttpProxyList = true;
		cloneObj.needCopyRequestCloserList = true;
		cloneObj.needCopyResponseDataUpdateList = true;
		return cloneObj;
	}
}

abstract class RequestBuilder<ReturnType> {
	
	/// 直接构造，使用默认配置项
	RequestBuilder() : _requestOptions = RequestOptions();
	
	/// 复制子配置项
	RequestBuilder.copyByOther(RequestBuilder operator) : _requestOptions = operator._requestOptions;
	
	/// Fork 子配置项
	RequestBuilder.forkByOther(RequestBuilder operator) : _requestOptions = operator._requestOptions.clone();
	
	/// 请求配置
	final RequestOptions _requestOptions;
	
	/// 返回对象
	ReturnType get _returnObj => this as ReturnType;
}

/// 请求配置配置混合
mixin RequestOptionMixin<ReturnType> on RequestBuilder<ReturnType> {
	
	
	/// 设置请求 id 方法
	/// 为当前请求设置 id
	/// * 请求 id 可以在任何时候设置
	/// * 需要注意的是，id 一经设置，不可更改
	ReturnType setRequestId(dynamic reqId) {
		_requestOptions.reqId ??= reqId;
		return _returnObj;
	}
	
	/// 获取当前请求设置的 id 信息
	dynamic getReqId() {
		return _requestOptions.reqId;
	}
	
	
	/// 获取当前的请求方法
	RequestMethod getRequestMethod() {
		return _requestOptions.requestMethod;
	}
	
	/// 获取自定义的请求方法
	String getCustomRequestMethod() => _requestOptions.customRequestMethod;
	
	
	/// 设置执行请求的代理方法
	/// 应在代理接口中直接调用参数中的回调，不做其他任何操作
	ReturnType setRequestRunProxy(AsyncRunProxy proxy) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.runProxy = proxy;
		}
		
		return _returnObj;
	}
	
	/// 拦截器列表
	List<PassInterceptor> get _passInterceptors {
		if (_requestOptions.needCopyInterceptor) {
			if (_requestOptions.passInterceptorList != null) {
				_requestOptions.passInterceptorList = List.from(_requestOptions.passInterceptorList);
			}
			_requestOptions.needCopyInterceptor = false;
		}
		return _requestOptions.passInterceptorList ??= [];
	}
	
	/// 在首位添加拦截器
	/// 最后添加的拦截器最先被运行
	ReturnType addFirstInterceptor(PassInterceptor interceptor) {
		if (_requestOptions.checkPrepareStatus) {
			_passInterceptors.insert(0, interceptor);
		}
		return _returnObj;
	}
	
	/// 清空全部拦截器
	/// 注意的一点是，默认拦截器列表中存在 [BusinessPassInterceptor] 类作为基础的请求处理拦截器
	ReturnType clearInterceptors() {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.passInterceptorList = null;
		}
		return _returnObj;
	}
	
	/// 获取请求拦截器
	List<PassInterceptor> getPassInterceptors() {
		return List.from(_requestOptions.passInterceptorList);
	}
	
	/// 获取请求拦截器数量
	int getPassInterceptorCount() => _requestOptions.passInterceptorList?.length ?? 0;
	
	/// 头部表
	Map<String, String> get _header {
		if (_requestOptions.needCopyHeaderMap) {
			if (_requestOptions.headerMap != null) {
				_requestOptions.headerMap = Map.from(_requestOptions.headerMap);
			}
			_requestOptions.needCopyHeaderMap = false;
		}
		return _requestOptions.headerMap ??= {};
	}
	
	/// 设置请求头部
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeader(String key, String value) {
		if (key == null) return _returnObj;
		if (_requestOptions.checkExecutingStatus) _header[key.toLowerCase()] = value;
		return _returnObj;
	}
	
	/// 设置请求头部
	/// 通过该方法设置的所有请求头中，`key` 值均会以小写形式存储
	ReturnType setRequestHeaderByMap(Map<String, String> headerMap) {
		if (headerMap == null || headerMap.isEmpty) return _returnObj;
		if (_requestOptions.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key.toLowerCase()] = value;
			});
		}
		return _returnObj;
	}
	
	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeader(String key, String value) {
		if (key == null) return _returnObj;
		if (_requestOptions.checkExecutingStatus) _header[key] = value;
		return _returnObj;
	}
	
	/// 设置自定义请求头部
	/// 通过该方法设置的所有请求头，保留原有 `Key` 值的大小写
	ReturnType setCustomRequestHeaderByMap(Map<String, String> headerMap) {
		if (headerMap == null || headerMap.isEmpty) return _returnObj;
		if (_requestOptions.checkExecutingStatus) {
			headerMap.forEach((key, value) {
				_header[key] = value;
			});
		}
		return _returnObj;
	}
	
	/// 获取请求头部
	/// 该方法会将 `Key` 值转化为小写形式
	String getRequestHeader(String key) => key != null ? _requestOptions?.headerMap[key.toLowerCase()] : null;
	
	/// 获取请求头部
	/// 该方法保留 `Key` 值的大小写形式
	String getCustomRequestHeader(String key) => key != null ? _requestOptions?.headerMap[key] : null;
	
	/// 遍历请求头
	void forEachRequestHeaders(HttpHeaderForeachCallback callback) {
		if (_requestOptions.headerMap != null) {
			_requestOptions.headerMap.forEach((String key, String value) => callback(key, value));
		}
	}
	
	/// 设置请求地址
	ReturnType setUrl(String url) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.url = url;
			// Url 发生变化，需要重新解析
			_requestOptions.needResolved = true;
		}
		return _returnObj;
	}
	
	/// 增加新的路径
	ReturnType addPath(String path) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.url += path;
			// Url 发生变化，需要重新解析
			_requestOptions.needResolved = true;
		}
		return _returnObj;
	}
	
	/// 追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParams(String key, String value, {bool checkFirstParams = true, bool useEncode = true}) {
		if (_requestOptions.checkExecutingStatus) {
			if (key != null && key.isNotEmpty && value != null && value.isNotEmpty) {
				final realValue = useEncode ? Uri.encodeComponent('$value') : value;
				
				if (checkFirstParams && _requestOptions.hasUrlParams != true) {
					_requestOptions.url += '?';
				} else {
					_requestOptions.url += '&';
				}
				_requestOptions.url += '$key=$realValue';
				// Url 发生变化，需要重新解析
				_requestOptions.needResolved = true;
				_requestOptions.hasUrlParams = true;
			}
		}
		return _returnObj;
	}
	
	/// 以 Map 的形式追加 Url 参数
	/// * checkFirstParams 是否检查第一参数，如果该值是当前 url 的第一参数，则会在首部追加 '?' 而不是 '&'
	/// * useEncode 是否对 Value 进行 encode
	ReturnType appendQueryParamsByMap(Map<String, String> map, {bool checkFirstParams = true, bool useEncode = true}) {
		if (_requestOptions.checkExecutingStatus) {
			if (map != null) {
				map.forEach((key, value) {
					appendQueryParams(key, value, checkFirstParams: checkFirstParams, useEncode: useEncode);
				});
			}
		}
		return _returnObj;
	}
	
	/// 获取请求地址
	String getUrl() => _requestOptions.url;
	
	/// 获取 Url 转换过的 HttpUrl 对象
	PassResolveUrl getResolverUrl() {
		if (_requestOptions.needResolved != false) {
			_requestOptions.needResolved = false;
			_requestOptions.resolveUrl = PassHttpUtils.resolveUrl(_requestOptions.url);
		}
		return _requestOptions.resolveUrl;
	}
	
	/// 编码器列表
	List<HttpMessageEncoder> get _encoders {
		if (_requestOptions.needCopyEncoderList) {
			if (_requestOptions.encoderList != null) {
				_requestOptions.encoderList = List.from(_requestOptions.encoderList);
			}
			_requestOptions.needCopyEncoderList = false;
		}
		return _requestOptions.encoderList ??= [];
	}
	
	/// 添加编码器
	/// 新添加的编码器会追加到首位
	/// 建议最好使用 [addLastEncoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstEncoder(HttpMessageEncoder encoder) {
		if (_requestOptions.checkExecutingStatus) {
			_encoders.insert(0, encoder);
		}
		return _returnObj;
	}
	
	/// 添加编码器
	/// 新添加的编码器会追加到末位
	ReturnType addLastEncoder(HttpMessageEncoder encoder) {
		if (_requestOptions.checkExecutingStatus) {
			_encoders.add(encoder);
		}
		return _returnObj;
	}
	
	/// 清空编码器
	ReturnType clearEncoder() {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.encoderList = null;
		}
		return _returnObj;
	}
	
	/// 遍历编码器
	/// 返回 false，中断遍历
	void forEachEncoder(ForeachCallback<HttpMessageEncoder> callback) {
		if (_requestOptions.encoderList != null) {
			var count = _requestOptions.encoderList.length;
			for (var i = 0; i < count; i++) {
				final encoder = _requestOptions.encoderList[i];
				if (!callback(encoder)) {
					break;
				}
			}
		}
	}
	
	/// 解码器列表
	List<HttpMessageDecoder> get _decoders {
		if (_requestOptions.needCopyDecoderList) {
			if (_requestOptions.decoderList != null) {
				_requestOptions.decoderList = List.from(_requestOptions.decoderList);
			}
			_requestOptions.needCopyDecoderList = false;
		}
		return _requestOptions.decoderList ??= [];
	}
	
	/// 添加解码器
	/// 新添加的解码器会追加到首位
	/// 建议最好使用 [addLastDecoder]，以免造成逻辑混乱
	@deprecated
	ReturnType addFirstDecoder(HttpMessageDecoder decoder) {
		if (_requestOptions.checkExecutingStatus) {
			_decoders.insert(0, decoder);
		}
		return _returnObj;
	}
	
	/// 添加解码器
	/// 新添加的解码器会追加到末位
	ReturnType addLastDecoder(HttpMessageDecoder decoder) {
		if (_requestOptions.checkExecutingStatus) {
			_decoders.add(decoder);
		}
		return _returnObj;
	}
	
	/// 清空解码器
	ReturnType clearDecoder() {
		if (_requestOptions.checkExecutingStatus) _requestOptions.decoderList = null;
		return _returnObj;
	}
	
	/// 遍历解码器
	/// 返回 false，中断遍历
	void forEachDecoder(ForeachCallback<HttpMessageDecoder> callback) {
		if (_requestOptions.decoderList != null) {
			final count = _requestOptions.decoderList.length;
			for (var i = 0; i < count; i++) {
				final decoder = _requestOptions.decoderList[i];
				if (!callback(decoder)) {
					break;
				}
			}
		}
	}
	
	/// 配置 `utf8` 字符串编解码器，形成字符串通道
	/// 该方法会将之前全部编解码器清空
	ReturnType stringChannel() {
		if (_requestOptions.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
		}
		return _returnObj;
	}
	
	/// 配置 `json` 编解码器，形成 json 通道
	/// 该方法会将之前全部编解码器清空
	ReturnType jsonChannel() {
		if (_requestOptions.checkExecutingStatus) {
			clearEncoder();
			clearDecoder();
			addLastEncoder(const JSON2Utf8StringEncoder());
			addLastEncoder(const Utf8String2ByteEncoder());
			addLastDecoder(const Byte2Utf8StringDecoder(isAllowMalformed: true));
			addLastDecoder(const Utf8String2JSONDecoder());
		}
		return _returnObj;
	}
	
	/// 响应数据更新回调列表
	List<HttpResponseDataUpdateCallback> get _responseDataUpdates {
		if (_requestOptions.needCopyResponseDataUpdateList) {
			if (_requestOptions.responseDataUpdateList != null) {
				_requestOptions.responseDataUpdateList = List.from(_requestOptions.responseDataUpdateList);
			}
			_requestOptions.needCopyResponseDataUpdateList = false;
		}
		return _requestOptions.responseDataUpdateList ??= [];
	}
	
	/// 添加新的回调
	/// 每当接收数据更新时，都会触发该回调接口，来通知当前数据获取的进度
	ReturnType addResponseDataUpdate(HttpResponseDataUpdateCallback callback) {
		if (_requestOptions.checkPrepareStatus) {
			_responseDataUpdates.add(callback);
		}
		return _returnObj;
	}
	
	/// 配置接收响应报文原始数据接口
	ReturnType setResponseRawDataReceiverCallback(HttpResponseRawDataReceiverCallback callback) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.responseReceiverCallback = callback;
		}
		return _returnObj;
	}
	
	/// 判断是否存在接收响应报文原始数据接口
	bool existResponseRawDataReceiverCallback() => _requestOptions.responseReceiverCallback != null;
	
	/// 请求中断器列表
	Set<RequestCloser> get _requestClosers {
		if (_requestOptions.needCopyRequestCloserList) {
			if (_requestOptions.requestCloserSet != null) {
				_requestOptions.requestCloserSet = Set.from(_requestOptions.requestCloserSet);
			}
			_requestOptions.needCopyRequestCloserList = false;
		}
		return _requestOptions.requestCloserSet ??= <RequestCloser>{};
	}
	
	/// 添加请求中断器
	ReturnType addRequestCloser(RequestCloser requestCloser) {
		if (_requestOptions.checkExecutingStatus) {
			_requestClosers.add(requestCloser);
		}
		return _returnObj;
	}
	
	/// 请求代理列表
	List<PassHttpProxy> get _httpProxies {
		if (_requestOptions.needCopyHttpProxyList) {
			if (_requestOptions.httpProxyList != null) {
				_requestOptions.httpProxyList = List.from(_requestOptions.httpProxyList);
			}
			_requestOptions.needCopyHttpProxyList = false;
		}
		return _requestOptions?.httpProxyList ??= [];
	}
	
	/// 添加请求 Http 代理
	ReturnType addHttpProxy(String host, int port) {
		if (_requestOptions.checkExecutingStatus) {
			final proxy = PassHttpProxy(host, port);
			if (!_httpProxies.contains(proxy)) {
				_httpProxies.add(proxy);
			}
		}
		
		return _returnObj;
	}
	
	/// 移除指定的请求 Http 代理
	ReturnType removeHttpProxy(String host, int port) {
		if (_requestOptions.checkExecutingStatus && _requestOptions.httpProxyList != null) {
			final proxy = PassHttpProxy(host, port);
			_httpProxies.remove(proxy);
			if (_httpProxies.isEmpty) {
				_requestOptions.httpProxyList = null;
			}
		}
		
		return _returnObj;
	}
	
	/// 移除全部相同 host 的请求 Http 代理
	ReturnType removeHttpProxyByHost(String host) {
		if (_requestOptions.checkExecutingStatus && _requestOptions.httpProxyList != null) {
			_httpProxies.removeWhere((proxy) {
				return proxy.host == host;
			});
			if (_httpProxies.isEmpty) {
				_requestOptions.httpProxyList = null;
			}
		}
		
		return _returnObj;
	}
	
	/// 获取指定 Host 下全部的请求 Http 代理
	List<PassHttpProxy> getPassHttpProxiesByHost(String host) {
		List<PassHttpProxy> list;
		if (_requestOptions.httpProxyList != null) {
			_requestOptions.httpProxyList.forEach((proxy) {
				if (proxy.host == host) {
					list ??= [];
					list.add(proxy);
				}
			});
		}
		
		return list;
	}
	
	/// 获取全部请求 Http 代理
	List<PassHttpProxy> getPassHttpProxies() {
		if (_requestOptions.httpProxyList != null) {
			return List.from(_requestOptions.httpProxyList);
		}
		else {
			return null;
		}
	}
	
	/// 遍历请求 Http 代理
	void forEachPassHttpProxies(ForeachCallback<PassHttpProxy> callback) {
		if (_requestOptions.httpProxyList != null) {
			final proxyList = _requestOptions.httpProxyList;
			final count = proxyList.length;
			for (var i = 0; i < count; i ++) {
				if (!callback(proxyList[i])) {
					break;
				}
			}
		}
	}
	
	/// 设置请求总超时时间
	/// 包括拦截器处理耗时也会计算到其中
	ReturnType setTotalTimeOut(Duration timeOut) {
		if (_requestOptions.checkPrepareStatus) {
			_requestOptions.totalTimeout = timeOut;
		}
		return _returnObj;
	}
	
	/// 设置连接超时时间
	ReturnType setConnectTimeOut(Duration timeOut) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.connectTimeout = timeOut;
		}
		return _returnObj;
	}
	
	/// 设置读取超时时间
	ReturnType setReadTimeOut(Duration timeOut) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.readTimeout = timeOut;
		}
		return _returnObj;
	}
	
	/// 获取请求连接超时时间
	/// 包括拦截器处理耗时也会计算到其中
	Duration getTotalTimeout() {
		return _requestOptions.totalTimeout;
	}
	
	/// 获取请求连接超时时间
	Duration getConnectTimeout() {
		return _requestOptions.connectTimeout;
	}
	
	/// 获取请求读取超时时间
	Duration getReadTimeout() {
		return _requestOptions.readTimeout;
	}
	
	/// 设置 PassHttpClient
	ReturnType setHttpClient(PassHttpClient client) {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.passHttpClient = client;
		}
		return _returnObj;
	}
	
	/// 获取 PassHttpClient
	/// 仅返回配置的 HttpClient
	PassHttpClient getHttpClient() {
		return _requestOptions.passHttpClient;
	}
	
	/// 将当前请求状态标记为已执行
	void markRequestExecuted() {
		_requestOptions.status = RequestStatus.Executed;
	}
	
	/// 将当前请求状态标记为已执行
	void markRequestExecuting() {
		_requestOptions.status = RequestStatus.Executing;
	}
	
	/// 检查当前状态是否处于准备状态
	/// 在这个状态下可以修改全部配置
	bool checkPrepareStatus() => _requestOptions.checkPrepareStatus;
	
	/// 检查当前状态是否处于执行中状态
	/// 这里的执行中并不是真正执行，该状态表示 Request 已经交由拦截链处理，并未真正生成 Response
	/// 在这个状态下可以修改大部分配置
	bool checkExecutingStatus() => _requestOptions.checkExecutingStatus;
	
	
	
	
	/// 获取当前的请求 Body（只在 Post 方法下存在该值）
	dynamic getRequestBody() {
		return _requestOptions.body;
	}
}

/// 请求方法配置混合
mixin RequestBodyMixin<ReturnType> on RequestBuilder<ReturnType> {
	/// 设置 GET 请求
	ReturnType GET() {
		if (_requestOptions.checkExecutingStatus) {
			_requestOptions.customRequestMethod = null;
			_requestOptions.requestMethod = RequestMethod.GET;
			_requestOptions.body = null;
		}
		return _returnObj;
	}
	
	/// 设置 POST 请求
	/// body 不能为 `null`
	ReturnType POST(dynamic body) {
		if (_requestOptions.checkExecutingStatus && body != null) {
			_requestOptions.customRequestMethod = null;
			_requestOptions.requestMethod = RequestMethod.POST;
			_requestOptions.body = body;
		}
		return _returnObj;
	}
	
	/// 设置自定义请求方法
	/// 可以选择是否传送 body
	ReturnType CUSTOM(String method, {dynamic body}) {
		if (_requestOptions.checkExecutingStatus && body != null) {
			_requestOptions.customRequestMethod = method;
			_requestOptions.requestMethod = RequestMethod.CUSTOM;
			_requestOptions.body = body;
		}
		return _returnObj;
	}
}

/// 请求操作混合
mixin RequestOperatorMixin<ReturnType> on RequestOptionMixin<ReturnType> {
	/// 通过配置的执行代理执行回调
	/// 注意的是，回调必须为 `static`
	Future<Q> runProxy<T, Q>(AsyncRunProxyCallback<T, Q> callback, T message) async {
		final runProxy = _requestOptions.runProxy;
		if (runProxy != null) {
			return await runProxy(callback, message);
		}
		
		return callback(message);
	}
	
	/// 将配置好的请求头部填充到 PassHttpRequest 中
	void fillRequestHeader(PassHttpRequest httpReq, {bool useProxy = true}) async {
		final bundle = _HeaderBundle(httpReq, this);
		if (useProxy) {
			await runProxy(_fillHeaders, bundle);
		} else {
			await _fillHeaders(bundle);
		}
	}
	
	/// 用于填充头部的静态方法
	static Future _fillHeaders(_HeaderBundle bundle) async {
		final httpReq = bundle._request;
		bundle._requestBuilder.forEachRequestHeaders(httpReq.setRequestHeader);
	}
	
	/// 使用现有的编码器进行消息编码
	/// - useProxy: 是否使用请求运行代理
	FutureOr<dynamic> encodeMessage(dynamic message, {bool useProxy = true}) {
		final encoders = _requestOptions.encoderList;
		if (encoders == null) {
			// 不存在编码器，直接返回 message
			return message;
		}
		final bundle = _EncodeBundle(message, encoders);
		if (useProxy) {
			/// 使用请求运行代理执行编码工作
			return runProxy(_encodeMessage, bundle);
		} else {
			return _encodeMessage(bundle);
		}
	}
	
	/// 实际 encode 消息方法
	static Future<dynamic> _encodeMessage(_EncodeBundle bundle) async {
		var message = bundle._message;
		
		final count = bundle._encoderList.length;
		for (var i = 0; i < count; i++) {
			final encoder = bundle._encoderList[i];
			final oldMessage = message;
			message = encoder.encode(message);
			message ??= oldMessage;
		}
		
		return message;
	}
	
	/// 将配置好的 Body 填充到 PassHttpRequest 中，如果 Body 在处理过程中发生错误，则会直接返回抛出异常
	/// 可以选择是否使用代理，编码
	/// 默认情况下，使用编码与代理
	/// - httpReq: PassHttpRequest 对象
	/// - modifier: 拦截链请求修改器
	/// - useEncode: 是否对数据进行编码
	/// - useProxy: 是否在编码的过程中使用请求执行代理
	Future<void> fillRequestBody(PassHttpRequest httpReq, {bool useEncode = true, bool useProxy = true}) async {
		dynamic body = getRequestBody();
		if (body == null) {
			return;
		}
		
		if (body is RequestBody) {
			// 当请求体是 RequestBody 时，会覆盖 Content-Type 字段
			final requestBody = body;
			final contentType = requestBody.contentType;
			if (contentType != null) {
				final overrideContentType = requestBody.overrideContentType;
				if (overrideContentType == true || httpReq.getRequestHeader('content-type') == null) {
					httpReq.setRequestHeader('content-type', contentType);
				}
			}
			
			await for (var message in body.provideBodyData()) {
				if (message is RawBodyData) {
					message = message.rawData;
				} else if (useEncode) {
					message = await encodeMessage(message, useProxy: useProxy);
				}
				
				if (!httpReq.checkDataLegal(message)) {
					throw HappyPassError('请求 \'body\' 数据类型非法: ${message.runtimeType}');
				}
				
				httpReq.sendData(message);
			}
		} else {
			// 当请求体不是 RequestBody 时
			dynamic message = body;
			if (message is RawBodyData) {
				message = message.rawData;
			} else if (useEncode) {
				message = await encodeMessage(message, useProxy: useProxy);
			}
			
			if (!httpReq.checkDataLegal(message)) {
				throw HappyPassError('请求 \'body\' 数据类型非法: ${message.runtimeType}');
			}
			
			httpReq.sendData(message);
		}
	}
	
	/// 使用现有的解码器进行消息解码
	/// - useProxy: 是否使用请求运行代理
	FutureOr<dynamic> decodeMessage(dynamic message, {bool useProxy = true}) {
		final decoders = _requestOptions.decoderList;
		if (decoders == null) {
			// 不存在解码器，直接返回消息
			return message;
		}
		
		final bundle = _DecodeBundle(message, _requestOptions.decoderList);
		if (useProxy) {
			return runProxy(_decodeMessage, bundle);
		} else {
			return _decodeMessage(bundle);
		}
	}
	
	/// 实际 decode 消息方法
	static Future<dynamic> _decodeMessage(_DecodeBundle bundle) async {
		dynamic decoderMessage = bundle._message;
		final decoders = bundle._decoderList;
		
		final count = decoders.length;
		for (var i = 0; i < count; i++) {
			final decoder = decoders[i];
			decoderMessage = decoder.decode(decoderMessage);
			if (decoderMessage == null) {
				break;
			}
		}
		
		return decoderMessage;
	}
	
	/// 从 PassHttpRequest 中获取 PassHttpResponse，并读取其全部 Byte 数据存入 List<int> 中
	/// 如果 Body 在处理过程中发生错误，则会直接抛出异常
	/// 可以选择是否使用代理，编码
	/// 默认情况下，开始编码与代理
	/// - httpReq: 使用 `PassHttpRequest` 获取响应数据进行解析
	/// - httpResp: 直接使用 `PassHttpResponse` 进行解析
	/// - useDecode: 表示是否使用解码器处理数据
	/// - useProxy: 表示使用使用请求执行代理来解码数据
	/// - doNotify: 表示是否通知响应数据接收进度
	Future<PassResponse> analyzeResponse(PassHttpRequest httpReq, {bool useDecode = true, bool useProxy = true, bool doNotify = true}) async {
		final httpResp = await httpReq.fetchHttpResponse();
		
		// 标记当前请求已经执行完成
		markRequestExecuted();
		
		
		final responseBody = <int>[];
		if (doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final totalLength = httpResp.contentLength;
			var curLength = 0;
			// 接收之前先触发一次空进度通知
			notifyResponseDataUpdate(curLength, totalLength: totalLength);
			await httpResp.bodyStream.forEach((byteList) {
				responseBody.addAll(byteList);
				// 每当接收到新数据时，进行通知更新
				curLength += byteList.length;
				notifyResponseDataUpdate(curLength, totalLength: totalLength);
			});
		} else {
			// 不进行通知，直接获取响应数据
			await httpResp.bodyStream.forEach((byteList) {
				responseBody.addAll(byteList);
			});
		}
		
		dynamic decodeObj = responseBody;
		if (useDecode) {
			decodeObj = await decodeMessage(decodeObj, useProxy: useProxy);
		}
		
		final processableResponse = ProcessablePassResponse(responseBody, decodeObj);
		processableResponse.assembleResponse(httpResp);
		return processableResponse;
	}
	
	/// 从 PassHttpRequest 中获取 PassHttpResponse，并读取其全部 Byte 数据全部传输到
	/// [HttpResponseRawDataReceiverCallback] 中处理，如果 Body 在处理过程中发生错误，
	/// 则会直接抛出异常
	///
	/// - httpReq: 使用 `PassHttpRequest` 获取响应数据进行解析
	/// - doNotify: 表示是否通知响应数据接收进度
	Future<PassResponse> analyzeResponseByReceiver(PassHttpRequest httpReq, {bool doNotify = true}) async {
		final httpResp = await httpReq.fetchHttpResponse();
		
		Stream<List<int>> rawByteDataStream;
		// 标记当前请求已经执行完成
		markRequestExecuted();
		if (doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final totalLength = httpResp.contentLength;
			var curLength = 0;
			// 接收之前先触发一次空进度通知
			notifyResponseDataUpdate(curLength, totalLength: totalLength);
			Stream<List<int>> rawByteStreamWrap(Stream<List<int>> rawStream) async* {
				await for (var byteList in rawStream) {
					// 每当接收到新数据时，进行通知更新
					curLength += byteList.length;
					notifyResponseDataUpdate(curLength, totalLength: totalLength);
					yield byteList;
				}
			}
			
			rawByteDataStream = rawByteStreamWrap(httpResp.bodyStream);
		} else {
			// 不进行通知，直接获取响应数据
			rawByteDataStream = httpResp.bodyStream;
		}
		
		PassResponse passResponse;
		final result = await transferRawDataForRawDataReceiver(rawByteDataStream);
		
		if (result is PassResponse) {
			if (result is ProcessablePassResponse) {
				result.assembleResponse(httpResp);
			}
			else if (result is SuccessPassResponse) {
				result.assembleResponse(httpResp);
			}
			passResponse = result;
		} else {
			final processableResponse = ProcessablePassResponse(null, result);
			processableResponse.assembleResponse(httpResp);
			passResponse = processableResponse;
		}
		
		// 如果接收完毕但没有返回应有的响应对象，那么会返回一个 `ErrorPassResponse` 表示处理出错
		return passResponse;
	}
	
	
	/// 通知相应数据接收进度
	/// 每当接收到新的数据时，都应触发该方法
	/// 如果总长度未知，则不应传总长度参数
	void notifyResponseDataUpdate(int length, {int totalLength = -1}) {
		// 除非总长度总长度未知，否则接收的数据长度不应超过总长度
//		if (length > totalLength && totalLength != -1) {
//			if (Request.DEBUG) {
//				print('[WARN] ${_buildRequest.getUrl()}: recv length over total length!');
//			}
//		}
		
		_requestOptions.responseDataUpdateList?.forEach((callback) {
			callback(length, totalLength);
		});
	}
	
	
	/// 调用接收响应原始数据接口，将 Future 直接返回
	/// 该方法并未在执行代理中执行
	Future<dynamic> transferRawDataForRawDataReceiver(Stream<List<int>> rawDataStream) {
		if (_requestOptions.responseReceiverCallback != null) {
			return _requestOptions.responseReceiverCallback(rawDataStream);
		}
		return null;
	}
	
	/// 在总超时时间内没有完成请求，返回错误响应结果
	Future<PassResponse> runInTotalTimeout(Future<PassResponse> call) {
		if (_requestOptions.totalTimeout != null) {
			return call.timeout(_requestOptions.totalTimeout, onTimeout: () {
				// 如果超时则抛出异常
				return ErrorPassResponse(msg: 'total time out');
			});
		}
		
		return call;
	}
	
	/// 填充紧迫超时时间
	/// 设置当前超时时间为: 连接超时 + 读写超时 + 200ms 额外处理时间
	void fillTightTimeout(PassHttpClient client) {
		final connectTimeout = _requestOptions.connectTimeout;
		final readTimeout = _requestOptions.readTimeout;
		
		if (connectTimeout != null && readTimeout != null) {
			// 存在连接超时和读写超时
			client.connectionTimeout = connectTimeout;
			client.idleTimeout = connectTimeout + readTimeout + const Duration(milliseconds: 200);
		} else if (connectTimeout != null) {
			// 仅存在连接超时，不会设置总超时时间
			client.connectionTimeout = connectTimeout;
		} else if (readTimeout != null) {
			// 仅存在读写超时，设置总超时时间
			// * 默认连接超时时间为 15 秒
			client.idleTimeout = const Duration(seconds: 15) + readTimeout + const Duration(milliseconds: 200);
		} else {
			// 其余情况将不会设置超时时间
		}
	}
	
	/// 填充宽松超时时间
	/// 设置当前超时时间为: (连接超时 + 读写时间 + 200ms 额外处理时间) * 2
	/// 这么做的目的是为了由我们接管超时处理逻辑
	void fillLooseTimeout(PassHttpClient client) {
		final connectTimeout = _requestOptions.connectTimeout;
		final readTimeout = _requestOptions.readTimeout;
		
		if (connectTimeout != null && readTimeout != null) {
			// 存在连接超时和读写超时
			client.connectionTimeout = connectTimeout;
			client.idleTimeout = (connectTimeout + readTimeout + const Duration(milliseconds: 200)) * 2;
		} else if (connectTimeout != null) {
			// 仅存在连接超时，不会设置总超时时间
			client.connectionTimeout = connectTimeout * 2;
		} else if (readTimeout != null) {
			// 仅存在读写超时，设置总超时时间
			// * 默认连接超时时间为 15 秒
			client.idleTimeout = (const Duration(seconds: 15) + readTimeout + const Duration(milliseconds: 200)) * 2;
		} else {
			// 其余情况将不会设置超时时间
		}
	}
	
	/// 在连接超时时间内完成指定操作，如果超时则抛出异常
	/// 先用 PassHttpClient 的超时时间，如果 PassHttpClient 不存在，则使用请求中的超时时间
	Future<T> runInConnectTimeout<T>(Future<T> call) {
		final contentTimeOut = _requestOptions.passHttpClient?.connectionTimeout ?? _requestOptions.connectTimeout;
		if (contentTimeOut != null) {
			final completer = Completer<T>();
			call = call.timeout(contentTimeOut, onTimeout: () {
				if (!completer.isCompleted) {
					completer.completeError('connect time out');
				}
				return null;
			});
			call.then((data) {
				if (!completer.isCompleted) {
					completer.complete(data);
				}
			});
			call.catchError((error, stacktrace) {
				if (!completer.isCompleted) {
					completer.completeError(error, stacktrace);
				}
			});
			
			return completer.future;
		}
		
		return call;
	}
	
	/// 在连接超时时间内完成指定操作，如果超时则抛出异常
	/// 以闭包的形式包装
	Future<T> runInConnectTimeoutByClosure<T>(FutureBuilder<T> builder) {
		return runInConnectTimeout(builder());
	}
	
	/// 在读取超时时间内完成指定操作，如果超时则抛出异常
	Future<T> runInReadTimeout<T>(Future<T> call) {
		if (_requestOptions.readTimeout != null) {
			final completer = Completer<T>();
			call = call.timeout(_requestOptions.readTimeout, onTimeout: () {
				if (!completer.isCompleted) {
					completer.completeError('read time out');
				}
				return null;
			});
			call.then((data) {
				if (!completer.isCompleted) {
					completer.complete(data);
				}
			});
			call.catchError((error, stacktrace) {
				if (!completer.isCompleted) {
					completer.completeError(error, stacktrace);
				}
			});
			
			return completer.future;
		}
		
		return call;
	}
	
	/// 在读取超时时间内完成指定操作，如果超时则抛出异常
	/// 以闭包的形式包装
	Future<T> runInReadTimeoutByClosure<T>(FutureBuilder<T> builder) {
		return runInReadTimeout(builder());
	}
}


/// 用于包装需要填充的请求和请求头的数据集
class _HeaderBundle {
	_HeaderBundle(this._request, this._requestBuilder);
	
	final PassHttpRequest _request;
	final RequestOptionMixin _requestBuilder;
}


/// 用于包装需要编码的消息和编码器的数据集
class _EncodeBundle {
	const _EncodeBundle(this._message, this._encoderList);
	
	final dynamic _message;
	final List<HttpMessageEncoder> _encoderList;
}

/// 用于包装需要解码的消息和解码器的数据集
class _DecodeBundle {
	const _DecodeBundle(this._message, this._decoderList);
	
	final dynamic _message;
	final List<HttpMessageDecoder> _decoderList;
}