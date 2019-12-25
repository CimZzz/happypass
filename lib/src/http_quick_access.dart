
import 'package:happypass/happypass.dart';
import 'dart:io'
if (dart.library.html) 'dart:html' as _file;

/// 快速请求处理回调
typedef RequestConfigCallback = void Function(Request request);

/// `happypass` 快速访问工具类唯一实例
HappyPassQuickAccess happypass = HappyPassQuickAccess._();

/// `happypass` 快速访问工具类
/// 借助 `happypass` Api，快速实现一些基本请求功能
/// - GET 请求
/// - POST 请求
class HappyPassQuickAccess {
	HappyPassQuickAccess._();

	/// 快速进行一次 GET 请求
	/// - [url] : 请求的地址
	/// - [path] : 请求的部分路径
	/// - [prototype] : 请求原型，如果存在，那么会请求会从该原型分裂而来
	/// - [configCallback] : 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
	/// * [url]、[path]、[prototype] 三者不能同时为 `null`
	Future<ResultPassResponse> get({
		String url,
		String path,
		RequestPrototype prototype,
		RequestConfigCallback configCallback
	}) {
		return Request.quickGet(
			url: url,
			path: path,
			prototype: prototype,
			configCallback: configCallback
		);
	}

	/// 快速进行一次 POST 请求
	/// - [url] : 请求的地址
	/// - [path] : 请求的部分路径
	/// - [body] : 请求体，表示 POST 传递的请求数据
	/// - [prototype] : 请求原型，如果存在，那么会请求会从该原型分裂而来
	/// - [configCallback] : 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
	/// * [url]、[path]、[prototype] 三者不能同时为 `null`
	/// * [body] 不能为 `null`
	Future<ResultPassResponse> post({
		String url,
		String path,
		dynamic body,
		RequestPrototype prototype,
		RequestConfigCallback configCallback,
	}) {
		return Request.quickPost(
			url: url,
			path: path,
			body: body,
			prototype: prototype,
			configCallback: configCallback
		);
	}

	/// 快速下载并保存到指定文件
	/// - [downloadUrl] : 指定下载的 Url
	/// - [storePath] : 保存文件的路径
	/// - [file] : 指定保存的文件
	/// - [prototype] : 请求原型，如果存在，那么会请求会从该原型分裂而来
	/// - [configCallback] : 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
	/// * [downloadUrl] 不能为 null
	/// * [storePath] 和 [file] 不能同时为 null，如果两者都存在，那么 [file] 优先生效
	Future<ResultPassResponse> download({
		String downloadUrl,
		String storePath,
		_file.File file,
		RequestPrototype prototype,
		RequestConfigCallback configCallback,
	}) {
		if(file == null && storePath == null) {
			return Future(() => ErrorPassResponse(msg: "保存文件或路径不能为 null"));
		}

		final request = prototype?.spawn() ?? Request.construct();
		if (downloadUrl != null) {
			request.setUrl(downloadUrl);
		}

		file = file ?? _file.File(storePath);

		request.setResponseRawDataReceiverCallback((Stream<List<int>> rawData) async {
			_file.IOSink ioSink;
			try {
				ioSink = file.openWrite();
				await ioSink.addStream(rawData);
				ioSink.flush();
				return SuccessPassResponse(body: "download successed!");
			}
			catch(e, stacktrace) {
				return ErrorPassResponse(msg: "下载文件失败", error: e, stacktrace: stacktrace);
			}
			finally {
				if(ioSink != null) {
					await ioSink.close();
				}
			}
		});
		if (configCallback != null) {
			configCallback(request);
		}

		return request.doRequest();
	}
}