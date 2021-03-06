import 'dart:async';
import 'request_body.dart';

/// 流请求数据体
/// 会将流的数据作为请求数据
/// * 每次从流中读到数据都会通过编码器进行编码
class StreamDataBody extends RequestBody {
	StreamDataBody(this._stream, {this.streamContentType = 'application/octet-stream'});
	
	/// 流内容类型
	/// 默认类型为 `application/octet-stream`
	final String streamContentType;
	
	/// 数据流
	final Stream _stream;
	
	@override
	String get contentType => streamContentType ?? 'application/octet-stream';
	
	@override
	Stream provideBodyData() {
		return _stream;
	}
}
