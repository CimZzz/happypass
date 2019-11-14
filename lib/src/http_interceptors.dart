part of 'http.dart';

/// 拦截器处理链
/// 通过该类完成拦截器的全部工作: 拦截 -> 修改请求 -> 完成请求 -> 返回响应的操作
/// 正常情况下，拦截器的工作应该如下
/// pass request : A -> B -> C -> D -> ... -> BusinessPassInterceptor
/// return response : BusinessPassInterceptor -> ... -> D -> C -> B -> A
/// 上述完成了一次拦截工作，Request 的处理和 Response 的构建都在 BusinessPassInterceptor 这个拦截器中完成
/// 如果在特殊情况下，某个拦截器（假设 D）意图自己完成请求处理，那么整个流程如下:
/// pass request : A -> B -> C -> D
/// return response : D -> C -> B -> A
/// 上述在 D 的位置直接拦截，请求并未传递到 BusinessPassInterceptor，所以 Request 的处理和 Response 的构建
/// 都应由 D 完成
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


    Future<PassResponse> waitResponse() async {
        return await _waitResponse(this._currentIdx + 1);
    }

    Future<PassResponse> requestForPassResponse() async {
        HttpClient client;
        HttpClientRequest httpReq;
        try {
            client = HttpClient();
            final requestBuilder = this.modifier;
            final method = requestBuilder.getRequestMethod();
            final url = requestBuilder.getUrl();

            // 创建请求对象
            if(method == RequestMethod.POST) {
                httpReq = await client.postUrl(Uri.parse(url));
            }
            else {
                httpReq = await client.getUrl(Uri.parse(url));
            }

            // 填充请求头部
            requestBuilder.forEachRequestHeaders((key, value) {
                httpReq.headers.add(key, value);
            });


            // POST 方法会发送请求体
            if(method == RequestMethod.POST) {
                dynamic body = requestBuilder.getRequestBody();
                // POST 方法的 body 不能为 null
                if(body == null) {
                    return ErrorPassResponse(msg: "[POST] \"body\" 不能为 \"null\"");
                }
                // 将发送的消息进行编码，最后转换为 `List<int>` 类型消息
                dynamic message = body;
                ErrorPassResponse errorResp;
                requestBuilder.forEachEncoder((encoder){
                    final oldMessage = message;
                    message = encoder.encode(message);
                    if(message == null) {
                        errorResp = ErrorPassResponse(msg: "[POST] 编码器 $encoder 编码消息 ${oldMessage.runtimeType} 时返回 \"null\"");
                        return false;
                    }
                    return true;
                });

                if(errorResp != null) {
                    return errorResp;
                }

                if(message is! List<int>) {
                    return ErrorPassResponse(msg: "[POST] 最后的编码结果类型不为 \"List<int>\"");
                }

                httpReq.add(message);
            }

            final httpResp = await httpReq.close();

            final List<int> responseBody = List();
            await httpResp.forEach((byteList) {
                responseBody.addAll(byteList);
            });

            dynamic decoderMessage = responseBody;
            requestBuilder.forEachDecoder((decoder) {
                decoderMessage = decoder.decode(decoderMessage);
                if(decoderMessage == null) {
                    return false;
                }
                return true;
            });
            return ProcessablePassResponse(httpResp, responseBody, decoderMessage);
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

/// 拦截器接口回调
typedef SimplePassInterceptorCallback = Future<PassResponse> Function(PassInterceptorChain chain);

/// 简单的请求拦截器
/// 将拦截的逻辑放到回调闭包中实现
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