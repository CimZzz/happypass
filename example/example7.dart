import 'dart:io';

import 'package:happypass/happypass.dart';

/// 本示例演示了如何利用拦截器实现自定义请求
void main() async {
  // 为了方便依然使用 [Request.quickGet] 方法
  final result = await Request.quickGet(
      url: "https://www.baidu.com",
      configCallback: (request) {
        // 设置字符串编解码器
        request.stringChannel();
        // 设置一个自定义拦截器，在其中实现请求的拦截
        request.addFirstInterceptor(SimplePassInterceptor((chain) {
          // 使用 `happypass` 提供的执行请求逻辑
          // 分为以下几个流程
          // 1. 构建 `HttpClient` 流程，可以在自定义回调中对 `HttpClient` 进行一些初始化配置
          // 比如对于 Http 证书的验证回调等等..
          //
          // 2. 通过 `HttpClient`，生成 `HttpClientRequest` 流程。根据设置的请求方法和指定的 `Url`
          // 生成请求
          //
          // 3. 对 `HttpClientRequest` 进行配置流程。主要是对于请求头部和请求数据的传输与处理
          //
          // 4. 使用现有的 `HttpClientRequest` 执行请求流程。需要将获取到的 `HttpClientResponse` 解析成 `PassResponse` 对象
          //
          //
          // 在实现流程的工程中，`ChainRequestModifier` 可以提供数据的访问，便捷的方法，请合理运用达到事半功倍的效果
          // 为了实现流程高度控制，`happypass` 提供了一系列 `hook` 回调支持开发者自定义这四个主要流程
          // 你可以自定义 `hook` 某一个流程，也可以全部 `hook`
          // 下面对全部流程进行了 `hook`，但其实现与缺省实现一致
          return chain.requestForPassResponse(
              // HttpClient 构造器
              // 可以自定义 HttpClient 的构造方式
              httpClientBuilder: (ChainRequestModifier modifier) {
            final client = HttpClient();
            modifier.fillLooseTimeout(client);
            return client;
          },

              // HttpClientRequest 构造器
              // 可以自定义 HttpClientRequest 的构造方式
              httpReqBuilder: (HttpClient client, ChainRequestModifier modifier) {
            final uri = Uri.parse(modifier.getUrl());
            if (modifier.getRequestMethod() == RequestMethod.GET) {
              return modifier.runInConnectTimeout(client.getUrl(uri));
            } else {
              return modifier.runInConnectTimeout(client.postUrl(uri));
            }
          },

              // HttpClientRequest 消息配置构造
              // 用于配置请求头，发送请求 Body
              // 如果该方法返回了 PassResponse，那么该结果将会直接被当做最终结果返回
              httpReqInfoBuilder: (HttpClientRequest httpReq, ChainRequestModifier modifier) async {
            await modifier.fillRequestHeader(httpReq, modifier);
            await modifier.fillRequestBody(httpReq, modifier);
          },

              // Response Body 构造器
              // 可以自行读取响应数据并对其修改，视为最终返回数据
              responseBuilder: (HttpClientRequest httpReq, ChainRequestModifier modifier) async {
            if (modifier.existResponseRawDataReceiverCallback()) {
              // 如果存在响应数据原始接收回调
              // 执行 [analyzeResponseByReceiver] 方法
              return await modifier.runInReadTimeout(modifier.analyzeResponseByReceiver(modifier, httpReq: httpReq));
            } else {
              // 执行 [analyzeResponse] 方法
              return await modifier.runInReadTimeout(modifier.analyzeResponse(modifier, httpReq: httpReq));
            }
          });
        }));
        // 设置一个打印请求的拦截器
        request.addFirstInterceptor(const LogUrlInterceptor());
      });

  // 打印最终结果
  print(result);
}
