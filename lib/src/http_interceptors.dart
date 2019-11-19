part of 'http.dart';

/// 拦截器处理链
/// 通过该类完成拦截器的全部工作: 拦截 -> 修改请求 -> 完成请求 -> 返回响应的操作
/// 拦截器采取的方式是首位插入，所以最先添加的拦截器最后执行
/// 正常情况下，拦截器的工作应该如下
/// pass request : E -> D -> C -> B -> A -> BusinessPassInterceptor
/// return response : BusinessPassInterceptor -> A -> B -> C -> D -> E
/// 上述完成了一次拦截工作，Request 的处理和 Response 的构建都在 BusinessPassInterceptor 这个拦截器中完成
/// 如果在特殊情况下，某个拦截器（假设 B）意图自己完成请求处理，那么整个流程如下:
/// pass request : E -> D -> C -> B
/// return response : B -> C -> D -> E
/// 上述在 B 的位置直接拦截，请求并未传递到 BusinessPassInterceptor，所以 Request 的处理和 Response 的构建都应由 B 完成
///
/// 需要注意的是，如果拦截器只是对 Request 进行修改或者观察，并不想实际处理的话，请调用
/// [PassInterceptorChain.waitResponse] 方法，表示将 Request 向下传递，然后将其结果返回表示将 Response 向上返回。
///
/// 便捷方法:
/// [PassInterceptorChain.requestForPassResponse] 将构建好的 Request 通过 HttpClient 的方式转换为 Response(PassResponse)
/// [PassInterceptorChain.modifier] 可以对 Request 进行修改
class PassInterceptorChain{
    PassInterceptorChain._(this._request):
            this._chainRequestModifier = ChainRequestModifier(_request),
            this._interceptors = _request._passInterceptorList,
            this._totalInterceptorCount = _request._passInterceptorList.length ?? 0;

    final Request _request;
    final ChainRequestModifier _chainRequestModifier;
    final List<PassInterceptor> _interceptors;
    final int _totalInterceptorCount;
    int _currentIdx = -1;

    Future<ResultPassResponse> _intercept() async {
        final response = await _waitResponse(0);
        // 没有生成 Response，表示拦截器将请求
        if(response == null) {
            return ErrorPassResponse(msg: "未能生成 Response");
        }

        if(response is ResultPassResponse) {
            return response;
        }

        if(response is ProcessablePassResponse) {
            return SuccessPassResponse(response.body ?? response.bodyData);
        }

        return ErrorPassResponse(msg: "无法识别该 Response");
    }

    Future<PassResponse> _waitResponse(int idx) async {
        if(idx >= _totalInterceptorCount || this._currentIdx >= idx) {
            return null;
        }
        this._currentIdx = idx;
        final currentInterceptor = _interceptors[idx];
        PassResponse response = await currentInterceptor.intercept(this);
        if(response != null) {
            _request._status = _RequestStatus.Executed;
        }

        return response;
    }

    /// 获取拦截链请求修改器
    /// 可以在拦截器中修改请求的大部分参数，直到有 `PassResponse` 返回
    ChainRequestModifier get modifier => this._chainRequestModifier;

    /// 等待其他拦截器返回 `Response`
    Future<PassResponse> waitResponse() async {
        return await _waitResponse(this._currentIdx + 1);
    }

    /// 实际执行 `Request` 获得 `Response`
    /// 提供了一些可选回调，最大限度满足自定义 Request 的自由
    /// 默认情况下，在只在编码与解码时使用了执行代理
    Future<PassResponse> requestForPassResponse({
        /// HttpClient 构造器
        /// 可以自定义 HttpClient 的构造方式
        HttpClient httpClientBuilder(),

        /// HttpClientRequest 构造器
        /// 可以自定义 HttpClientRequest 的构造方式
        Future<HttpClientRequest> httpReqBuilder(HttpClient client, ChainRequestModifier modifier),

        /// HttpClientRequest 消息配置构造
        /// 用于配置请求头，发送请求 Body
        /// 如果该方法返回了 PassResponse，那么该结果将会直接被当做最终结果返回
        PassResponse httpReqInfoBuilder(HttpClientRequest httpReq, ChainRequestModifier modifier),

        /// Response Body 构造器
        /// 可以自行读取响应数据并对其修改，视为最终返回数据
        Future<PassResponse> responseBuilder(HttpClientRequest httpReq, ChainRequestModifier modifier)
    }) async {
        HttpClient client;
        HttpClientRequest httpReq;
        try {
            client = httpClientBuilder != null ? httpClientBuilder() : HttpClient();
            final chainRequestModifier = this.modifier;
            final method = chainRequestModifier.getRequestMethod();

            // 创建请求对象
            if(httpReqBuilder != null) {
                httpReq = await httpReqBuilder(client, chainRequestModifier);
            }
            else {
                final url = chainRequestModifier.getUrl();
                if (method == RequestMethod.POST) {
                    httpReq = await client.postUrl(Uri.parse(url));
                }
                else {
                    httpReq = await client.getUrl(Uri.parse(url));
                }
            }

            PassResponse resultResp;
            if(httpReqInfoBuilder != null) {
                resultResp = httpReqInfoBuilder(httpReq, chainRequestModifier);
            }
            else {
                await chainRequestModifier.fillRequestHeader(httpReq, chainRequestModifier);
                resultResp = await chainRequestModifier.fillRequestBody(httpReq, chainRequestModifier);
            }

            if(resultResp != null) {
                return resultResp;
            }

            PassResponse response;
            if(responseBuilder != null) {
                response = await responseBuilder(httpReq, modifier);
            }
            else {
                response = await chainRequestModifier.analyzeResponse(httpReq, modifier);
            }
            
            if(response == null) {
                return ErrorPassResponse(msg: "未能成功解析 Response");
            }
            
            return response;
        }
        catch(e) {
            return ErrorPassResponse(msg: "请求发生异常: $e", error: e);
        }
        finally {
            if(client != null) {
                try {
                    client.close();
                }
                catch(e){}
                client = null;
            }
        }
    }
}

/// 请求拦截器
/// 用来接收并处理 Request
abstract class PassInterceptor {
    const PassInterceptor();
    Future<PassResponse> intercept(PassInterceptorChain chain);
}

/// 打印请求 Url 拦截器
class LogUrlInterceptor extends PassInterceptor {
    const LogUrlInterceptor();

    @override
    Future<PassResponse> intercept(PassInterceptorChain chain) {
        print("current request url : " + chain.modifier.getUrl());
        return chain.waitResponse();
    }
}

/// 拦截器接口回调
typedef SimplePassInterceptorCallback = Future<PassResponse> Function(PassInterceptorChain chain);

/// 简单的请求拦截器
/// 将拦截的逻辑放到回调闭包中实现
/// 需要注意的是，闭包必须是 `static` 的
class SimplePassInterceptor extends PassInterceptor {
    SimplePassInterceptor(this._callback);
    final SimplePassInterceptorCallback _callback;

    @override
    Future<PassResponse> intercept(PassInterceptorChain chain) => _callback(chain);
}

/// 业务逻辑拦截器
/// 默认实际处理 Request 和生成 Response 的拦截器
class BusinessPassInterceptor extends PassInterceptor {
    const BusinessPassInterceptor();

    @override
    Future<PassResponse> intercept(PassInterceptorChain chain) async {
        return await chain.requestForPassResponse();
    }


}