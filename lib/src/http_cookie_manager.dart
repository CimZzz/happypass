part of 'http.dart';

/// Cookie 管理器
/// 用来读取与存储请求中的 Cookie 信息
abstract class CookieManager {
	/// 根据 HttpUrl 取得 Cookie List
	List<Cookie> getCookies(HttpUrl url);
	
	/// 储存对应 HttpUrl 下的 Cookie List
	void storeCookies(HttpUrl url, List<Cookie> cookieList);
}

/// 内存缓存 Cookie 管理器
/// 将对应的 Cookie 保存在内存中
/// 需要注意的是，本 Cookie 管理器中缓存的 Cookie 全局共享
class MemoryCacheCookieManager extends CookieManager {
	static Map<String, Map<String, Cookie>> memoryCookieMap = Map();
	
	@override
	List<Cookie> getCookies(HttpUrl httpUrl) {
		return memoryCookieMap[httpUrl.host]?.values?.toList();
	}
	
	@override
	void storeCookies(HttpUrl httpUrl, List<Cookie> cookieList) {
		final oldCookieMap = memoryCookieMap[httpUrl.host];
		if(oldCookieMap != null) {
			cookieList.forEach((cookie) {
				oldCookieMap[cookie.name] = cookie;
			});
		}
		else {
			Map<String, Cookie> cookieMap = Map();
			cookieList.forEach((cookie) {
				cookieMap[cookie.name] = cookie;
			});
			
			memoryCookieMap[httpUrl.host] = cookieMap;
		}
	}
}