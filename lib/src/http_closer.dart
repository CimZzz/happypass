part of 'http.dart';


/// 请求中断器
/// 用于外部中断请求
class RequestCloser {
	Set<ChainRequestModifier> _modifierSet;
	ResultPassResponse _closeResponse;
	
	/// 判断是否请求中断
	bool _isClosed = false;
	bool get isClosed => _isClosed;
	
	/// 装配 [ChainRequestModifier]
	void _assembleModifier(ChainRequestModifier modifier) {
		if(isClosed) {
			modifier._finishResponse = _closeResponse;
		}
		else {
			this._modifierSet ??= Set();
			this._modifierSet.add(modifier);
		}
	}
	
	/// 强制中断请求
	void close({ResultPassResponse finishResponse = const ErrorPassResponse(msg: "request interrupted!")}) {
		if(isClosed) {
			return;
		}
		_isClosed = true;
		_closeResponse = finishResponse;
		if(this._modifierSet != null) {
			this._modifierSet.forEach((modifier) {
				modifier.close(finishResponse: finishResponse);
			});
		}
	}
	
	/// 回收引用
	void _finish(ChainRequestModifier modifier) {
		this._modifierSet?.remove(modifier);
	}
}