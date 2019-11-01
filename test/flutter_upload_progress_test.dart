import 'package:flutter_upload_progress/flutter_upload_progress.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

/// WIP
void main() {
  test('handles a upload', () async {
    var client = MockClient.streaming((request, bodyStream) async {
      var bodyString = await bodyStream.bytesToString();
      var stream =
          Stream.fromIterable(['Request body was "$bodyString"'.codeUnits]);
      return http.StreamedResponse(stream, 200);
    });

    var progressService = ProgressService(client: client);
    var response = await progressService.upload(
      method: 'post',
      url: 'https://example.com/upload',
    );

    expect(response.body, equals('Request body was "hello, world"'));
  });

  test('handles a upload with multipart', () async {
    var client = MockClient.streaming((request, bodyStream) async {
      var bodyString = await bodyStream.bytesToString();
      var stream =
          Stream.fromIterable(['Request body was "$bodyString"'.codeUnits]);
      return http.StreamedResponse(stream, 200);
    });

    var progressService = ProgressService(client: client);
    var response = await progressService.uploadMultipart(
        method: 'put', url: 'https://example.com/upload');

    expect(response.body, equals('Request body was "hello, world"'));
  });

  test('handles a upload', () async {
    var client = MockClient.streaming((request, bodyStream) async {
      var bodyString = await bodyStream.bytesToString();
      var stream =
          Stream.fromIterable(['Request body was "$bodyString"'.codeUnits]);
      return http.StreamedResponse(stream, 200);
    });

    var progressService = ProgressService(client: client);
    var filepath =
        await progressService.download(url: 'https://example.com/upload');

    expect(filepath, equals('Request body was "hello, world"'));
  });
}
