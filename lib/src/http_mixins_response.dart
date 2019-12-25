part of 'http.dart';

/// 获取原始响应信息混合
/// 可以获取原始响应数据中的头部、状态码等信息
mixin _ResponseProxy implements _ResponseMixinBase {
	
	/**
	 * Returns the status code.
	 *
	 * The status code must be set before the body is written
	 * to. Setting the status code after writing to the body will throw
	 * a `StateError`.
	 */
	int get statusCode => this._httpResponse?.statusCode;
	
	/**
	 * Returns the reason phrase associated with the status code.
	 *
	 * The reason phrase must be set before the body is written
	 * to. Setting the reason phrase after writing to the body will throw
	 * a `StateError`.
	 */
	String get reasonPhrase => this._httpResponse?.reasonPhrase;
	
	/**
	 * Returns the content length of the response body. Returns -1 if the size of
	 * the response body is not known in advance.
	 *
	 * If the content length needs to be set, it must be set before the
	 * body is written to. Setting the content length after writing to the body
	 * will throw a `StateError`.
	 */
	int get contentLength => this._httpResponse?.contentLength;
	
	/**
	 * Gets the persistent connection state returned by the server.
	 *
	 * If the persistent connection state needs to be set, it must be
	 * set before the body is written to. Setting the persistent connection state
	 * after writing to the body will throw a `StateError`.
	 */
	bool get persistentConnection => this._httpResponse?.persistentConnection;
	
	/**
	 * Returns whether the status code is one of the normal redirect
	 * codes [HttpStatus.movedPermanently], [HttpStatus.found],
	 * [HttpStatus.movedTemporarily], [HttpStatus.seeOther] and
	 * [HttpStatus.temporaryRedirect].
	 */
	bool get isRedirect => this._httpResponse?.isRedirect;
	
	/**
	 * Returns the series of redirects this connection has been through. The
	 * list will be empty if no redirects were followed. [redirects] will be
	 * updated both in the case of an automatic and a manual redirect.
	 */
	List<RedirectInfo> get redirects => this._httpResponse?.redirects;
	
	/**
	 * Returns the client response headers.
	 *
	 * The client response headers are immutable.
	 */
	HttpHeaders get headers => this._httpResponse?.headers;
	
	/**
	 * Detach the underlying socket from the HTTP client. When the
	 * socket is detached the HTTP client will no longer perform any
	 * operations on it.
	 *
	 * This is normally used when a HTTP upgrade is negotiated and the
	 * communication should continue with a different protocol.
	 */
	Future<Socket> detachSocket() => this._httpResponse?.detachSocket();
	
	/**
	 * Cookies set by the server (from the 'set-cookie' header).
	 */
	List<Cookie> get cookies => this._httpResponse?.cookies;
	
	/**
	 * Returns the certificate of the HTTPS server providing the response.
	 * Returns null if the connection is not a secure TLS or SSL connection.
	 */
	X509Certificate get certificate => this._httpResponse?.certificate;
	
	/**
	 * Gets information about the client connection. Returns [:null:] if the socket
	 * is not available.
	 */
	HttpConnectionInfo get connectionInfo => this._httpResponse?.connectionInfo;
}