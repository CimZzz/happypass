/// Happy pass 错误对象
class HappyPassError {
	const HappyPassError(this.msg);
	
	final String msg;
	
	@override
	String toString() => msg;
}