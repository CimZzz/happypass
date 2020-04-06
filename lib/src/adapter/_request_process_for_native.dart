import 'dart:io';
import 'package:happypass/src/http.dart';

import 'request_process.dart' as _processor;

final HttpProcessor processor = HttpProcessor();

class HttpProcessor implements _processor.HttpProcessor {
	
	/// 默认情况下，在只在编码与解码时使用了执行代理
	@override
	Future<PassResponse> request(ChainRequestModifier modifier) async {
		HttpClient client;
		HttpClientRequest httpReq;
		try {
			final chainRequestModifier = modifier;
			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				return null;
			}
			
			client = HttpClient();
			// 设置宽松的超时时间，目的是为了由我们接管超时处理逻辑
			chainRequestModifier.fillLooseTimeout(client);
			// 装配 `HttpClient`，保证中断器可以正常中断请求
			chainRequestModifier.assembleHttpClient(client);
			// 配置 HTTP 请求代理
			chainRequestModifier.fillRequestHttpProxy(client);
			
			final method = chainRequestModifier.getRequestMethod();
			
			// 创建请求对象
			final url = chainRequestModifier.getUrl();
			if (method == RequestMethod.POST) {
				// 限制在连接超时时间内获取 `HttpClientRequest`
				httpReq = await chainRequestModifier.runInConnectTimeout(client.postUrl(Uri.parse(url)));
			} else {
				// 限制在连接超时时间内获取 `HttpClientRequest`
				httpReq = await chainRequestModifier.runInConnectTimeout(client.getUrl(Uri.parse(url)));
			}
			
			if (chainRequestModifier.isClosed) {
				// 如果请求已经取消，则直接返回 null
				httpReq.close();
				return null;
			}
			
			// 填充 Cookie
			final existCookie = chainRequestModifier.getCookies(chainRequestModifier.getUrl());
			if (existCookie != null) {
				httpReq.cookies.addAll(existCookie);
			}
			
			final fillHeaderFuture = chainRequestModifier.fillRequestHeader(httpReq, chainRequestModifier);
			final fillBodyFuture = chainRequestModifier.fillRequestBody(httpReq, chainRequestModifier);
			
			await fillHeaderFuture;
			await fillBodyFuture;
			
			PassResponse response;
			if (chainRequestModifier.existResponseRawDataReceiverCallback()) {
				// 如果存在响应数据原始接收回调
				// 执行 [analyzeResponseByReceiver] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponseByReceiver(modifier, httpReq: httpReq));
			} else {
				// 执行 [analyzeResponse] 方法
				// 限制在读取超时时间内解析完成 `HttpClientResponse`
				response = await chainRequestModifier.runInReadTimeout(chainRequestModifier.analyzeResponse(modifier, httpReq: httpReq));
			}
			httpReq = null;
			
			return response ?? ErrorPassResponse(msg: '未能成功解析 Response');
		} catch (e, stackTrace) {
			print(stackTrace);
			return ErrorPassResponse(msg: '请求发生异常: $e', error: e, stacktrace: stackTrace);
		} finally {
			if (client != null) {
				client.close(force: true);
				client = null;
			}
		}
	}
	
}
