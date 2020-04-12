import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

/// 本示例表示简单的 http 转发服务端
void main() async {
	final server = await ServerSocket.bind('127.0.0.1', 4444);
	final list = [];
	await for(final socket in server) {
		print('new socket');
		thread(socket);
	}
}

class A {
	Socket socket;
}

class Bundle {
	A a;
	SendPort sendPort;
}

Future<void> thread(Socket socket) async {
	Socket dest;
	
	final completer = Completer();
	
	socket.listen((event) async {
		if(dest == null) {
			dest = await Socket.connect('49.234.99.78', 80);
			dest.listen((event) {
				var str = utf8.decode(event);
				final idx = str.indexOf('Server: ');
				if(idx != -1) {
					str = str.replaceAll('Server: ', 'Access-Control-Allow-Origin: *\r\nServer: ');
				}
				print(str);
				socket.add(event);
				socket.flush();
			}, onDone: () {
				print('completed remote!');
				dest = null;
			});
		}
		print(utf8.decode(event));
		dest.add(event);
		dest.flush();
	}, onDone: () {
		completer.complete();
	}, onError: (e) {
		completer.complete();
	});
	await completer.future;
	print('complete1');
}