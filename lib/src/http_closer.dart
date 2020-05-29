import 'dart:async';

import 'http_interceptor_chain.dart';
import 'http_responses.dart';

/// 请求中断响应结果选择回调
typedef RequestCloserResponseChooseCallback = ResultPassResponse Function(ChainRequestModifier modifier);

const _defaultErrorResponse = const ErrorPassResponse(msg: 'request interrupted!');

/// 请求中断器
/// 用于外部中断请求
class RequestCloser {
	RequestCloser({RequestCloserResponseChooseCallback responseChooseCallback}) :
			_responseChooseCallback = responseChooseCallback;

	/// 请求中断响应结果选择回调
	/// 如果设置了该回调，那么会根据每个被中断请求返回不同的最终响应结果
	/// * 如果该回调返回 `null`，那么仍然会使用 `_finishResponse` 作为其最终响应结果
	final RequestCloserResponseChooseCallback _responseChooseCallback;

	/// 判断是否已经中断了请求
	bool _isClosed = false;

	bool get isClosed => _isClosed;

	/// 强制中断返回的响应结果
	PassResponse _finishResponse;

	/// 请求中断代理执行域集合
	Set<RequestCloseScope> _scopeSet;

	/// 注册请求中断代理执行域
	/// 若此时已经中断，那么会立即中断执行域
	void _registerRequestCloseScope(RequestCloseScope scope) {
		if (isClosed) {
			scope._interruptScope(_responseChooseCallback, _finishResponse);
			return;
		}

		_scopeSet ??= {};
		_scopeSet.add(scope);
	}

	/// 注销请求中断代理执行域
	void _unregisterRequestCloseScope(RequestCloseScope scope) {
		if (_scopeSet != null) {
			_scopeSet.remove(scope);
		}
	}

	/// 强制执行中断操作逻辑
	void _close() {
		if (_scopeSet != null) {
			final tempSet = _scopeSet;
			_scopeSet = null;
			tempSet.forEach((scope) {
				scope._interruptScope(_responseChooseCallback, _finishResponse);
			});
		}
	}

	/// 强制中断请求
	void close({PassResponse finishResponse = _defaultErrorResponse}) {
		if (isClosed) {
			return;
		}

		_isClosed = true;
		_finishResponse = finishResponse ?? _defaultErrorResponse;
		_close();
	}
}

/// 可中断请求结果 Future
class RequestClosable<T> implements Future<T> {
	final RequestCloser _closer;
	final Future<T> _future;

	RequestClosable(this._closer, this._future);

	@override
	Stream<T> asStream() => _future.asStream();

	@override
	Future<T> catchError(Function onError, {bool Function(Object error) test}) =>
		_future.catchError(onError, test: test);

	@override
	Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function onError}) =>
		_future.then(onValue, onError: onError);

	@override
	Future<T> timeout(Duration timeLimit, {FutureOr<T> Function() onTimeout}) =>
		_future.timeout(timeLimit, onTimeout: onTimeout);

	@override
	Future<T> whenComplete(FutureOr Function() action) => _future.whenComplete(action);

	/// 立即中断当前请求
	void close({PassResponse finishResponse = _defaultErrorResponse}) {
		_closer.close(finishResponse: _defaultErrorResponse);
	}
}


/// 请求代理执行完成回调
typedef RequestCloseCallback = void Function();

/// 请求中断代理执行域
/// 请求中断器可以通过该类立即中断拦截流程，返回结果
class RequestCloseScope {
	Completer<PassResponse> _realBusinessCompleter;
	Completer<PassResponse> _innerCompleter;
	StreamSubscription _innerSubscription;
	RequestCloseCallback _callback;
	bool _isStarted = false;

	ChainRequestModifier _modifier;

	ResultPassResponse _finishResponse;

	ResultPassResponse get finishResponse => _finishResponse;

	bool _isClosed = false;

	bool get isClosed => _isClosed;

	void assembleModifier(ChainRequestModifier modifier) {
		_modifier = modifier;
	}

	void registerRequestCloser(Iterable<RequestCloser> closers) {
		if (closers != null) {
			for (final closer in closers) {
				if (_isClosed) {
					return;
				}
				closer._registerRequestCloseScope(this);
			}
		}
	}

	void unregisterRequestCloser(Iterable<RequestCloser> closers) {
		if (closers != null) {
			for (final closer in closers) {
				closer._unregisterRequestCloseScope(this);
			}
		}
	}


	/// 代理执行请求逻辑
	/// 大致流程如下:
	///
	/// A ----- C
	///         |
	/// B -------
	///
	/// A - 表示实际请求处理逻辑
	/// B - 表示中断逻辑
	/// C - 表示最后返回的处理结果
	/// A 或 B 首先触发的一方任意结果都会成为 C 的最终结果
	FutureOr<PassResponse> startScopeRun(Future<PassResponse> realFuture, RequestCloseCallback callback) {
		if (_isClosed) {
			callback();
			return _finishResponse;
		}
		_isStarted = true;
		_callback = callback;
		_realBusinessCompleter = Completer();
		_innerCompleter = Completer();
		_innerSubscription = _realBusinessCompleter.future.asStream().listen((data) {
			if (!_isClosed) {
				_isClosed = true;
				_innerCompleter.complete(data);
				_callback();
			}
		}, onError: (e, stackTrace) {
			if (!_isClosed) {
				_isClosed = true;
				_innerCompleter.complete(ErrorPassResponse(
					msg: e.toString(), error: e, stacktrace: stackTrace));
				_callback();
			}
		});
		_realBusinessCompleter.complete(realFuture);
		return _innerCompleter.future;
	}

	/// 中断 Scope
	void _interruptScope(RequestCloserResponseChooseCallback callback, ResultPassResponse defaultResponse) {
		if (!_isClosed) {
			try {
				_finishResponse = callback(_modifier) ?? defaultResponse;
			}
			catch (e) {
				_finishResponse = defaultResponse;
			}
			_isClosed = true;
			if (!_isStarted) {
				return;
			}
			// 主动中断时取消 Stream 订阅
			_innerSubscription.cancel();
			_innerCompleter.complete(finishResponse);
			_callback();
		}
	}
}