import '../http.dart';
import 'http_client.dart';
import 'http_request.dart';

import 'request_process.dart' as _processor;

final HttpProcessor processor = HttpProcessor();

class HttpProcessor implements _processor.HttpProcessor {
	
	/// 默认情况下，在只在编码与解码时使用了执行代理
	@override
	Future<PassResponse> request(ChainRequestModifier modifier) async {
		var httpClient = modifier.getHttpClient();
		// 用来判断 Http Client 是不是临时对象
		// 如果是的话，那么在请求结束后会被强制关闭
		bool isTempHttpClient = httpClient == null;
		PassHttpRequest httpReq;
		try {
			final chainRequestModifier = modifier;
			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				return null;
			}

			// 未配置 HttpClient，需要生成一个临时的 HttpClient
			if(isTempHttpClient) {
				httpClient = PassHttpClient();
				// 设置宽松的超时时间，目的是为了由我们接管超时处理逻辑
				chainRequestModifier.fillLooseTimeout(httpClient);
				// 配置 HTTP 请求代理
				httpClient.httpProxy = chainRequestModifier.getPassHttpProxies();
				// 装配 `HttpClient`，保证中断器可以正常中断请求
				// 只有临时 HttpClient 才会被中断器强制关闭；预置的不会被强制中断
				chainRequestModifier.assembleHttpClient(httpClient);
			}

			final url = chainRequestModifier.getUrl();
			final method = chainRequestModifier.getRequestMethod();

			httpReq = await httpClient.fetchHttpRequest(method, url);
			// 装配 `PassHttpRequest`，保证中断器可以正常中断请求
			chainRequestModifier.assembleHttpRequest(httpReq);

			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				return null;
			}

			final fillHeaderFuture = chainRequestModifier.fillRequestHeader(httpReq, chainRequestModifier, useProxy: false);
			final fillBodyFuture = chainRequestModifier.fillRequestBody(httpReq, chainRequestModifier, useProxy: false, sendOnce: true);

			// 等待填充头部和填充请求 Body 完成
			await fillHeaderFuture;
			await fillBodyFuture;
			
			PassResponse response;
			if (chainRequestModifier.existResponseRawDataReceiverCallback()) {
				// 如果存在响应数据原始接收回调
				// 执行 [analyzeResponseByReceiver] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponseByReceiver(httpReq, modifier));
			} else {
				// 执行 [analyzeResponse] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponse(httpReq, modifier));
			}
			httpReq = null;
			
			return response ?? ErrorPassResponse(msg: '未能成功解析 Response');
		} catch (e, stackTrace) {
			print(stackTrace);
			return ErrorPassResponse(msg: '请求发生异常: $e', error: e, stacktrace: stackTrace);
		} finally {
			if(isTempHttpClient) {
				if (httpClient != null) {
					httpClient.close();
					httpClient = null;
				}
			}
			httpReq?.close();
		}
	}
	
}
