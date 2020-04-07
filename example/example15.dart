import 'package:happypass/happypass.dart';
import 'package:happypass/src/http_mock_interceptor.dart';

/// 本示例演示如何使用 [MockClientPassInterceptor] 进行离线本地请求模拟
/// [MockClientPassInterceptor] 可以根据请求 `url` 进行拦截，如果成功拦截可以直接返回一个响应结果作为最终的响应数据
void main() async {
	// 首先，我们构造一个请求原型（优化代码可读性）
	final prototype = RequestPrototype();
	// 设置 Url 作为 `baseUrl`
	prototype.setUrl('https://www.baidu.com');
	// 为其配置字符串编解码
	prototype.stringChannel();
	// 配置一个 `MockClientPassInterceptor`，并针对指定 `url` 请求进行拦截
	prototype.addFirstInterceptor(MockClientPassInterceptor((builder) =>
	{
		'www.baidu.com': builder.mock(
			path: {
				// 添加路径 `fakePath`
				'/fakePath': builder.mock(
					// 拦截全部 GET 请求
					get: [
						// 通过 `Handler` 的方式
						// 不拦截请求
						builder.doHandler((handler) {
							print('find get www.baidu.com/fakePath, but not mocked!');
						}),
						// 直接返回响应结果
						// 因为上面的回调没有返回响应结果，所以请求交给后一个模拟拦截回调来处理
						builder.doModifier((modifier, handler) {
							handler.success(dataBody: 'get www.baidu.com/fakePath mocked! params: ${modifier
								.getResolverUrl()
								.queryParams}');
						}),
					],
					// 拦截全部 POST 请求
					post: [
						// 根据 POST 请求体内容返回相对应的响应
						builder.doModifier((modifier, handler) {
							if (modifier.getRequestBody() == 'hello') {
								handler.success(dataBody: 'hi');
							}
							else {
								handler.error(msg: 'err, why not you say \'hello\'?');
							}
						})
					]
				)
			},
			// 拦截全部 GET 请求
			get: [
				// 不进行拦截，跳过
				builder.doDirectly(() => null)
			],
			// 拦截全部 POST 请求
			post: [
				// 配置具有 MockClientHandler 参数
				builder.doHandler((handler) {
					// 通过 `Handler` 发送响应结果
					handler.success(dataBody: 'post www.baidu.com mocked!');
				})
			]
		),
	}));

	// 这里，我们使用 [Request.quickGet] 发送一个 `GET` 请求，指定请求原型
	final result = await happypass.get(url: 'https://www.baidu.com/fakePath?params=123', prototype: prototype);
	// 观察打印结果
	print(result);

	// 发送其他请求试试
	print(await happypass.post(path: '/fakePath', body: 'hello', prototype: prototype));
	print(await happypass.post(path: '/fakePath', body: 'hei', prototype: prototype));
	print(await happypass.post(body: 'hi', prototype: prototype));

	// 如果你需要模拟的请求太多了，配置起来极度复杂，那么可以使用 [MockClientPassInterceptor.multi] 方法构造拦截器
	// 这个构造方法支持以 List 的形式构造模拟拦截器
	// 可以参考下方实现
	final builder1 = (MockClientBuilder builder) =>
	<String, dynamic>{
		'www.baidu.com': {
			'/newPath': builder.mock(
				get: [
					builder.doDirectly(() => SuccessPassResponse(body: 'mock newPath'))
				]
			)
		}
	};
	final builder2 = (MockClientBuilder builder) =>
	<String, dynamic>{
		'www.baidu.com': {
			'/newPath2': builder.mock(
				get: [
					builder.doDirectly(() => SuccessPassResponse(body: 'mock newPath2'))
				]
			)
		}
	};

	// 清空之前配置的模拟拦截器
	// * 注意，会连带地将 [BusinessPassInterceptor] 一同清除
	prototype.clearInterceptors();
	// 使用 `builder1` 和 `builder2` 这两个构造回调生成模拟请求拦截器
	prototype.addFirstInterceptor(MockClientPassInterceptor.multi([builder1, builder2]));

	// 发送请求试试
	print(await happypass.get(path: '/newPath', prototype: prototype));
	print(await happypass.get(path: '/newPath2', prototype: prototype));
}
