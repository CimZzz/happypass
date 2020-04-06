import 'dart:io'
if (dart.library.html) 'dart:html' as _platform;
import 'multi_part.dart' as _multipart;

/// Multipart 子数据
class _MultiData {
	_MultiData({this.name, this.data, this.fileName, this.contentType});
	
	final String name;
	final Object data;
	final String fileName;
	final String contentType;
}

class MultipartDataBody implements _multipart.MultipartDataBody {
	
	/// Multipart 数据列表
	List<_MultiData> _multiDataList;
	
	/// 直接添加 Multipart 数据
	MultipartDataBody addMultiPartData(_MultiData data) {
		if (data == null) {
			return this;
		}
		
		_multiDataList ??= [];
		_multiDataList.add(data);
		return this;
	}
	
	
	@override
  _multipart.MultipartDataBody addMultipartFile(String name, _platform.File file, {String fileName, String contentType}) {
    // TODO: implement addMultipartFile
    throw UnimplementedError();
  }

  @override
  _multipart.MultipartDataBody addMultipartStream(String name, Stream<List<int>> stream, {String fileName, String contentType}) {
    // TODO: implement addMultipartStream
    throw UnimplementedError();
  }

  @override
  _multipart.MultipartDataBody addMultipartText(String name, String text, {String fileName, String contentType}) {
    // TODO: implement addMultipartText
    throw UnimplementedError();
  }

  @override
  // TODO: implement contentType
  String get contentType => throw UnimplementedError();

  @override
  // TODO: implement overrideContentType
  bool get overrideContentType => throw UnimplementedError();

  @override
  Stream provideBodyData() {
    // TODO: implement provideBodyData
    throw UnimplementedError();
  }

}