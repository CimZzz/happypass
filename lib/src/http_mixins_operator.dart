part of 'core.dart';

/// 用来检查当前请求的执行状态
mixin RequestStatusChecker implements RequestOperatorMixBase {

	/// 检查当前状态是否处于准备状态
	/// 在这个状态下可以修改全部配置
	bool checkPrepareStatus() => _requestOptions.checkPrepareStatus;

	/// 检查当前状态是否处于执行中状态
	/// 这里的执行中并不是真正执行，该状态表示 Request 已经交由拦截链处理，并未真正生成 Response
	/// 在这个状态下可以修改大部分配置
	bool checkExecutingStatus() => _requestOptions.checkExecutingStatus;
}

/// 调用请求执行代理
/// 通过请求执行代理来执行回调
/// 注意的是，回调必须为 `static`
mixin RequestProxyRunner implements RequestOperatorMixBase {
	/// 通过配置的执行代理执行回调
	/// 注意的是，回调必须为 `static`
	Future<Q> runProxy<T, Q>(AsyncRunProxyCallback<T, Q> callback, T message) async {
		final runProxy = _requestOptions.runProxy;
		if (runProxy != null) {
			return await runProxy(callback, message);
		}

		return callback(message);
	}
}


/// 填充 Request 头部混合
/// 用于填充 Request Headers
mixin RequestHeaderFiller implements RequestOperatorMixBase {
	/// 将配置好的请求头部填充到 PassHttpRequest 中
	void fillRequestHeader(PassHttpRequest httpReq, ChainRequestModifier modifier, {bool useProxy = true}) async {
		final headers = modifier._request._headerMap;
		if (headers != null && headers.isNotEmpty) {
			final bundle = _HeaderBundle(httpReq, headers);
			if (useProxy) {
				await modifier.runProxy(_fillHeaders, bundle);
			} else {
				await _fillHeaders(bundle);
			}
		}
	}

	static Future _fillHeaders(_HeaderBundle bundle) async {
		final httpReq = bundle._request;
		final headers = bundle._requestHeaders;
		if (headers != null && headers.isNotEmpty) {
			headers.forEach(httpReq.setRequestHeader);
		}
	}
}

/// 用于包装需要填充的请求和请求头的数据集
class _HeaderBundle {
	_HeaderBundle(this._request, this._requestHeaders);

	final PassHttpRequest _request;
	final Map<String, String> _requestHeaders;
}

/// 用于进行编码消息
mixin RequestEncoder implements RequestOperatorMixBase, RequestProxyRunner {
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
}

/// 用于包装需要编码的消息和编码器的数据集
class _EncodeBundle {
	const _EncodeBundle(this._message, this._encoderList);

	final dynamic _message;
	final List<HttpMessageEncoder> _encoderList;
}

/// 填充 Request 请求Body
/// 用于填充 Request Body，可选择进行代理和编码
mixin RequestBodyFiller implements RequestOperatorMixBase, RequestEncoder {
	/// 将配置好的 Body 填充到 PassHttpRequest 中，如果 Body 在处理过程中发生错误，则会直接返回抛出异常
	/// 可以选择是否使用代理，编码
	/// 默认情况下，使用编码与代理
	/// - httpReq: PassHttpRequest 对象
	/// - modifier: 拦截链请求修改器
	/// - useEncode: 是否对数据进行编码
	/// - useProxy: 是否在编码的过程中使用请求执行代理
	/// - sendOnce: 是否只发送一次数据（如果该值为 true，那么会将数据体中全部数据收集起来，之后统一发送），并且消息的数据类型为同种类型
	Future<void> fillRequestBody(PassHttpRequest httpReq, ChainRequestModifier modifier, {bool useEncode = true, bool useProxy = true, bool sendOnce = false}) async {
		dynamic body = modifier.getRequestBody();
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

			List messageCacheList;

			await for (var message in body.provideBodyData()) {
				if (message is RawBodyData) {
					message = message.rawData;
				} else if (useEncode) {
					message = await encodeMessage(message, useProxy: useProxy);
				}

				if (httpReq.checkDataLegal(message)) {
					throw const HappyPassError('请求 \'body\' 数据类型非法');
				}

				if(sendOnce) {
					messageCacheList ??= [];
					if(message is List) {
						messageCacheList.addAll(message);
					}
					else {
						messageCacheList.add(message);
					}
				}
				else {
					httpReq.sendData(message);
				}
			}

			// 如果 sendOnce 为 true, 一次性全部发送过去
			if(messageCacheList != null) {
				if(messageCacheList.length == 1) {
					// 当列表中只有一个数据时，将会去掉容器
					httpReq.sendData(messageCacheList[0]);
				}
				else {
					httpReq.sendData(messageCacheList);
				}
				messageCacheList = null;
			}
		} else {
			// 当请求体不是 RequestBody 时
			dynamic message = body;
			if (message is RawBodyData) {
				message = message.rawData;
			} else if (useEncode) {
				message = await encodeMessage(message, useProxy: useProxy);
			}

			if (httpReq.checkDataLegal(message)) {
				throw const HappyPassError('请求 \'body\' 数据类型非法');
			}

			httpReq.sendData(message);
		}
	}
}

/// 用于解码消息
mixin ResponseDecoder implements RequestOperatorMixBase, RequestProxyRunner {
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
}

/// 用于包装需要解码的消息和解码器的数据集
class _DecodeBundle {
	const _DecodeBundle(this._message, this._decoderList);

	final dynamic _message;
	final List<HttpMessageDecoder> _decoderList;
}

/// 解析 Request 的 Response Body
/// 用于解析 Response Body，可选择进行代理和解码
mixin ResponseBodyDecoder implements RequestOperatorMixBase, ResponseDecoder {
	/// 从 PassHttpRequest 中获取 PassHttpResponse，并读取其全部 Byte 数据存入 List<int> 中
	/// 如果 Body 在处理过程中发生错误，则会直接抛出异常
	/// 可以选择是否使用代理，编码
	/// 默认情况下，开始编码与代理
	/// - httpReq: 使用 `PassHttpRequest` 获取响应数据进行解析
	/// - httpResp: 直接使用 `PassHttpResponse` 进行解析
	/// - useDecode: 表示是否使用解码器处理数据
	/// - useProxy: 表示使用使用请求执行代理来解码数据
	/// - doNotify: 表示是否通知响应数据接收进度
	Future<PassResponse> analyzeResponse(PassHttpRequest httpReq, ChainRequestModifier modifier, {bool useDecode = true, bool useProxy = true, bool doNotify = true}) async {
		final httpResp = await httpReq.fetchHttpResponse();

		// 标记当前请求已经执行完成
		modifier.markRequestExecuted();


		final responseBody = <int>[];
		if (doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final totalLength = httpResp.contentLength;
			var curLength = 0;
			// 接收之前先触发一次空进度通知
			modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
			await httpResp.bodyStream.forEach((byteList) {
				responseBody.addAll(byteList);
				// 每当接收到新数据时，进行通知更新
				curLength += byteList.length;
				modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
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
	Future<PassResponse> analyzeResponseByReceiver(PassHttpRequest httpReq, ChainRequestModifier modifier, {bool doNotify = true}) async {
		final httpResp = await httpReq.fetchHttpResponse();

		Stream<List<int>> rawByteDataStream;
		// 标记当前请求已经执行完成
		modifier.markRequestExecuted();
		if (doNotify) {
			// 获取当前响应的数据总长度
			// 如果不存在则置为 -1，表示总长度未知
			final totalLength = httpResp.contentLength;
			var curLength = 0;
			// 接收之前先触发一次空进度通知
			modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
			Stream<List<int>> rawByteStreamWrap(Stream<List<int>> rawStream) async* {
				await for (var byteList in rawStream) {
					// 每当接收到新数据时，进行通知更新
					curLength += byteList.length;
					modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
					yield byteList;
				}
			}

			rawByteDataStream = rawByteStreamWrap(httpResp.bodyStream);
		} else {
			// 不进行通知，直接获取响应数据
			rawByteDataStream = httpResp.bodyStream;
		}

		PassResponse passResponse;
		final result = await modifier.transferRawDataForRawDataReceiver(rawByteDataStream);

		if (result is PassResponse) {
			if(result is ProcessablePassResponse) {
				result.assembleResponse(httpResp);
			}
			else if(result is SuccessPassResponse) {
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
}

/// 通知当前 Response Body 接收进度
/// 用于解析 Response Body，可选择进行代理和解码
mixin ResponseDataUpdate implements RequestOperatorMixBase {
	/// 通知相应数据接收进度
	/// 每当接收到新的数据时，都应触发该方法
	/// 如果总长度未知，则不应传总长度参数
	void notifyResponseDataUpdate(int length, {int totalLength = -1}) {
		// 除非总长度总长度未知，否则接收的数据长度不应超过总长度
		if (length > totalLength && totalLength != -1) {
			if (Request.DEBUG) {
				print('[WARN] ${_buildRequest.getUrl()}: recv length over total length!');
			}
		}

		_requestOptions.responseDataUpdateList?.forEach((callback) {
			callback(length, totalLength);
		});
	}
}

/// 直接传输 Request 的 Response Body 数据
/// 从响应中获取数据，不做任何处理交给接收响应原始数据回调处理
mixin ResponseRawDataTransfer implements RequestOperatorMixBase {
	/// 调用接收响应原始数据接口，将 Future 直接返回
	/// 该方法并未在执行代理中执行
	Future<dynamic> transferRawDataForRawDataReceiver(Stream<List<int>> rawDataStream) {
		if (_requestOptions.responseReceiverCallback != null) {
			return _requestOptions.responseReceiverCallback(rawDataStream);
		}
		return null;
	}
}

/// 切换当前请求状态为已执行
/// 按照规范，当 `PassHttpRequest` 执行完 `fetchHttpResponse` 方法后，
/// 应该主动调用该方法，以防止一些请求前的配置信息遭到修改
mixin RequestExecutedChanger implements RequestOperatorMixBase {
	/// 将当前请求状态标记为已执行
	void markRequestExecuted() {
		_requestOptions.status = RequestStatus.Executed;
	}

	/// 将当前请求状态标记为已执行
	void markRequestExecuting() {
		_requestOptions.status = RequestStatus.Executing;
	}
}

/// 中断请求
/// 可以强制中断请求结束，并返回指定的响应结果
mixin RequestClose implements RequestOperatorMixBase {
	/// 判断当前请求是否已经结束
	bool _isClosed = false;

	bool get isClosed => _isClosed || _finishResponse != null;

	/// 用来承载在请求中断的中断结果
	ResultPassResponse _finishResponse;

	/// 用来中断的 `PassHttpClient`
	PassHttpClient _client;

	/// 用来中断的 `PassHttpRequest`
	PassHttpRequest _httpRequest;

	/// 用来执行实际处理逻辑的 Completer
	Completer<PassResponse> _realBusinessCompleter = Completer();

	/// 用来处理内部中断逻辑的 Completer
	/// 保证在调用 `close` 之后可以立即返回响应数据
	Completer<PassResponse> _innerCompleter = Completer();

	/// 内部 Completer 的流订阅
	StreamSubscription<PassResponse> _innerSubscription;

	/// 用于 `ChainRequestModifier` 首次装配给 `RequestCloser`
	void _assembleCloser(ChainRequestModifier modifier) {
		final closerSet = _requestOptions.requestCloserSet;
		if (closerSet != null) {
			for (var closer in closerSet) {
				closer._assembleModifier(modifier);
				if (isClosed) {
					// 如果请求被某个中断器中断的话，那么将不再访问后续中断器
					break;
				}
			}
		}
	}

	/// 代理执行请求逻辑
	/// 大致流程如下:
	///
	/// A ----- C
	///         |
	/// B -------
	///
	/// A - 表示实际请求处理逻辑
	/// B - 表示中断逻辑
	/// C - 表示最后返回的处理结果
	/// A 或 B 首先触发的一方任意结果都会成为 C 的最终结果
	FutureOr<PassResponse> _requestProxy(Future<PassResponse> realFuture) {
		if (_finishResponse != null) {
			return _finishResponse;
		}
		_realBusinessCompleter = Completer();
		_innerCompleter = Completer();
		_innerSubscription = _realBusinessCompleter.future.asStream().listen((data) {
			_innerCompleter.complete(data);
		});
		_realBusinessCompleter.complete(realFuture);
		return _innerCompleter.future;
	}

	/// 装配 PassHttpClient，用来强制中断逻辑
	void assembleHttpClient(PassHttpClient client) {
		_client = client;
		if (_isClosed) {
			client.close();
		}
	}

	/// 装配 PassHttpRequest，用来强制中断逻辑
	void assembleHttpRequest(PassHttpRequest httpRequest) {
		_httpRequest = httpRequest;
		if (_isClosed) {
			httpRequest.close();
		}
	}

	/// 强制中断当前请求
	/// - finishResponse: 中断请求所返回的最终响应结果
	void close({ResultPassResponse finishResponse = const ErrorPassResponse(msg: 'request interrupted!')}) {
		_httpRequest?.close();
		_client?.close();
		_innerCompleter?.complete(finishResponse);
		// 因为 `Completer` 完成不是立即生效的，如果在同一时间内多个中断器同时中断请求
		// 会导致多次完成 `Completer` 而引起异常，所以需要在第一次执行中断逻辑后立即回收
		// `Completer` 相关的资源，防止该异常的发生
		_reset();
	}

	/// 回收当前执行请求逻辑的 Completer 相关的资源与引用
	void _reset() {
		_innerSubscription?.cancel();
		_innerSubscription = null;
		_innerCompleter = null;
		_realBusinessCompleter = null;
		_httpRequest = null;
		_client = null;
	}

	/// 清理当前所持有的引用和状态
	void _finish() {
		_isClosed = true;
		_finishResponse = null;
		_reset();
	}
}

/// 执行请求总超时方法包装混合
/// 可以指定对应操作，并为其设置超时时长
mixin RequestTotalTimeoutCaller implements RequestOperatorMixBase {
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
}

/// 填充 `PassHttpClient` 的超时时间混合
/// 用于填充 `PassHttpClient` 超时时间字段
mixin RequestTimeoutFiller implements RequestOperatorMixBase {
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
}

/// 执行请求超时方法包装混合
/// 可以指定对应操作，并为其设置超时时长
mixin RequestTimeoutCaller implements RequestOperatorMixBase {
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