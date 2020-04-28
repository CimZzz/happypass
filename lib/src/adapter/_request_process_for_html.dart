import '../http_interceptor_chain.dart';
import '../http_responses.dart';

import 'http_client.dart';
import 'http_request.dart';

import 'request_process.dart' as _processor;

final HttpProcessor processor = HttpProcessor();

class HttpProcessor implements _processor.HttpProcessor {
	
	/// Html 中 HttpClient 无实际意义，只是用来创建请求
	/// 只有 PassHttpRequest 作为实际意义上的请求对象
	@override
	Future<PassResponse> request(ChainRequestModifier modifier) async {
		PassHttpRequest httpReq;
		try {
			final chainRequestModifier = modifier;
			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				return null;
			}
			final url = chainRequestModifier.getUrl();
			final method = chainRequestModifier.getRequestMethod();
			
			httpReq = await PassHttpClient().fetchHttpRequest(method, url);
			// 装配 `PassHttpRequest`，保证中断器可以正常中断请求
			chainRequestModifier.assembleHttpRequest(httpReq);
			
			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				return null;
			}
			
			final fillHeaderFuture = chainRequestModifier.fillRequestHeader(httpReq);
			final fillBodyFuture = chainRequestModifier.fillRequestBody(httpReq);
			
			// 等待填充头部和填充请求 Body 完成
			await fillHeaderFuture;
			await fillBodyFuture;
			
			PassResponse response;
			if (chainRequestModifier.existResponseRawDataReceiverCallback()) {
				// 如果存在响应数据原始接收回调
				// 执行 [analyzeResponseByReceiver] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponseByReceiver(httpReq));
			} else {
				// 执行 [analyzeResponse] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponse(httpReq));
			}
			httpReq = null;
			
			return response ?? ErrorPassResponse(msg: '未能成功解析 Response');
		} catch (e, stackTrace) {
//			print(stackTrace);
			return ErrorPassResponse(msg: '请求发生异常: $e', error: e, stacktrace: stackTrace);
		} finally {
			httpReq?.close();
		}
	}
}