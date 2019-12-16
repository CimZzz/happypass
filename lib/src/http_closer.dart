part of 'http.dart';


/// 请求中断器
/// 用于外部中断请求
class RequestCloser {
	ChainRequestModifier _modifier;
	ResultPassResponse _closeResponse;
	
	/// 判断请求是否已经结束
	bool _isClosed = false;
	bool get isClosed => this._modifier?._isClosed ?? _isClosed;
	
	/// 装配 [ChainRequestModifier]
	void _assembleModifier(ChainRequestModifier modifier) {
		if(isClosed) {
			modifier._finishResponse = _closeResponse;
		}
		else {
			this._modifier = modifier;
		}
	}
	
	/// 强制中断请求
	void close({ResultPassResponse finishResponse = const ErrorPassResponse(msg: "request interrupted!")}) {
		if(isClosed) {
			return;
		}
		_isClosed = true;
		if(this._modifier == null) {
			_closeResponse = finishResponse;
		}
		else {
			_modifier?.close(finishResponse: finishResponse);
		}
	}
	
	/// 回收引用
	void _finish() {
		_isClosed = true;
		_modifier = null;
		_closeResponse = null;
	}
}