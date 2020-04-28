/// Http 代理对象
/// 用来指定 Http 代理
class PassHttpProxy {
	const PassHttpProxy(this.host, this.port) : assert(host != null && port != null);
	
	final String host;
	final int port;
	
	@override
	bool operator ==(other) {
		return other is PassHttpProxy && other.host == host && other.port == port;
	}
	
	@override
	String toString() {
		return 'PROXY $host:$port';
	}
}
