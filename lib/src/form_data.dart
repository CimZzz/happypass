import 'dart:async';

import 'package:happypass/happypass.dart';

/// 表单请求数据体
/// 对应使用的 Content-Type 为 'application/x-www-form-urlencoded'
/// 用来传递表单格式键值对数据
class FormDataBody extends RequestBody {
	/// 缺省的构造方法
	FormDataBody();

	/// 以键值对 Map 的形式创建 FormDataBody
	FormDataBody.createByMap(Map<String, String> map) {
		addMap(map);
	}

	/// 强制覆盖请求中的 `ContentType`
	@override
	bool get overrideContentType => true;

	@override
	String get contentType => 'application/x-www-form-urlencoded';

	/// 请求数据映射表
	Map<String, String> _bodyMap;

	/// 向 FormDataBody 中添加键值对数据
	/// `Key` 与 `Value` 不能为空，并会将 `Value` 转化为字符串
	/// * `Key` 与 `Value` 都会被 `Uri` 加密处理
	FormDataBody addPair(String key, Object value) {
		if (key == null || value == null) {
			return this;
		}

		_bodyMap ??= {};
		_bodyMap[Uri.encodeComponent(key)] = Uri.encodeComponent(value.toString());

		return this;
	}

	/// 向 FormDataBody 中添加键值对 Map
	/// 以键值对 Map 的类型添加数据
	FormDataBody addMap(Map<String, String> map) {
		if (map != null) {
			map.forEach(addPair);
		}
		return this;
	}

	/// 转化为 FormDataBody 数据
	@override
	Stream<dynamic> provideBodyData() async* {
		final bodyMap = _bodyMap;
		if (bodyMap == null) {
			yield null;
		}
		_bodyMap = null;

		var bodyStr = '';
		var isFirst = true;
		bodyMap.forEach((String key, String value) {
			if (isFirst) {
				isFirst = false;
			} else {
				bodyStr += '&';
			}
			bodyStr += '$key=$value';
		});
		yield bodyStr;
	}
}
