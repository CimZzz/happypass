## 开始使用

当前最新版本为: 1.0.0

在 "pubspec.yaml" 文件中加入
```yaml
dependencies:
  happypass: ^1.0.0
```

github
```text
https://github.com/CimZzz/happypass
```

### 构建一个请求 (Request)

[查看测试代码](example/example1.dart)

``HappyPass`` 将请求对象抽象为 `Request` 类，借由配置 `Request` 来实现自定义请求的目的。

为了发送请求，首先我们需要构建 ``Request`` 类

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
.addFirstInterceptor(SimplePassInterceptor((chain) {
	return chain.waitResponse();
}))
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
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain A");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain B");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain C");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain D");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain E");
	return chain.waitResponse();
}))
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
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain A");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain B");
	// 这次我们在 B 点直接执行请求
	return chain.requestForPassResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain C");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain D");
	return chain.waitResponse();
}))
.addFirstInterceptor(SimplePassInterceptor((chain) {
	print("chain E");
	return chain.waitResponse();
}))
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
        Future<List<int>> responseBodyBuilder(HttpClientResponse httpResp)
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
.addFirstInterceptor(SimplePassInterceptor((chain) {
	return chain.waitResponse();
}));
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
导致其 `UI` 卡顿。因此，我们可以配置 `Request` 运行环境代理，将请求放到其他 `Isolate` 中执行，以此达到优化的目的

```dart
// 通过 [Request.construct] 方法直接创建实例
Request request = Request.construct();
// 设置 Request 路径
request.setUrl("https://www.baidu.com/")
// 设置 Request 运行环境
.setRequestRunProxy((executor) async {
	print("执行请求");
	print("延时2秒执行");
	// 假设创建 Isolate
	await Future.delayed(const Duration(seconds: 2));
    // 使用 executor
	return executor.execute();
})
// 设置解码器
.addLastDecoder(const Byte2Utf8StringDecoder())
// 添加拦截器
.addFirstInterceptor(SimplePassInterceptor((chain) {
	return chain.waitResponse();
}))
// GET 请求
.GET();
// 发送请求并打印响应结果
print(await request.doRequest());
```