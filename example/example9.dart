import 'package:happypass/happypass.dart';

/// 本示例主要演示请求中断器 [RequestCloser] 的使用
/// 为了区分多种情况，使用多个方法分别说明:
/// [method1] 在请求开始后中断请求
/// [method2] 在请求开始前中断请求
/// [method3] 在请求开始后中断请求，并指定一个响应结果
/// [method4] 在请求开始后中断请求，连续中断请求，并指定不同响应结果，观察生效情况
/// [method5] 为请求设置多个中断器，在请求开始后依次中断，观察生效情况
/// [method6] 多个请求使用同一个中断器，在请求开始后中断
/// [method7] 多个请求使用同一个中断器，在请求开始后中断，并根据不同请求返回不同的响应结果
/// * `RequestCloser` 可以被多个请求同时使用，当主动调用中断时，多个请求将会被同时中断并且强制返回统一结果
void main() async {
	method1();
	method2();
	method3();
	method4();
	method5();
	method6();
	method7();
}

void method1() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();
	
	// 发送 GET 请求
	final resultFuture = Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置请求中断器
		request.addRequestCloser(requestCloser);
	});
	
	// 请求开始后中断请求
	requestCloser.close();
	print("method1: ${await resultFuture}");
}

void method2() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();
	
	// 请求开始前中断请求
	requestCloser.close();
	
	// 发送 GET 请求
	final resultFuture = Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置请求中断器
		request.addRequestCloser(requestCloser);
	});
	
	print("method2: ${await resultFuture}");
}

void method3() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();
	
	// 发送 GET 请求
	final resultFuture = Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置请求中断器
		request.addRequestCloser(requestCloser);
	});
	
	// 请求开始后中断请求，并指定一个响应结果
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call"));
	print("method3: ${await resultFuture}");
}

void method4() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();
	
	// 发送 GET 请求
	final resultFuture = Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置请求中断器
		request.addRequestCloser(requestCloser);
	});
	
	// 请求开始后连续中断请求，指定不同的响应结果
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (1)"));
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (2)"));
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (3)"));
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (4)"));
	print("method4: ${await resultFuture}");
}

void method5() async {
	// 首先我们需要实例化多个 RequestCloser 对象
	final requestCloser1 = RequestCloser();
	final requestCloser2 = RequestCloser();
	final requestCloser3 = RequestCloser();
	final requestCloser4 = RequestCloser();
	final requestCloser5 = RequestCloser();
	
	// 发送 GET 请求
	final resultFuture = Request.quickGet(url: "https://www.baidu.com", configCallback: (request) {
		// 配置多个请求中断器
		request.addRequestCloser(requestCloser1);
		request.addRequestCloser(requestCloser2);
		request.addRequestCloser(requestCloser3);
		request.addRequestCloser(requestCloser4);
		request.addRequestCloser(requestCloser5);
	});
	
	// 请求开始后依次使用中断器进行中断
	requestCloser1.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (1)"));
	requestCloser2.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (2)"));
	requestCloser3.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (3)"));
	requestCloser4.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (4)"));
	requestCloser5.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call (5)"));
	print("method5: ${await resultFuture}");
}

void method6() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	final requestCloser = RequestCloser();
	
	// 构建一个请求原型方便我们批量执行请求
	// * 请求原型无法设置中断器
	final prototype = RequestPrototype();
	prototype.setUrl("https://www.baidu.com");
	
	// 建立配置请求回调
	final configCallback = (Request request) {
		request.addRequestCloser(requestCloser);
	};
	
	// 发送多个 GET 请求
	final resultFuture1 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture2 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture3 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture4 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture5 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	
	// 请求开始后中断请求
	requestCloser.close(finishResponse: ErrorPassResponse(msg: "interrupt request after call"));
	print("method6-reponse1: ${await resultFuture1}");
	print("method6-reponse2: ${await resultFuture2}");
	print("method6-reponse3: ${await resultFuture3}");
	print("method6-reponse4: ${await resultFuture4}");
	print("method6-reponse5: ${await resultFuture5}");
}

void method7() async {
	// 首先我们需要实例化一个 RequestCloser 对象
	// 设置 `responseChooseCallback` 回调，为每个请求提供不同的响应结果
	// * 前四个请求分别返回不同的响应结果，第五个请求返回 null
	final requestCloser = RequestCloser(
		responseChooseCallback: (ChainRequestModifier modifier) {
			switch(modifier.getReqId()) {
				case 1:
					return ErrorPassResponse(msg: "reqeust 1 canceled");
				case 2:
					return ErrorPassResponse(msg: "reqeust 2 canceled");
				case 3:
					return ErrorPassResponse(msg: "reqeust 3 canceled");
				case 4:
					return ErrorPassResponse(msg: "reqeust 4 canceled");
			}
		}
	);
	
	// 构建一个请求原型方便我们批量执行请求
	// * 请求原型无法设置中断器
	final prototype = RequestPrototype();
	prototype.setUrl("https://www.baidu.com");
	
	// 建立配置请求回调
	// 为每个请求设置请求 id，便于中断器区分
	int reqId = 1;
	final configCallback = (Request request) {
		request.setRequestId(reqId ++);
		request.addRequestCloser(requestCloser);
	};
	
	// 发送多个 GET 请求
	final resultFuture1 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture2 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture3 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture4 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	final resultFuture5 = Request.quickGet(prototype: prototype, configCallback: configCallback);
	
	// 请求开始后中断请求
	requestCloser.close();
	print("method7-reponse1: ${await resultFuture1}");
	print("method7-reponse2: ${await resultFuture2}");
	print("method7-reponse3: ${await resultFuture3}");
	print("method7-reponse4: ${await resultFuture4}");
	print("method7-reponse5: ${await resultFuture5}");
}