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

