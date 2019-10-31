library flutter_upload_progress;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart' as fileUtil;
import 'package:path_provider/path_provider.dart';

typedef void OnProgressCallback(int processedBytes, int totalBytes);

class ProgressService {
  final Client _client;

  ProgressService({Client client}) : _client = client;

  Future<Response> upload(
      {String method,
      String url,
      File file,
      Map<String, String> headers,
      OnProgressCallback onProgress}) async {
    assert(method != null);
    assert(url != null);
    assert(file != null);

    int totalByteLength = await file.length();
    int byteCount = 0;

    Stream<List<int>> streamUpload = file.openRead().transform(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              byteCount += data.length;

              if (onProgress != null) {
                onProgress(byteCount, totalByteLength);
              }

              sink.add(data);
            },
            handleError: (error, stack, sink) {
              print(error.toString());
            },
            handleDone: (sink) {
              sink.close();
            },
          ),
        );

    final request = _CustomStreamRequest(method, Uri.parse(url), streamUpload);

    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    request.headers.addAll({
      HttpHeaders.contentTypeHeader: ContentType.binary.toString(),
      'filename': fileUtil.basename(file.path)
    });

    request.contentLength = totalByteLength;

    return Response.fromStream(
        await (_client == null ? request.send() : _client.send(request)));
  }

  Future<Response> uploadMultipart(
      {String method,
      String url,
      File file,
      Map<String, String> headers,
      OnProgressCallback onProgress}) async {
    assert(method != null);
    assert(url != null);
    assert(file != null);

    int byteCount = 0;

    var multipart =
        await MultipartFile.fromPath(fileUtil.basename(file.path), file.path);

    var requestMultipart = MultipartRequest('', Uri());

    requestMultipart.files.add(multipart);

    var msStream = requestMultipart.finalize();

    var totalByteLength = requestMultipart.contentLength;

    ByteStream streamUpload = ByteStream(msStream.transform<List<int>>(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          sink.add(data);

          byteCount += data.length;

          if (onProgress != null) {
            onProgress(byteCount, totalByteLength);
          }
        },
        handleError: (error, stack, sink) {
          throw error;
        },
        handleDone: (sink) {
          sink.close();
        },
      ),
    ));

    final request = _CustomStreamRequest(method, Uri.parse(url), streamUpload);

    request.contentLength = totalByteLength;

    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    request.headers.addAll({
      HttpHeaders.contentTypeHeader:
          requestMultipart.headers[HttpHeaders.contentTypeHeader]
    });

    return Response.fromStream(
        await (_client == null ? request.send() : _client.send(request)));
  }

  Future<File> download(
      {String url,
      String filename,
      Map<String, String> headers,
      OnProgressCallback onProgress}) async {
    final request = StreamedRequest('get', Uri.parse(url));

    if (headers != null && headers.isNotEmpty) {
      request.headers.addAll(headers);
    }

    request.headers
        .addAll({HttpHeaders.contentTypeHeader: 'application/octet-stream'});

    var response =  await (_client == null ? request.send() : _client.send(request));

    int byteCount = 0;
    int totalBytes = response.contentLength;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    appDocPath = "/storage/emulated/0/Download";

    File file = new File(appDocPath + "/" + filename);

    var raf = file.openSync(mode: FileMode.write);

    Completer completer = new Completer<String>();

    response.stream.listen(
      (data) {
        byteCount += data.length;

        raf.writeFromSync(data);

        if (onProgress != null) {
          onProgress(byteCount, totalBytes);
        }
      },
      onDone: () {
        raf.closeSync();
        completer.complete(file);
      },
      onError: (e) {
        raf.closeSync();
        file.deleteSync();
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    return completer.future;
  }
}

class _CustomStreamRequest extends BaseRequest {
  final ByteStream stream;

  _CustomStreamRequest(String method, Uri url, this.stream)
      : super(method, url);

  ByteStream finalize() {
    super.finalize();
    return stream;
  }
}
