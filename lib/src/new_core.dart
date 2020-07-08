import 'dart:async';

import 'http_responses.dart';

/// 请求配置
/// Author CimZzz
/// Since happy-pass 3.0
/// 用于配置请求参数
class PassRequestOptions {}

/// 请求响应链
/// Author CimZzz
/// Since happy-pass 3.0
/// 进行请求各个阶段的拦截
class PassRequestChain {
  PassRequestOptions _options;
}

/// 请求链结果结点
/// Author CimZzz
/// Since happy-pass 3.0
/// 请求进行到最后的步骤
class _ChainOfResult {
  PassRequestChain _chain;
  var _isDone = false;

  /// 返回最终的请求结果
  FutureOr<ResultPassResponse> untilResult(void hook()) {
    return null;
  }

  T _doChain<T>(T action()) {
    if (!_isDone) {
      _isDone = true;
      return action();
    }
    return null;
  }
}

class _ChainOfInterrupt extends _ChainOfResult {

}

/// 请求链请求准备结点
/// Author CimZzz
/// Since happy-pass 3.0
/// 请求在未执行之前进行配置修改的步骤
class _ChainOfPrepared extends _ChainOfInterrupt {
  _ChainOfInterrupt prepared(void prepared(PassRequestOptions options)) {
    return _doChain(() {
      prepared(_chain._options);
      return _ChainOfInterrupt()
          .._chain = _chain;
    });
  }
}
