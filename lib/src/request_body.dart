part of 'http.dart';

/// 原始请求 Body 数据
/// 该对象不会被编码器进行编码
class RawBodyData {
  const RawBodyData({this.rawData});

  final List<int> rawData;
}

/// 请求体
/// 用来包装请求数据，来支持多种样式数据的处理
/// 注意该对象是一次性对象，不能持久化持有其引用
abstract class RequestBody {
  /// 是否覆盖请求头部中 `Content-Type` 字段
  /// 只有在请求头部中存在已指定的 `Content-Type` 字段时，该字段才会生效
  bool get overrideContentType => null;

  /// 请求数据的 Content-Type
  /// 当请求头中不包含 "Content-Type" 或者 [overrideContentType] 为 true 时，
  /// 该值会填充到请求头部之中
  String get contentType;

  /// 生成请求 Body 数据
  /// 提供请求数据
  Stream<dynamic> provideBodyData();
}
