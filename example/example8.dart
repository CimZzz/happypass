import 'dart:io';

import 'package:happypass/happypass.dart';

/// 本示例实现了用自定义拦截器进行请求正常拦截，不使用提供的请求方法。在本示例中，会确保 `Request` 的全部功能仍然正常使用。
void main() async {
	// 为了方便依然使用 [Request.quickGet] 方法
	final result = await Request.quickGet(
		url: 'https://www.baidu.com',
		configCallback: (request) {
			// 设置字符串编解码器
			request.stringChannel();
			// 设置一个自定义拦截器，在其中实现请求的拦截
			request.addFirstInterceptor(SimplePassInterceptor((chain) async {
				// 之前的示例展示了如何使用提供的请求方法，并演示如何到对其每个流程进行 `hook`
				// 在本示例中，我们不在使用提供的方法，但是要确保全部 `happypass` 的功能可以正常使用
				// ChainRequestModifier 提供了大量数据访问的方法，我们要合理利用它
				ChainRequestModifier modifier = chain.modifier;
				HttpClient client;
				HttpClientRequest httpReq;
				try {
					// 实例化 `HttpClient`
					client = HttpClient();
					// * 这一步是为了确保请求中断器可以正常中断请求
					// * 请求已经开始运作，请求中断器在这个时候可以中断 `HttpClient` 来实现
					// * 请求的中断
					modifier.assembleHttpClient(client);

					// 填充宽松请求超时时间，这是为了由我们来接管超时处理逻辑
					// 比如使用 [ChainRequestModifier.runInConnectTimeout] 将生成 `HttpClientRequest` 方法包装起来，
					// 如果在给定连接超时时间内没有生成成功，那么该方法将会直接抛出连接超时异常
					//
					// * 如果不想使用 `happypass` 管理超时时间，那么可以使用 [ChainRequestModifier.fillTightTimeout] 方法
					// * 设置紧迫超时时间。如果超时将会由 `HttpClient` 抛出超时异常
					//
					// modifier.fillTightTimeout(client);
					modifier.fillLooseTimeout(client);
					// 根据请求方法来生成 `HttpClientRequest`
					final url = modifier.getUrl();
					if (modifier.getRequestMethod() == RequestMethod.POST) {
						httpReq = await modifier.runInConnectTimeout(client.postUrl(Uri.parse(url)));
					} else {
						httpReq = await client.getUrl(Uri.parse(url));
					}

					// * 这一步是为了确保 Cookie 能够正确配置
					// * `HttpClientRequest` 已经生成完毕，首先为其配置来自
					// * `CookieManager` 中所储存的 Cookie，而这一步正是从 CookieManager
					// * 中提取 Cookie
					final existCookie = modifier.getCookies(modifier.getUrl());
					if (existCookie != null) {
						httpReq.cookies.addAll(existCookie);
					}

					// 为 `HttpClientRequest` 配置其他请求参数
					// 1. 请求头部
					// 2. 请求 Body

					// * 可以使用 [ChainRequestModifier.fillRequestHeader] 方法来快速填充请求头部
					// * 该方法做过优化，可以通过设置 `useProxy` 来决定是否在请求运行代理中填充请求头部（如果设置了的话）
					// * 当然，我们也可以自行填充请求头部，就像下面这样
					// modifier.fillRequestHeader(httpReq, modifier, useProxy: false);
					modifier.forEachRequestHeaders((String key, String value) {
						// 遍历请求头部列表添加到 `HttpClientRequest` 中
						httpReq.headers.add(key, value);
					});

					// * 可以使用 [ChainRequestModifier.fillRequestBody] 方法来快速填充请求 Body
					// * 该方法做过优化:
					// * - 可以通过设置 `useEncode` 来决定是否使用编码
					// * - 可以通过设置 `useProxy` 来决定是否在请求运行代理中进行请求 Body 编码（如果设置了的话）
					// * 下面我们不借助 [ChainRequestModifier.fillRequestBody] 方法，自行设置请求 Body
					// modifier.fillRequestBody(httpReq, modifier);

					if (modifier.getRequestMethod() == RequestMethod.POST) {
						// 只有 POST 请求才需要传输请求 Body
						final requestBody = modifier.getRequestBody();

						if (requestBody is RequestBody) {
							// * 如果请求 Body 是 `RequestBody` 类型数据的话，需要进行特殊处理
							// * 这一步处理是为了确保 `RequestBody` 能够正常执行它应有的处理逻辑

							// [RequestBody] 可以覆盖 `Content-Type` 请求头部
							// 如果请求不存在 `Content-Type` 头部或者 [RequestBody.overrideContentType] 设置为 `true` 时，
							// `Content-Type` 将会被覆盖
							if (requestBody.overrideContentType == true || httpReq.headers.value('content-type') == null) {
								httpReq.headers.set('content-type', requestBody.contentType);
							}

							// `RequestBody` 中的数据以流的形式存在
							await for (var message in requestBody.provideBodyData()) {
								// 每个从 `RequestBody` 取到的数据，都应该通过编码器进行编码
								// 除非数据类型为 `RawDataBody`
								// `RawDataBody` 表示该数据即为原始数据，不应对其进行编码
								if (message is RawBodyData) {
									httpReq.add(message.rawData);
									continue;
								}

								// * 对消息进行编码
								// * 使用 [ChainRequestModifier.encodeMessage] 方法能够快捷进行编码
								// * 当然，你也可以遍历编码器进行编码，这一切取决你
								message = await modifier.encodeMessage(message, useProxy: true);

								if (message is! List<int>) {
									// 最终编码结果必须为 `List<int>` 类型的 byte 数据，
									// 否则认定为请求错误，返回请求错误
									return ErrorPassResponse(msg: '[POST] 最后的编码结果类型不为 \'List<int>\'');
								}

								// 将最终的 byte 交给 `HttpClientRequest`
								httpReq.add(message);
							}
						} else {
							// 请求 Body 是某种数据结构，需要我们通过编码器最终将其转化为 `List<int>` 类型的 byte 数据
							dynamic message = requestBody;
							if (message is RawBodyData) {
								// 同样，如果请求 Body 是 `RawBodyData` 类型的数据，那么我们直接取用其 [RawBodyData.rawData] 作为最终
								// 数据即可
								message = message.rawData;
							} else {
								// * 其他数据结构需要我们进行编码处理
								// * 使用 [ChainRequestModifier.encodeMessage] 方法能够快捷进行编码
								// * 当然，你也可以遍历编码器进行编码，这一切取决你
								message = await modifier.encodeMessage(message, useProxy: true);
							}

							if (message is! List<int>) {
								// 最终编码结果必须为 `List<int>` 类型的 byte 数据，
								// 否则认定为请求错误，返回请求错误
								return ErrorPassResponse(msg: '[POST] 最后的编码结果类型不为 \'List<int>\'');
							}

							httpReq.add(message);
						}
					}

					// 全部请求配置信息已经完成，获取响应数据
					// * 我们应该确保通知响应进度的功能可以正常工作，
					// * 在解析响应数据时，需要对这方面功能进行处理;
					// * 另外，如果按照 `happypass` 的处理逻辑，如果设置了响应数据原始接收接口，
					// * 那么响应数据都会交由原始数据接收接口处理，且不会保留数据

					// * `happypass` 提供了两种解析响应数据的方法
					// * - analyzeResponse : 标准解析响应数据方法。收集全部响应数据，使用解码器对数据进行解码，生成 `PassResponse` 并返回
					// * - analyzeResponseByReceiver : 使用响应数据原始接收接口解析响应数据。不会收集响应数据，而是直接将数据中转到接口中进行处理，根据接口处理完成后返回的数据，生成 `PassResponse` 并返回
					// modifier.analyzeResponse(modifier, httpReq: httpReq);
					modifier.analyzeResponseByReceiver(modifier, httpReq: httpReq);

					// * 下面我们不借助 `ChainRequestModifier` 提供的解析方法，自行解析响应数据，并保证 `happypass` 各个功能能够正确工作

					// 通过 `HttpClientRequest` 获取响应数据
					final httpResponse = await httpReq.close();
					// * 紧接着，我们需要标记请求已经执行完成，以防止在响应向上回溯时，请求原始数据遭到修改
					// * 调用 [ChainRequestModifier.markRequestExecuted] 即可
					modifier.markRequestExecuted();
					// * 将响应数据中的 Cookie 交由 `CookieManager` 处理
					// * 调用 [ChainRequestModifier.storeCookies] 即可
					// * 在方法中存在空值处理，所以我们无需再次进行空值校验
					modifier.storeCookies(url, httpResponse.cookies);

					// * 为了保证通知响应进度回调消息准确，我们需要取 `HttpClientResponse` 中的 `Content-Length`，
					// * 作为总的接收数据长度
					// * 另外，如果响应中没有描述数据长度，那么应该将 `totalLength` 标记为 `-1`，表示总长度未知
					final contentLengthList = httpResponse.headers['content-length'];
					int totalLength = -1;
					if (contentLengthList?.isNotEmpty == true) {
						totalLength = int.tryParse(contentLengthList[0]) ?? -1;
					}
					int curLength = 0;

					PassResponse passResponse;

					if (modifier.existResponseRawDataReceiverCallback()) {
						// 使用 [ChainRequestModifier.runInReadTimeOut] 方法将处理响应数据方法包装起来，这样可以在解析时间超时时抛出异常
						passResponse = await modifier.runInReadTimeout(() async {
							// 如果存在原始响应数据接收回调，应将实际处理逻辑交由接口实现
							// 请参考下面写法，能够确保请求设置的原始响应数据接收回调正常工作
							Stream<List<int>> rawDataStream = httpResponse;

							// * 如果想让响应数据通知进度功能生效的话，我们必须在接收响应数据时进行处理
							// * 调用 [ChainRequestModifier.notifyResponseDataUpdate] 方法可以通知全部进度回调进度更新
							// * 下面会在原始数据 byte 流外包裹一层 Stream，用来实现进度通知功能
							Stream<List<int>> rawDataStreamWrap(Stream<List<int>> rawStream) async* {
								await for (var byteList in rawStream) {
									// 每当接收到新数据时，进行通知更新
									curLength += byteList.length;
									modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
									yield byteList;
								}
							}

							// 接收之前先触发一次空进度通知
							modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);

							final result = await modifier.transferRawDataForRawDataReceiver(rawDataStreamWrap(rawDataStream));

							if (result is PassResponse) {
								return result;
							} else {
								return ProcessablePassResponse(httpResponse, null, result);
							}
						}());
					} else {
						// 使用 [ChainRequestModifier.runInReadTimeOut] 方法将处理响应数据方法包装起来，这样可以在解析时间超时时抛出异常
						passResponse = await modifier.runInReadTimeout(() async {
							// 不存在原始响应数据接收回调，执行标准解析逻辑
							// 参考下面写法，能够确保 `happypass` 各个功能正常工作
							List<int> responseBody = List();

							// 接收之前先触发一次空进度通知
							modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
							await httpResponse.forEach((byteList) {
								responseBody.addAll(byteList);
								// 每当接收到新数据时，进行通知更新
								curLength += byteList.length;
								modifier.notifyResponseDataUpdate(curLength, totalLength: totalLength);
							});

							dynamic decodeObj = responseBody;

							// * 按照标准流程，应该对收集到的响应数据进行解码
							// * 使用 [ChainRequestModifier.decodeMessage] 方法能够快捷进行解码
							// * 当然，你也可以遍历编码器进行解码，这一切取决你
							decodeObj = await modifier.decodeMessage(decodeObj, useProxy: true);

							return ProcessablePassResponse(httpResponse, responseBody, decodeObj);
						}());
					}

					// 如果接收完毕但没有返回应有的响应对象，那么会返回一个 `ErrorPassResponse` 表示处理出错
					return passResponse ?? ErrorPassResponse(msg: '未能成功解析 Response');
				} catch (e) {
					return ErrorPassResponse(msg: '请求发生异常: $e', error: e);
				} finally {
					client?.close(force: true);
				}
			}));
		});

	// 以上，你已经成功完成了 `happypass` 所作的一切请求工作，让我们来看看结果吧
	print(result);
}
