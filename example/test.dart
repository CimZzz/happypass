import 'package:happypass/happypass.dart';

void main () async {
	final request = Request.construct();
	request.addFirstInterceptor(MockClientPassInterceptor((builder) => {
		"www.baidu.com": builder.mock(
			get: [
				builder.doDirectly(() => SuccessPassResponse(body: "mocked!"))
			]
		)
	}));
}