import 'http_responses.dart';
import 'request_builder.dart';

/// 请求中断响应结果选择回调
typedef RequestCloserResponseChooseCallback = ResultPassResponse Function(ChainRequestModifier modifier);

/// 请求中断器
/// 用于外部中断请求
class RequestCloser {
	RequestCloser({this.responseChooseCallback});

	/// 全部监控的请求 Modifier
	Set<ChainRequestModifier> _modifierSet;

	/// 中断请求所提供的默认请求
	ResultPassResponse _closeResponse;

	/// 请求中断响应结果选择回调
	/// 如果设置了该回调，那么会根据每个被中断请求返回不同的最终响应结果
	/// * 如果该回调返回 `null`，那么仍然会使用 `_closeResponse` 作为其最终响应结果
	final RequestCloserResponseChooseCallback responseChooseCallback;

	/// 判断是否请求中断
	bool _isClosed = false;

	bool get isClosed => _isClosed;

	/// 强制中断请求
	void close({ResultPassResponse finishResponse = const ErrorPassResponse(msg: 'request interrupted!')}) {
		if (isClosed) {
			return;
		}
		_isClosed = true;
		_closeResponse = finishResponse;
		if (_modifierSet != null) {
			_modifierSet.forEach((modifier) {
				modifier.close(finishResponse: _pickFinishResponse(modifier));
			});
		}
	}

	/// 拾取最终响应结果
	/// 根据 [RequestCloserResponseChooseCallback] 和终结时指定的响应结果选取最终的响应结果
	ResultPassResponse _pickFinishResponse(ChainRequestModifier modifier) {
		if (responseChooseCallback != null) {
			return responseChooseCallback(modifier) ?? _closeResponse;
		} else {
			return _closeResponse;
		}
	}

	/// 装配 [ChainRequestModifier]
	/// 发生在实际执行请求逻辑之前
	void _assembleModifier(ChainRequestModifier modifier) {
		if (isClosed) {
			modifier._finishResponse = _pickFinishResponse(modifier);
		} else {
			_modifierSet ??= {};
			_modifierSet.add(modifier);
		}
	}

	/// 回收 [ChainRequestModifier] 引用
	void _finish(ChainRequestModifier modifier) {
		_modifierSet?.remove(modifier);
	}
}
