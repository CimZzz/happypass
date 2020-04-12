

import 'dart:io';

import 'package:happypass/happypass.dart';

void main() async {
	final result = await happypass.post(
		url: "http://virtual-lightning.com/shop/test.php",
		body: MultipartDataBody()
			..addMultipartFile('b', File('/Users/cimzzz/Desktop/hsb_pack.sh'))
			..addMultipartFile('c', File('/Users/cimzzz/Desktop/hsb_pack.sh'))
			..addMultipartText('a', '1'),
		configCallback: (request) {
			request.stringChannel();
		}
	);
	
	print(result);
}