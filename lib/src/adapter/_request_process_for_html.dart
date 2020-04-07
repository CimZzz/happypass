import 'dart:html';
import 'package:happypass/src/http.dart';

import 'request_process.dart' as _processor;

final HttpProcessor processor = HttpProcessor();

class HttpProcessor implements _processor.HttpProcessor {
	
	@override
	Future<PassResponse> request(ChainRequestModifier modifier) async {
		try {
			String method;
			String contentType;
			dynamic body;
			switch(modifier.getRequestMethod()) {
				case RequestMethod.POST:
					method = 'POST';
					break;
				default:
					method = 'GET';
					break;
			}
			
			// 开启 XMLHttpRequest
			final xhr = HttpRequest();
			xhr.open(method, modifier.getUrl());
			// 处理 Request Body
			body = modifier.getRequestBody();
			
			// POST 方法的 body 不能为 null
			if (body == null) {
				return ErrorPassResponse(msg: '[POST] \'body\' 不能为 \'null\'');
			}
			
			if(body is RequestBody) {
				contentType = body.contentType;
				if (contentType != null) {
					final overrideContentType = body.overrideContentType;
					if (overrideContentType == true || modifier.getRequestHeader('content-type') == null) {
						httpReq.headers.set('content-type', contentType);
					}
				}
			}
			
		} catch (e, stackTrace) {
			return ErrorPassResponse(msg: '请求发生异常: $e', error: e, stacktrace: stackTrace);
		} finally {
		}
	}
}