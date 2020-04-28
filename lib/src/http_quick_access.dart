import 'http_responses.dart';
import 'core.dart';
import 'request_builder.dart';
import 'adapter/file.dart';

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
		assert(url != null || path != null || prototype != null);
		final request = prototype?.spawn() ?? Request();
		if (url != null) {
			request.setUrl(url);
		}
		if (path != null) {
			request.addPath(path);
		}
		request.GET();
		if (configCallback != null) {
			configCallback(request);
		}
		return request.doRequest();
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
		assert(url != null || path != null || prototype != null);
		if (body == null) {
			return null;
		}
		final request = prototype?.spawn() ?? Request();
		if (url != null) {
			request.setUrl(url);
		}
		if (path != null) {
			request.addPath(path);
		}
		request.POST(body);
		if (configCallback != null) {
			configCallback(request);
		}
		return request.doRequest();
	}
	
	/// 快速下载并保存到指定文件
	/// - [downloadUrl] : 指定下载的 Url
	/// - [storePath] : 保存文件的路径
	/// - [prototype] : 请求原型，如果存在，那么会请求会从该原型分裂而来
	/// - [configCallback] : 请求配置回调。在执行之前会调用一次该回调，对请求做最后的配置
	/// * [downloadUrl] 不能为 null
	/// * [storePath] 不能为 null
	Future<ResultPassResponse> download({
		String downloadUrl,
		String storePath,
		RequestPrototype prototype,
		RequestConfigCallback configCallback,
	}) async {
		final fileWrapper = FileWrapper(storePath);
		
		final errMsg = fileWrapper.checkErrMsg();
		
		if (errMsg != null) {
			return ErrorPassResponse(msg: errMsg);
		}
		
		final request = prototype?.spawn() ?? Request();
		if (downloadUrl != null) {
			request.setUrl(downloadUrl);
		}
		
		request.setResponseRawDataReceiverCallback((Stream<List<int>> rawData) async {
			if (await fileWrapper.saveFileData(rawData)) {
				return SuccessPassResponse(body: "download successed!");
			}
			else {
				return ErrorPassResponse(msg: "下载文件失败: ${fileWrapper.checkErrMsg() ?? 'null'}");
			}
		});
		if (configCallback != null) {
			configCallback(request);
		}
		
		return await request.doRequest();
	}
}