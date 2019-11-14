import 'package:happypass/happypass.dart';

void main() async {
	final protoType = RequestPrototype();
	protoType.addFirstEncoder(const Utf8String2ByteEncoder());
	protoType.addLastDecoder(const Byte2Utf8StringDecoder());
	protoType.addLastDecoder(const Utf8String2JSONDecoder());
	protoType.setUrl("http://quan.suning.com/getSysTime.do");
	protoType.addFirstInterceptor(SimplePassInterceptor((chain) async {
//		print("url: ${chain.modifier.getUrl()}");
//		final resp = await chain.waitResponse();
//		print("resp: $resp");
		return chain.waitResponse();
	}));

	print(await protoType.spawn().GET().doRequest());
	print(await protoType.spawn().GET().doRequest());
}