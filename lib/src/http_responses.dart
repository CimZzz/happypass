part of 'http.dart';

/// Http 请求响应体的基类
abstract class PassResponse {
  const PassResponse();
}

/// 结果响应体
abstract class ResultPassResponse extends PassResponse {
  const ResultPassResponse(this.isSuccess);

  final bool isSuccess;
}

/// Http 请求失败时返回的响应体
class ErrorPassResponse extends ResultPassResponse {
  const ErrorPassResponse({this.msg, this.error, this.stacktrace}) : super(false);
  final String msg;
  final dynamic error;
  final StackTrace stacktrace;

  @override
  String toString() => msg ?? "null";
}

/// Http 请求成功是返回的响应体
class SuccessPassResponse extends ResultPassResponse {
  SuccessPassResponse({this.body}) : super(true);
  final dynamic body;

  @override
  String toString() => "$body";
}

/// Http 加工的响应体
class ProcessablePassResponse extends PassResponse {
  ProcessablePassResponse(this.rawResponse, this.bodyData, this.body);

  final HttpClientResponse rawResponse;
  final List<int> bodyData;
  final dynamic body;
}
