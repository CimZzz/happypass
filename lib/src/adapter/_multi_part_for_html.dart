import 'dart:html';
import 'package:happypass/happypass.dart';

import 'multi_part.dart' as _multipart;

class MultipartDataBody implements _multipart.MultipartDataBody {
	
	@override
	String get contentType => null;
	
	@override
	bool get overrideContentType => false;
	
	/// Multipart 数据列表
	List<_multipart.MultiData> _multiDataList;
	
	/// 直接添加 Multipart 数据
	MultipartDataBody addMultiPartData(_multipart.MultiData data) {
		if (data == null) {
			return this;
		}
		
		_multiDataList ??= [];
		_multiDataList.add(data);
		return this;
	}
	
	
	@override
	_multipart.MultipartDataBody addMultipartFile(String name, File file, {String fileName, String contentType}) {
		return addMultiPartData(_multipart.MultiData(
			name: name,
			data: file,
			fileName: fileName ?? file.name,
			contentType: contentType ?? file.type,
		));
	}
	
	@override
	_multipart.MultipartDataBody addMultipartText(String name, String text, {String fileName, String contentType}) {
		return addMultiPartData(
			_multipart.MultiData(name: name, data: text, fileName: fileName, contentType: _multipart.getDefaultContentType(fileName)));
	}
	
	@override
	_multipart.MultipartDataBody addMultipartStream(String name, Stream<List<int>> stream, {String fileName, String contentType}) {
		return addMultiPartData(_multipart.MultiData(
			name: name,
			data: stream,
			fileName: fileName,
			contentType: contentType ?? _multipart.getDefaultContentType(fileName),
		));
	}
	
	@override
	Stream<dynamic> provideBodyData() async* {
		final multiDataList = _multiDataList;
		if (multiDataList == null) {
			yield null;
		}
		
		final formData = FormData();
		for (var data in multiDataList) {
			final srcData = data.data;
			if (srcData is Blob) {
				formData.appendBlob(data.name, srcData, data.fileName);
			}
			else if (srcData is Stream<List<int>>) {
				final streamData = await srcData.reduce((previous, element) {
					previous.addAll(element);
					return previous;
				});
				formData.appendBlob(data.name, Blob(streamData, data.contentType), data.fileName);
			}
			else if (srcData is String) {
				formData.append(data.name, srcData);
			}
		}
		yield RawBodyData(rawData: formData);
	}
}