# List of the headers

Values of headers that are **NOT** present in this list will be replaced by the Notarization Backend with `*****` after the request was made to hide potentially sensitive information, like credentials or authentication tokens.

!!! example

    Input:
    ```js
    requestHeaders: {
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15",
      "Custom-Header-With-Sensitive-Info": "Private Value"
    }
    ```

    What will be in the report:
    ```js
    requestHeaders: {
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Safari/605.1.15",
      "Custom-Header-With-Sensitive-Info": "*****"
    }
    ```

List of headers which are **not** going to be replaced:

- `Accept`
- `Accept-Charset`
- `Accept-Datetime`
- `Accept-Encoding`
- `Accept-Language`
- `Access-Control-Request-Method`
- `Access-Control-Request-Header`
- `Cache-Control`
- `Connection`
- `Content-Encoding`
- `Content-Length`
- `Content-MD5`
- `Content-Type`
- `Date`
- `Expect`
- `Forwarded`
- `Host`
- `HTTP2-Settings`
- `If-Match`
- `If-Modified-Since`
- `If-None-Match`
- `If-Range`
- `If-Unmodified-Since`
- `Max-Forwards`
- `Origin`
- `Pragma`
- `Prefer`
- `Range`
- `Referer`
- `TE`
- `Trailer`
- `Transfer-Encoding`
- `User-Agent`
- `Upgrade`
- `Via`
- `Warning`
- `Upgrade-Insecure-Requests`
- `X-Requested-With`
- `DNT`
- `X-Forwarded-For`
- `X-Forwarded-Host`
- `X-Forwarded-Proto`
- `Front-End-Https`
- `X-Http-Method-Override`
- `X-ATT-DeviceId`
- `X-Wap-Profile`
- `Proxy-Connection`
- `Save-Data`
- `Sec-GPC`
