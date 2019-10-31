# flutter_upload_progress

File upload and download with progress callback.

## Using

```
 var progressService = ProgressService();
    var response = await progressService.uploadMultipart(
        method: 'post',
        url: 'https://example.com/upload',
        file: {File},
        onProgress: (sentBytes, totalBytes){
            print('$sentBytes/$totalBytes');
        });
```
