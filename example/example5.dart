import 'package:happypass/happypass.dart';

/// 本示例扩展了第一个示例的内容---快速请求
/// 我们来看看有快速请求都能做哪些工作
void main() async {
	dynamic result;

	// 首先演示 GET 请求
	// 使用 [Request.quickGet] 方法快速发起一次 `GET` 请求
	result = await Request.quickGet(
		// GET 请求地址
		url: 'https://www.baidu.com',
		// 拼接在地址后方的路径
		path: '/s?wd=helloworld',
		// 请求原型
		// 如果存在请求原型的话，那么会从请求原型孵化请求而不是构建一个全新的请求
		prototype: null,
		// 配置回调
		// 在请求发起之前触发的配置回调，可以在这个回调中对请求进行配置。
		// * 该回调中的参数会覆盖请求原型中配置的参数
		configCallback: (request) {
			request.stringChannel();
		},
	);

	print('======== first get request ========');
	print(result);

	// 进阶使用:
	// 我们可以配合请求原型，达到更便捷地掌控目的
	RequestPrototype prototype = RequestPrototype();
	// 为请求原型配置请求 baseUrl
	prototype.setUrl('https://www.baidu.com');
	// 为请求原型配置 utf8 字符串编解码器
	prototype.stringChannel();

	// 仍然使用 [Request.quickGet]，和上次不同的是，这次使用请求原型来孵化请求
	result = await Request.quickGet(
		// 因为我们请求原型中已经指定了 baseUrl，所以无需重复配置请求 Url 了
		// url: 'http://www.baidu.com',
		path: '/s?wd=helloworld',
		prototype: prototype);

	print('======== second get request ========');
	print(result);

	// 具体如何搭配由你来决定，happypass 推崇的就是开发者拥有高度的自由度，给予开发者基于 `happypass` 实现高度自定义请求
	// 下面介绍使用 [Request.quickPost] 方法快速发起一次 `POST` 请求
	// POST 方法同样也可以使用原型来孵化请求，可以参考 GET 请求，这里就不多赘述了
	result = await Request.quickPost(
		// POST 请求地址
		url: 'xxxx',
		// 拼接在地址后方的路径
		path: 'xx',
		// 请求体数据
		// 该字段不能为空，POST 必须指定一个请求数据
		body: FormDataBody(),
		// 请求原型
		// 如果存在请求原型的话，那么会从请求原型孵化请求而不是构建一个全新的请求
		prototype: null,
		// 配置回调
		// 在请求发起之前触发的配置回调，可以在这个回调中对请求进行配置。
		// * 该回调中的参数会覆盖请求原型中配置的参数
		configCallback: (request) {
			request.stringChannel();
		},
	);
}
