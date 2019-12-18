import 'dart:async';
import 'dart:io';
import 'dart:convert';

part 'http_mixins.dart';
part 'http_interceptors.dart';
part 'http_decoders.dart';
part 'http_encoders.dart';
part 'http_responses.dart';
part 'request_body.dart';
part 'http_closer.dart';
part 'http_cookie_manager.dart';
part 'http_utils.dart';
part 'http_proxy.dart';

/// 请求状态
/// 1. Prepare 准备状态，在这个阶段中对请求进行一些配置
/// 2. Executing 执行状态，表示该请求正在执行中，但还没有获得结果
/// 3. Executed 执行结束状态，请求任务已经完成
enum _RequestStatus {
    Prepare,
    Executing,
    Executed
}

/// 请求方法
/// 1. GET 请求
/// 2. POST 请求
enum RequestMethod {
    GET,
    POST
}

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

/// 请求对象
/// 对该对象进行配置，然后执行获取请求结果
/// `Request` 不能直接创建，代替的是通过以下方法实例化:
/// 1. [Request.construct]
/// 2. [RequestPrototype.spawn]
/// 如果发送的请求不需要太多配置信息，可以使用 [Request.quickGet] / [Request.quickPost]
/// 方法来发送 `GET / `POST` 请求
class Request extends _BaseRequest {
    Request._();

    /// 构造请求方法
    static Request construct() {
        return Request._();
    }
    
    /// 表示当前请求状态
    _RequestStatus _status = _RequestStatus.Prepare;

    /// 检查当前状态是否处于准备状态
    /// 在这个状态下可以修改全部配置
    bool get checkPrepareStatus => _status.index == _RequestStatus.Prepare.index;

    /// 检查当前状态是否处于执行中状态
    /// 这里的执行中并不是真正执行，该状态表示 Request 已经交由拦截链处理，并未真正生成 Response
    /// 在这个状态下可以修改大部分配置
    bool get checkExecutingStatus => _status.index <= _RequestStatus.Executing.index;
    
    /// 请求完成 Future
    Completer<ResultPassResponse> _requestCompleter;
    
    /// 请求 id
    /// 通常情况下为 null，但是为了满足特定需求需要知晓某个请求的信息，可以为请求设置 id 来进行区分
    dynamic _reqId;

    /// 执行代理接口回调
    /// 请求中部分操作比较耗时，可以设置该代理来实现真实异步执行（比如借助 Isolate）
    AsyncRunProxy _runProxy;

    /// 存放请求拦截器
    List<PassInterceptor> _passInterceptorList = [const BusinessPassInterceptor()];

    /// 存放请求头 Map
    Map<String, String> _headerMap;


    /// 判断是否已经存在 Url 参数
    /// 这个标志取决于拼接 Url 地址时是否追加 `?`
    bool _hasUrlParams = false;

    /// 存放请求地址 Url
    String _url;

    /// 存放请求方法
    RequestMethod _requestMethod;

    /// 存放请求方法所需数据体
    dynamic _body;

    /// 数据编码器
    List<HttpMessageEncoder> _encoderList;

    /// 数据解码器
    List<HttpMessageDecoder> _decoderList;
    
    /// 进度更新回调
    List<HttpResponseDataUpdateCallback> _responseDataUpdateList;
    
    /// 接收原始数据回调
    HttpResponseRawDataReceiverCallback _responseReceiverCallback;
    
    /// 请求中断器
    Set<RequestCloser> _requestCloserSet;

    /// Cookie 管理器
    /// 该对象在克隆时，将会传递引用而不是实例化一个新的对象
    CookieManager _cookieManager;
    
    /// 请求 Http 代理
    List<PassHttpProxy> _httpProxyList;

    /// 请求总超时时间
    /// 包括拦截器处理耗时也会计算到其中
    Duration _totalTimeout;

    /// 请求连接超时时间
    Duration _connectTimeout;

    /// 请求读取超时时间
    Duration _readTimeout;
    
    /// 执行请求
    /// 只有在 [_RequestStatus.Prepare] 状态下才会实际发出请求
    /// 其余条件下均返回第一次执行时的 Future
    Future<ResultPassResponse> doRequest() {
        if(_status != _RequestStatus.Prepare) {
            return _requestCompleter.future;
        }

        _status = _RequestStatus.Executing;
        _requestCompleter = Completer();
        _requestCompleter.complete(_execute());
        return _requestCompleter.future;
    }
    
    /// 实际执行请求逻辑
    /// 借助 [PassInterceptorChain] 完成请求
    /// 缺省情况下，由 [BusinessPassInterceptor] 拦截器完成请求处理逻辑
    Future<ResultPassResponse> _execute() async {
        final interceptorChain = PassInterceptorChain._(this);
        try {
            return await interceptorChain._intercept();
        }
        catch(e) {
            return ErrorPassResponse(msg: "拦截发生异常: $e", error: e);
        }
    }

    /// 创建克隆的请求对象
    /// 该方法只能由 [RequestPrototype.spawn] 方法调用。
    Request _clone() {
        final cloneObj = Request._();
        cloneObj._runProxy = this._runProxy;
        if(this._passInterceptorList != null) {
            cloneObj._passInterceptorList = List.from(this._passInterceptorList);
        }
        if(this._headerMap != null) {
            cloneObj._headerMap = Map.from(this._headerMap);
        }
        cloneObj._url = this._url;
        cloneObj._requestMethod = this._requestMethod;
        cloneObj._body = this._body;
        if(this._encoderList != null) {
            cloneObj._encoderList = List.from(this._encoderList);
        }
        if(this._decoderList != null) {
            cloneObj._decoderList = List.from(this._decoderList);
        }
        cloneObj._cookieManager = this._cookieManager;
        
        if(this._httpProxyList != null) {
            cloneObj._httpProxyList = List.from(this._httpProxyList);
        }
        
        return cloneObj;
    }

    /// 快速进行一次 GET 请求
    /// - url: 请求的地址
    /// - path: 请求的部分路径
    /// - prototype: 请求原型，如果存在，那么会请求会从该原型分裂而来
    /// - configCallback: 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
    /// * [url]、[path]、[prototype] 三者不能同时为 `null`
    static Future<ResultPassResponse> quickGet({
        String url,
        String path,
        RequestPrototype prototype,
        RequestConfigCallback configCallback,
    }) {
        assert(url != null || path != null || prototype != null);
        final request = prototype?.spawn() ?? Request.construct();
        if(url != null) {
            request.setUrl(url);
        }
        if(path != null) {
            request.addPath(path);
        }
        request.GET();
        if(configCallback != null) {
            configCallback(request);
        }
        return request.doRequest();
    }

    /// 快速进行一次 POST 请求
    /// - url: 请求的地址
    /// - path: 请求的部分路径
    /// - body: 请求体，表示 POST 传递的请求数据
    /// - prototype: 请求原型，如果存在，那么会请求会从该原型分裂而来
    /// - configCallback: 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
    /// * [url]、[path]、[prototype] 三者不能同时为 `null`
    /// * [body] 不能为 `null`
    static Future<ResultPassResponse> quickPost({
        String url,
        String path,
        dynamic body,
        RequestPrototype prototype,
        RequestConfigCallback configCallback,
    }) {
        assert(url != null || path != null || prototype != null);
        assert(body != null);
        final request = prototype?.spawn() ?? Request.construct();
        if(url != null) {
            request.setUrl(url);
        }
        if(path != null) {
            request.addPath(path);
        }
        request.POST(body);
        if(configCallback != null) {
            configCallback(request);
        }
        return request.doRequest();
    }
}

/// 请求原型
/// 作为请求的模板，可以快速生成请求对象无需重复配置
/// [RequestPrototype.spawn] 方法可以快速生成配置好的请求参数
/// [RequestPrototype.clone] 方法可以复制一个相同配置的新的请求原型对象
class RequestPrototype extends _BaseRequestPrototype<RequestPrototype> {
    RequestPrototype(): this._prototype = Request._();

    RequestPrototype._fork(Request request): this._prototype = request._clone();

    final Request _prototype;

    @override
    RequestPrototype get _returnObj => this;

    @override
    Request get _buildRequest => _prototype;

    /// 复制一个新的原型，配置与当前配置相同
    RequestPrototype clone() => RequestPrototype._fork(_prototype);

    /// 根据当前配置生成一个 Request 对象
    Request spawn() => _prototype._clone();
}