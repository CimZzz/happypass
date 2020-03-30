import 'dart:async';

import 'package:happypass/happypass.dart';

/// 模拟拦截回调的构造器
typedef MockBuilderCallback = Map<String, dynamic> Function(MockClientBuilder builder);

/// 请求模拟拦截回调，直接返回最终结果
typedef _MockClientRequestCallback = FutureOr<PassResponse> Function();

/// 请求模拟拦截回调，使用 [MockClientHandler] 指定拦截结果
typedef _MockClientRequestHandlerCallback = FutureOr<void> Function(MockClientHandler handler);

/// 请求模拟拦截回调，使用 [MockClientHandler] 指定拦截结果，需要额外参数 [ChainRequestModifier]
typedef _MockClientRequestHandlerWithModifierCallback = FutureOr<void> Function(ChainRequestModifier modifier, MockClientHandler handler);

/// 模拟 Entry 基类
/// 全部模拟拦截 Entry 都由此类派生
class _MockClientEntry {
	_MockClientEntry(this.mockCallback, this.requestMethod);

	/// 模拟回调接口
	final Function mockCallback;

	/// 限制的请求方法
	/// 只有与指定请求方法匹配的请求才会执行模拟回调
	/// 如果该值为 `null`，表示会模拟拦截全部请求方法
	final RequestMethod requestMethod;

	/// 执行模拟拦截方法
	Future<void> mock(MockClientHandler handler, ChainRequestModifier modifier) {
		if (requestMethod != null && modifier.getRequestMethod() != requestMethod) {
			return null;
		}

		if (mockCallback is _MockClientRequestCallback) {
			final response = mockCallback();
			if (response != null) {
				handler.hold(response);
			}
		} else if (mockCallback is _MockClientRequestHandlerCallback) {
			return mockCallback(handler);
		} else if (mockCallback is _MockClientRequestHandlerWithModifierCallback) {
			return mockCallback(modifier, handler);
		}
		return null;
	}
}

/// 模拟回调构造器
/// 能够便捷构造模拟回调
class MockClientBuilder {
	const MockClientBuilder();

	/// 生成模拟节点，并设置对应请求方法的模拟拦截回调
	/// [get] : 对应 `GET` 请求所配置的模拟拦截回调
	/// [post] : 对应 `POST` 请求所配置的模拟拦截回调
	/// [all] : 对应全部请求所配置的模拟拦截回调
	/// [path] : 继续添加子路径
	Map<String, dynamic> mock({List<Function> get, List<Function> post, List<Function> all, Map<String, dynamic> path}) {
		final map = <String, dynamic>{};
		if (get != null) {
			map['\'get\''] = get;
		}
		if (post != null) {
			map['\'post\''] = post;
		}
		if (all != null) {
			map['\'*\''] = all;
		}
		if (path != null) {
			map.addAll(path);
		}
		if(map.length == 0) {
			return null;
		}
		
		return map;
	}

	/// 使用 [_MockClientRequestCallback] 作为模拟回调
	Function doDirectly(_MockClientRequestCallback callback) {
		return callback;
	}

	/// 使用 [_MockClientRequestHandlerCallback] 作为模拟回调
	Function doHandler(_MockClientRequestHandlerCallback callback) {
		return callback;
	}

	/// 使用 [_MockClientRequestHandlerWithModifierCallback] 作为模拟回调
	Function doModifier(_MockClientRequestHandlerWithModifierCallback callback) {
		return callback;
	}
}

class MockClientHandler {
	/// 模拟结果
	/// 表示在 [MockRequestCallback] 中调用 [hold]、[success]、[error] 成功生成的响应结果
	/// 当该结果存在时，会将请求进行拦截，返回该结果作为最终的响应结果
	FutureOr<PassResponse> _result;

	/// 判断是否已经 `Mocked`
	bool get _isMocked => _result != null;

	/// 使用 Future<PassResponse> 来设置模拟响应结果
	/// * 即使最终 `Future` 返回 `null`，也视为拦截成功
	void hold(FutureOr<PassResponse> passResponse) {
		_result ??= passResponse;
	}

	/// 模拟请求成功的响应结果
	void success({dynamic dataBody}) {
		_result ??= SuccessPassResponse(body: dataBody);
	}

	/// 模拟请求失败的响应结果
	void error({String msg, dynamic error, StackTrace stacktrace}) {
		_result ??= ErrorPassResponse(msg: msg, error: error, stacktrace: stacktrace);
	}
}

/// 模拟请求拦截器
/// 可以针对请求 `url` 进行拦截，直接返回预设好的响应结果，整个过程是离线的，并且无须与服务器进行交互。
///
/// * 建议仅在 `debug` 模式下开发使用，便于快速开发与离线测试
class MockClientPassInterceptor extends PassInterceptor {
	/// 分别对应
	Map<String, List<_MockClientEntry>> _mockMap;

	/// 在构造方法中配置需要模拟拦截的请求
	/// 配置方法可以参考如下写法:
	/// {
	///     'xxx.com': {
	///         '/path1': {
	///             ''get'': [
	///                 callback1,
	///                 callback2,
	///                 callback3,
	///             ],
	///             ''post'': [
	///                 callback4,
	///                 callback5,
	///                 callback6,
	///             ],
	///             ''*'': [
	///                 callback7,
	///                 callback8,
	///                 callback9,
	///             ]
	///         }
	///     }
	/// }
	///
	/// 等同于
	///
	/// 'xxx.com': {
	/// 	'/path1': builder.gen(
	/// 		get: [
	/// 			builder.mock(...),
	/// 			builder.mockWithHandler(...),
	/// 			builder.mockWithModifier(...),
	/// 		],
	/// 		post: [
	/// 			builder.mock(...),
	/// 			builder.mockWithHandler(...),
	/// 			builder.mockWithModifier(...),
	/// 		],
	/// 		all: [
	/// 			builder.mock(...),
	/// 			builder.mockWithHandler(...),
	/// 			builder.mockWithModifier(...),
	/// 		]
	/// 	)
	/// }
	///
	/// 以上配置表示含义是:
	/// 拦截通向 'xxx.com/path1' 的全部请求。`get` 表示 `GET` 请求对应的模拟拦截回调；
	/// `post` 表示 `POST` 请求对应的模拟拦截回调；`*` 表示全部请求（不限制请求方法）模拟拦截回调
	///
	/// 举个例子，如果向该路径下发送一个 `GET` 请求，那么将会访问的请求模拟拦截回调依次为:
	/// `callback1`、`callback2`、`callback3`、`callback7`、`callback8`、`callback9`.
	///
	/// * 如果在 `callback1` 拦截请求，返回了一个模拟响应结果的话，则不会再触发后续回调
	///
	/// * 使用 `builder` 可以快速并正确地配置模拟拦截回调，而不需要显式声明回调参数类型
	///
	/// * 配置路径暂时不支持正则匹配
	MockClientPassInterceptor(MockBuilderCallback mockBuilderCallback) {
		final buildMap = mockBuilderCallback(const MockClientBuilder());
		if (buildMap == null) {
			return;
		}
		_processBuildMap(null, buildMap);
	}

	/// 可以根据多个构造回调生成模拟请求拦截器
	MockClientPassInterceptor.multi(List<MockBuilderCallback> list) {
		list?.forEach((mockBuilderCallback) {
			final buildMap = mockBuilderCallback(const MockClientBuilder());
			if (buildMap == null) {
				return;
			}
			_processBuildMap(null, buildMap);
		});
	}

	/// 实际处理配置模拟逻辑
	void _processBuildMap(String urlPrefix, Map<String, dynamic> map) {
		map.forEach((partOfUrl, value) {
			if (value is Map<String, dynamic>) {
				_processBuildMap((urlPrefix ?? '') + partOfUrl, value);
			} else if (urlPrefix != null && value is List<Function>) {
				RequestMethod limitRequestMethod;
				final requestMethod = partOfUrl.toLowerCase();
				switch (requestMethod) {
					case '\'get\'':
						limitRequestMethod = RequestMethod.GET;
						break;
					case '\'post\'':
						limitRequestMethod = RequestMethod.POST;
						break;
					case '\'*\'':
						break;
					default:
						return;
				}
				_mockMap ??= {};
				final callbackList = _mockMap.putIfAbsent(urlPrefix, () => []);
				value.forEach((callback) {
					callbackList.add(_MockClientEntry(callback, limitRequestMethod));
				});
			}
		});
	}

	/// 拦截器实际逻辑实现
	@override
	FutureOr<PassResponse> intercept(PassInterceptorChain chain) async {
		final modifier = chain.modifier;
		final resolveUrl = modifier.getResolverUrl();
		if (resolveUrl == null) {
			// 解析 url 失败，无法进行模拟拦截
			return await chain.waitResponse();
		}

		try {
			if (_mockMap != null) {
				final hostAndPath = '${resolveUrl.host}${resolveUrl.path ?? ''}';
				final protocolAndHostAndPath = '${resolveUrl.protocol}://$hostAndPath';
				final entryList = _mockMap[hostAndPath] ?? _mockMap[protocolAndHostAndPath];
				if (entryList != null) {
					final handler = MockClientHandler();
					for (var entry in entryList) {
						await entry.mock(handler, modifier);
						if (handler._isMocked) {
							return await handler._result;
						}
					}
				}
			}
		} catch (e, stacktrace) {
			return ErrorPassResponse(msg: 'mock failure [$resolveUrl]', error: e, stacktrace: stacktrace);
		}

		return await chain.waitResponse();
	}
}
