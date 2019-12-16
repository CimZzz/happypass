## happypass

happy pass,pass happy to everybody!

`happypass` 是一个高度自由化、可定制的 http 请求库，如果你喜欢掌控自己的代码，那么一定会爱上它！

本项目是开源项目，如果大家有好的想法和意见，可以告知我或者一起参与其中，共同维护我们的开源环境。

### 快速集成

当前最新版本为: 1.0.6

在 "pubspec.yaml" 文件中加入
```yaml
dependencies:
  happypass: ^1.0.6
```

[github](https://github.com/CimZzz/happypass)

```text
https://github.com/CimZzz/happypass
```

### 最详细的示例

`happypass` 字面意思就是想要 `pass happy to everybody`，对于提高工程师使用体验更是视为重中之重。所以在 `happypass` 中，有着大量详细示例以供参考，帮助我们工程师
能够快速上手使用。

[示例目录](https://github.com/CimZzz/happypass/blob/master/example)

### 构建一个请求 (Request)

`happypass` 将请求对象抽象为 `Request` 类，借由配置 `Request` 来实现自定义请求的目的。

下面是一个极简的示例:
```dart
import 'package:happypass/happypass.dart';
void main() async {
	PassResultResponse result = await Request.quickGet(url: "https://www.baidu.com/", configCallback: (request) {
		request.stringChannel();
	});

	print(result);
}
```

仅仅几行代码，你就完成了一次 `GET` 请求！

当然，这是最基本的一小部分功能，还有非常多的强大功能帮助你实现主宰自己的 `http` 请求。

如果想要全面了解 `happypass` 功能覆盖，还请查看[详细示例](https://github.com/CimZzz/happypass/blob/master/example)

对于上面的示例，我们可以做一些扩展配置，如设置请求头部等:

```dart
request.setRequestHeader("content-type", "application/json");
```

> 需要注意的是，Request 无法直接实例化。如果想要构建一个全新的 `Request` 对象，请使用 `Request.construct()` 方法

### RequestPrototype

RequestPrototype(请求原型)，也可以理解为请求的`模板`。利用请求原型预先配置好某些属性，然后在使用的时候快速生成一个配置好的请求，这样做的好处是避免重复配置请求参数，防止不必要的代码冗余。

实例化一个请求原型
```dart
import 'package:happypass/happypass.dart';
void main() async {
    Request
}
```



```dart
// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();
```

然后配置 ``Request``

```dart
// 设置 Request 路径
request.setUrl("https://www.baidu.com/")
// 设置 Request 头部
.setRequestHeader("Hello", "World")
// 设置解码器（将响应数据转换为 UTF8 字符串）
.addLastDecoder(const Byte2Utf8StringDecoder())
// 添加拦截器
.addFirstInterceptor(const LogUrlInterceptor())
// GET 请求
.GET();
```

上述配置了 Request 路径、头部、解码器、拦截器和请求方法。

然后发送请求获得结果

```dart
// 发送请求并打印响应结果
print(await request.doRequest());
```

以上完成了一次简单的 `GET` 请求。

### 编码器

[查看测试代码](example/example2.dart)

在 `POST` 请求中，最终发送的请求数据是 `List<int>` 类型，而编码器的作用就是将 `body` 中的数据进行转换，最终转化为 `List<int>` 类型数据。

如下:
```dart
// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();
// 设置 Request 路径
request.setUrl("http://xxxxxx")
// 设置请求方法为 POST
// body 是一个 Map，所以需要配置编码器将 Map 转化为 List<int> 数据
// 假设服务端需要的数据时 JSON 字符串
.POST({
	"data": "helloworld"
})
// 首先将 Map 转化为 JSON 字符串
.addFirstEncoder(const JSON2Utf8StringEncoder())
// 然后将 String 转化为 List<int>
.addFirstEncoder(const Utf8String2ByteEncoder())
// 将响应数据 List<int> 转化为 String
.addLastDecoder(const Byte2Utf8StringDecoder());
// 发送请求并打印响应结果
print(await request.doRequest());
```

这样，编码器先通过 `JSON2Utf8StringEncoder` 将 ``Map`` 转换为 `JSON` 字符串，再通过 `Utf8String2ByteEncoder` 将 `JSON` 字符串转换为 `List<int>` 字节数组。

目前只有 ``POST`` 请求会用到编码器。

### 解码器

[查看测试代码](example/example3.dart)

在请求之后，接收到的响应数据是 `List<int>` 类型，我们可以通过配置解码器的方式将其转换为我们所需要的类型。

使用编码器实例中的部分代码，针对解码器部分进行修改

```dart

// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();
// 设置 Request 路径
request.setUrl("http://xxxxxx")
...
// 将响应数据 List<int> 转化为 String
.addLastDecoder(const Byte2Utf8StringDecoder())
// 然后 String 转化为 Map
.addLastDecoder(const Utf8String2JSONDecoder());
// 发送请求并打印响应结果
print(await request.doRequest());
```

解码器先通过 `Byte2Utf8StringDecoder` 将 `List<int>` 转换为 `JSON` 字符串，在通过 `Utf8String2ByteEncoder` 将 `JSON` 字符串转换为 `Map`

### 拦截器

[查看测试代码](example/example4.dart)

拦截器负责处理 `Request` 和生成 `Response`。默认情况下，每个请求都会携带一个缺省的拦截器 `BusinessPassInterceptor`，该拦截器主要的目的就是将请求
转化为对应的 `Response`

首先声明两个拦截器:
```dart
class SimpleIntercept1 extends PassInterceptor {
	const SimpleIntercept1(this.name);

	final String name;

	@override
	Future<PassResponse> intercept(PassInterceptorChain chain) {
		print(name);
		return chain.waitResponse();
	}
}

class SimpleIntercept2 extends PassInterceptor {
	const SimpleIntercept2(this.name);

	final String name;

	@override
	Future<PassResponse> intercept(PassInterceptorChain chain) {
		print(name);
		return chain.requestForPassResponse();
	}
}
```

可以给请求配置拦截器观察一下执行流程:
```dart
// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();
// 设置 Request 路径
request.setUrl("https://www.baidu.com/")
// 设置 Request 头部
.setRequestHeader("Hello", "World")
// 设置解码器
.addLastDecoder(const Byte2Utf8StringDecoder())
// 添加拦截器
.addFirstInterceptor(const SimpleIntercept1("Chain A"))
.addFirstInterceptor(const SimpleIntercept1("Chain B"))
.addFirstInterceptor(const SimpleIntercept1("Chain C"))
.addFirstInterceptor(const SimpleIntercept1("Chain D"))
.addFirstInterceptor(const SimpleIntercept1("Chain E"))
// GET 请求
.GET();
// 发送请求并打印响应结果
print(await request.doRequest());
```

执行结果如下:
```text
chain E
chain D
chain C
chain B
chain A
...
// real response data
```

拦截器采取的方式是首位插入，所以最先添加的拦截器最后执行

正常情况下，拦截器的工作应该如下

pass request : E -> D -> C -> B -> A -> BusinessPassInterceptor

return response : BusinessPassInterceptor -> A -> B -> C -> D -> E

上述完成了一次拦截工作，Request 的处理和 Response 的构建都在 BusinessPassInterceptor 这个拦截器中完成

如果在特殊情况下，某个拦截器（假设 B）意图自己完成请求处理，那么整个流程如下:

pass request : E -> D -> C -> B

return response : B -> C -> D -> E

上述在 B 的位置直接拦截，请求并未传递到 BusinessPassInterceptor，所以 Request 的处理和 Response 的构建都应由 B 完成

这次我们在 B 点进行拦截

```dart
// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();

// 设置 Request 路径
request.setUrl("https://www.baidu.com/")
// 设置解码器
.addLastDecoder(const Byte2Utf8StringDecoder())
// 添加拦截器
.addFirstInterceptor(const SimpleIntercept1("Chain A"))
.addFirstInterceptor(const SimpleIntercept2("Chain B"))
.addFirstInterceptor(const SimpleIntercept1("Chain C"))
.addFirstInterceptor(const SimpleIntercept1("Chain D"))
.addFirstInterceptor(const SimpleIntercept1("Chain E"))
// GET 请求
.GET();

// 发送请求并打印响应结果
print(await request.doRequest());
```

执行结果如下
```text
chain E
chain D
chain C
chain B
...
// real response data
```

拦截器回调参数中的 `PassInterceptorChain` 提供了一些便捷的方法:
```dart
class PassInterceptorChain {

    ...

    /// 等待其他拦截器返回 `Response`
    Future<PassResponse> waitResponse() async
    
    /// 获取拦截链请求修改器
    /// 可以在拦截器中修改请求的大部分参数，直到有 `PassResponse` 返回
    ChainRequestModifier get modifier;
    
    /// 实际执行 `Request` 获得 `Response`
    /// 提供了一些可选回调，最大限度满足自定义 Request 的自由
    Future<PassResponse> requestForPassResponse async ({
        /// HttpClient 构造器
        /// 可以自定义 HttpClient 的构造方式
        HttpClient httpClientBuilder(),
        /// HttpClientRequest 构造器
        /// 可以自定义 HttpClientRequest 的构造方式
        Future<HttpClientRequest> httpReqBuilder(HttpClient client, ChainRequestModifier modifier),
        /// HttpClientRequest 消息配置构造
        /// 用于配置请求头，发送请求 Body
        /// 如果该方法返回了 PassResponse，那么该结果将会直接被当做最终结果返回
        PassResponse httpReqInfoBuilder(HttpClientRequest httpReq, ChainRequestModifier modifier),
        /// HttpClientResponse 构造器
        /// 可以自定义 HttpClientResponse 的构造方式
        Future<HttpClientResponse> httpRespBuilder(HttpClientRequest httpReq),
        /// Response Body 构造器
        /// 可以自行读取响应数据并对其修改，视为最终返回数据
        Future<PassResponse> responseBuilder(HttpClientRequest httpReq, ChainRequestModifier modifier)
    });

    ...
}
```

具体的细节逻辑可以参考[源代码](lib/src/http_interceptors.dart)

### 请求原型

[查看测试代码](example/example5.dart)

避免大量不必要的请求配置操作，可以使用请求原型来实现快速构建配置相同的请求

```dart
// 通过 [Request.construct] 方法直接创建实例
RequestPrototype requestPrototype = RequestPrototype();

// 设置 Request 路径
requestPrototype.setUrl("https://www.baidu.com/")
// 设置 Request 头部
.setRequestHeader("Hello", "World")
// 设置解码器
.addLastDecoder(const Byte2Utf8StringDecoder())
// 添加拦截器
.addFirstInterceptor(const LogUrlInterceptor());
// 不允许原型配置请求方法
//.GET();

// 由原型孵化出 Request
final request1 = requestPrototype.spawn();
final request2 = requestPrototype.spawn();
final request3 = requestPrototype.spawn();
// 异步执行所有请求
request1.GET().doRequest();
request2.GET().doRequest();
request3.GET().doRequest();
// 发送请求并打印响应结果
print("request1 : ${await request1.doRequest()}");
print("request2 : ${await request2.doRequest()}");
print("request3 : ${await request3.doRequest()}");
```

需要注意的是，为了避免 `RequestPrototype` 持有大量 `body` 而导致的内存问题，所以禁止 `Prototype` 配置请求方法。

#### 请求运行环境代理

[查看测试代码](example/example6.dart)

`Request` 默认会在当前 `Isolate` 下执行请求，而一些比如 `Flutter` 主 `Isolate` 通常会做一些 `UI` 渲染相关工作，大量的请求很可能会
导致其 `UI` 卡顿。因此，我们可以配置 `Request` 运行环境代理，将请求某些操作（如对请求 `Body` 进行编码）放到其他 `Isolate` 中执行，以此达到优化的目的

比如我们配置一个 Isolate 请求代理

```dart
class _Receiver<T, Q> {
	_Receiver(this.message, this.callback, this.port);
	final T message;
	final AsyncRunProxyCallback<T, Q> callback;
	final SendPort port;
	
	Future<Q> execute() async {
		return await callback(message);
	}
}


void _doProxy(_Receiver receiver) async {
	try {
		final result = await receiver.execute();
		receiver.port.send(result);
	}
	catch(e) {
		receiver.port.send(ErrorPassResponse());
	}
}

void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("https://www.baidu.com/")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.setRequestRunProxy(<T, Q>(asyncCallback, message) async {
		final receiverPort = ReceivePort();
		final isolate = await Isolate.spawn(_doProxy, _Receiver(message, asyncCallback, receiverPort.sendPort));
		final result = await receiverPort.first;
		receiverPort.close();
		isolate.kill();
		if(result is ErrorPassResponse) {
			throw IOException;
		}
		return result;
	})
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.addFirstInterceptor(const LogUrlInterceptor())
	// GET 请求
	.GET();
	// 发送请求并打印响应结果
	print(await request.doRequest());
}
```

#### 表单数据 - FormDataBody

[查看测试代码](example/example7.dart)

我们可以使用 `FormDataBody` 很便捷地发送表单数据，
如下面的例子:

```dart
void main() async {
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("xxxxx")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.POST(FormDataBody().addPair("hello", "world").addPair("happy", "everyday"));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}
```

使用 `FormDataBody`，把要传递的数据以 "键值对" 的方式发过去，就是那么简单。

#### Multipart 数据 - MultipartDataBody

[查看测试代码](example/example8.dart)

如果我们想要上传某个或多个文件，或者一个数据流，可以使用 `MultipartDataBody` 来实现，例子如下:

```dart
void main() async {
	File file = File("xxxx/temp.txt");
	// 通过 [Request.construct] 方法直接创建实例
	Request request = Request.construct();
	// 设置 Request 路径
	request.setUrl("xxx")
	// 设置 Request 运行环境，放置到 Isolate 中执行
	.addFirstEncoder(const Utf8String2ByteEncoder())
	// 设置解码器
	.addLastDecoder(const Byte2Utf8StringDecoder())
	// 设置拦截器
	.POST(MultipartDataBody().addMultipartFile("file", file));
	// 发送请求并打印响应结果
	print(await request.doRequest());
}
```