# CP-VER-004: Unsupported Tus-Resumable on POST is not processed

POST {{base_url}}
Tus-Resumable: 99.99.99
Upload-Length: 100

HTTP 412
[Asserts]
header "Tus-Version" exists
header "Location" not exists
