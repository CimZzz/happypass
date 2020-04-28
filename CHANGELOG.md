## 1.0.0

- 上传至 pub 库
- 支持 ``RequestPrototype``（请求原型），可以通过该模板快速生成请求
- 支持使用拦截器
- 支持配置自定义请求 ``body`` 编码器
- 支持配置自定义响应数据解码器

## 1.0.1

- 修复请求执行代理 BUG

## 1.0.2

- 新增操作 `Url` 的方法，现在可以追加路径和参数了

## 1.0.3

- 新增 RequestBody 类，用来传递更加丰富的请求数据:
    1. 使用 ``FormDataBody``，传递标准表单数据
    2. 使用 ``MultipartDataBody``，传递 `Multipart` 数据
- 修复因异常请求阻塞问题

## 1.0.4

- `MultipartDataBody` 中每一部分的头部将不会被加密
- 新增了两个便捷配置编解码器的方法

## 1.0.5

- 修复了 `MultipartDataBody` 最后一个字段多出 `\r\n` 的问题

## 1.0.6

重要改版

- 新增请求 `Http` 代理
- 新增请求中断器 `RequestCloser`
- 新增请求 `id`
- 新增请求总超时、连接超时与读取超时
- 新增 `CookieManager`
- 大规模重构文档 

## 1.0.7 

- 优化文档

## 1.0.8

- 重命名 HttpUtils -> PassHttpUtils
- 重命名 HttpUrl -> PassResolveUrl
- 新增 MockClientPassInterceptor，可以拦截客户端请求，返回模拟结果
- 新增 DEBUG 字段，用来打印不合逻辑的错误信息

## 1.0.8+1

- 格式化代码

## 1.0.8+2

- 格式化代码

## 1.0.8+3

- 格式化代码

## 1.0.8+4

- 格式化代码

## 1.0.8+5

- 格式化代码

## 1.0.8+6

- 格式化代码

## 1.0.8+7

- 格式化代码

## 1.0.8+8

- 格式化代码

## 1.0.8+9

- 格式化代码

## 1.0.9

- 优化代码

## 1.1.0

- 内部混合分文件定义
- `SuccessPassResponse` 和 `ProcessablePassResponse` 支持访问原始请求数据
- 新增 `HappyPassQuickAccess` 快速完成常用的基本请求

## 1.1.1
- 修复 `HappyPassQuickAccess` 不能外显的问题
- 优化内存管理

## 1.1.2
- 修复 `MockClientPassInterceptor` 部分情况下无法拦截的问题

## 1.1.3
- 修复 `Html` 下载兼容问题

## 2.0.0-pre
- 测试 2.0 版本

## 2.0.0-pre-2
- 测试 2.0 版本

## 2.0.0-pre-3
- 测试 2.0 版本
- 修复 Html HttpClient 的 bug

## 2.0.0-pre-4
- 修复 body 类型非法问题

## 2.0.0
- 2.0.0 版本正式发布，兼容移动端和 Web 端

## 2.0.1
- 修复 addQueryParams 符号相反的问题

## 2.0.2
- 修复 addQueryParams 值错误问题