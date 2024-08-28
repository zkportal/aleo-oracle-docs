# Errors

## List of Error Codes

A list of all errors that may occur during the notarization process, with explanations and tips for fixing them.

### Validation Errors

#### 100
```validation error: failed to decode a request, invalid request structure```

Request structure might be invalid or damaged. Please verify parameters that you provide to `AttestationRequest`.

#### 101
```validation error: url is required```

Field `url` is missing in `AttestationRequest`.

#### 102
```"validation error: url should not include a scheme. Please remove https:// or http:// from your url"```

`url` should not include a scheme. Notarization Backend will prefix `url` with `https://` scheme.

```js
// valid url
"google.com"
"www.google.com"

// invalid url
"https://google.com"
"http://example.com"
```

#### 110
```validation error: requestMethod is required```

Field `requestMethod` is missing in `AttestationRequest`. Should be `GET` or `POST`.

#### 111
```validation error: requestMethod expected to be GET/POST```

Oracle SDK only supports `GET` and `POST` methods to request data from the attestation target.

#### 112
```validation error: responseFormat is required```

Field `responseFormat` is missing in `AttestationRequest`. It represents in which format the attestation target is expected to respond. Can be `json` or `html`.

#### 113
```validation error: responseFormat expected to be json/html```

The only attestation targets that are supported are those that can respond with `json` or `html` response format.

#### 114
```validation error: htmlResultType is required with html responseFormat```

When `responseFormat` is `html` then you should specify which type of a result you want to extract. It can be `element` or `value`.

Given extracted value below:
`<a href="/test">Nice link</a>`
- using `responseFormat: "element"` will return the whole tag - `<a href="/test">Nice link</a>`;
- using `responseFormat: "value"` will return `Nice link`. This is an equivalent of using `{@link HTMLElement#innerText}`.

#### 115
```validation error: htmlResultType expected to be element/value```

Field `htmlResultType` has an invalid value. Look for an error `106` above for an explanation on how each type works.

#### 116
```validation error: selector is not a valid xpath expression```

Notarization Backend was unable to parse `selector` as a valid xpath expression. Make sure you are using correct xpath syntax.

#### 120
```validation error: requestBody is required with POST requestMethod```

When `requestMethod` is `POST` you are required to provide the `requestBody` field.

#### 121
```validation error: contentType is required with POST requestMethod```

When `requestMethod` is `POST` you are required to provide the `contentType` field.

#### 130
```validation error: max field length is 4kb```

One of the fields in `AttestationRequest` is bigger than 4 kilobytes. Please check the sizes of the provided fields.

#### 140
```validation error: invalid encoding option```

Field `encodingOptions.value` in `AttestationRequest` can only be `string` \| `int` \| `float`.

#### 141
```validation error: encoding option precision for floating point number is too big```

Max value for field `encodingOptions.precision` in `AttestationRequest` is 12. Please provide a smaller number.

#### 142
```validation error: encodingOptions.value is required```

Field `encodingOptions.value` is missing in `AttestationRequest`. Please provide one of the options: `string` \| `int` \| `float`.

#### 143
```validation error: encodingOptions.precision is required when value is float```

Field `encodingOptions.precision` is required when `encodingOptions.value` is `float`. Please provide precision of the number in the Attestation Data.

### Request and its Parsing Errors

#### 201
```request error: failed to create request```

Notarization Backend was unable to create a request to the attestation target with the provided parameters. Please verify that the `AttestationRequest` object is valid.

#### 202
```request error: failed to execute request```

Notarization Backend was unable to execute a request created from `AttestationRequest`. Please verify that `url` is a valid URL. Keep in mind that you don't need to provide a scheme, HTTPS is assumed.
```js
// valid url
"google.com"
"www.google.com"

// invalid url
"https://google.com"
"http://example.com"
```

#### 203
```request error: error reading response body```

Notarization Backend was unable to read a body from the attestation target response. Make sure that the `AttestationRequest` that you provided is valid.

#### 210
```response parsing error: invalid html in response```

Attestation target responded with non-html content but `html` response format is expected or HTML in the response might be invalid. Make sure you provided a correct `responseFormat`. Also check that `url` is correct and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

#### 211
```response parsing error: failed to query XPath```

Notarization Backend was unable to extract any data with the provided `selector`. Make sure that `selector` is a valid XPath.

#### 212
```response parsing error: element with this XPath not found```

Notarization Backend was unable to find an element with the provided `selector` in the attestation target response. This might be due to an error in the `selector`, or the notarization backend was unable to reproduce a request and is missing some required data in the attestation target response. Make sure that `selector` and `url` are correct, and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

If you are having trouble fixing this error and extracting the correct value, you might want to try using `testSelector()` to see if the notarization backend is getting the expected response.

#### 213
```response parsing error: error parsing extracted result as an html element```

Extracted data is not a valid HTML element. This might be due to an error in the `selector`, or the notarization backend is trying to extract data from an incorrect response. Make sure that `selector` and `url` are correct, and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

If you are having trouble fixing this error and extracting the correct value, you might want to try using `testSelector()` to see if the notarization backend is getting the expected response.

#### 214
```response parsing error: element with provided XPath do not have innerText```

Notarization backend found an empty value using the provided `selector`. This might be due to an error in the `selector`, or the notarization backend is trying to extract data from an incorrect response. Make sure that `selector` and `url` are correct, and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

If you are having trouble fixing this error and extracting the correct value, you might want to try using `testSelector()` to see if the notarization backend is getting the expected response.

#### 221
```response parsing error: invalid JSON in response```

Attestation target responded with non-JSON content but `json` response format is expected or JSON in the response might be invalid. Make sure you provided a correct `responseFormat`. Also check that `url` is correct and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

#### 222
```response parsing error: failed to query JSONPath or key not found```

Notarization Backend was unable to extract data using the provided `selector`. This might be due to an invalid `selector` or the notarization backend getting an incorrect response from the attestation target. Make sure that `selector` is correct and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

Keep in mind that each key in a `selector` should be separated with a `"."` dot, even the index selector of an array element.

Example
```js
const json = {
  "primitive": "value",
  "list": [123, 223, 3],
  "dictionary": {
    "key1": "value1",
    "key2": "value2"
  }
}
```
- selector `primitive` will select `value`;
- selector `dictionary.key2` will select `value2`;
- selector `list.[1]` will select `223`.

Notice that it is `list.[1]` not `list[1]`.

If you are having trouble fixing this error and extracting the correct value, you might want to try using `testSelector()` to see if the notarization backend is getting the expected response.

#### 223
```response parsing error: found an empty JSON```

Notarizing backend found an empty JSON using the provided `selector`. This might be due to an invalid `selector` or the notarization backend getting an incorrect response from the attestation target. Make sure that `selector` is correct and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

If you are having trouble fixing this error and extracting the correct value, you might try to use `testSelector()` to see that the backend is getting the correct response.

#### 224
```response parsing error: found invalid JSON value```

Extracted data is not a valid `json` value or object. This might be due to invalid `selector` or the notarization backend getting an incorrect response from the attestation target. Make sure that `selector` is correct and that all required `requestHeaders` and parameters are present to reproduce your request correctly.

If you are having trouble fixing this error and extracting the correct value, you might try to use `testSelector()` to see that the backend is getting the correct response.

#### 250
```error: extracted data is too big for attestation. Max allowed is 4kb```

Attestation target responded with a body bigger than `4kb`. Try to make the response smaller by, for example, providing parameters or filters to the request so that you have less unnecessary data in the response.

### Attestation Errors

Errors with 3XX codes mean that something went wrong during the attestation process. These are internal errors related to the Trusted Execution Environment.

You should never encounter any of these errors if the Notarization Backend is set up correctly, but please contact developers if you encounter one of those.

```
301 - nitro attestation error: failed to open Nitro Security Module session
302 - nitro attestation error: failed to read random bytes for nonce
303 - nitro attestation error: failed to send Nitro Security Module request to device
304 - nitro attestation error: Nitro Security Module device responded with an error
305 - nitro attestation error: Nitro Security Module device did not return an attestation

350 - sgx error: failed to get a remote report
```

#### 380
```local report error: failed to decode example report```

If you are trying a local notarization backend for testing and you provided your custom example report - verify that report is correct. A report should be Base64-encoded.

#### 390
```"attestation error: attestation target is not whitelisted```

The Notarization Target is not on a domain that is allowed to be notarized by the backend. Please contact the developers to request new domains.

#### 391
```attestation error: attestation limit reached for requested target```

A limit of outgoing requests per second to the specified Notarization Target has been reached. Try again later.

### Attested random number errors

#### 400
```"missing "max" search parameter"```

The request to create an attested random number has failed due to missing the `max` URL search parameter. Make sure the URL looks like
`https://sgx.aleooracle.xyz/random?max=123`.

#### 401
```expected "max" search parameter to be a number 2-340282366920938463463374607431768211456```

The request to create an attested random number has failed due to an invalid value of the `max` URL search parameter. The `max` parameter should be a number
between 2 and 340282366920938463463374607431768211456. The upper limit is defined as 2^128^, which is the maximum possible value of Leo language's `u128` type + 1.

####

### Encoding Errors

#### 1001
```extracted value expected to be int but failed to parse as int```

Notarization Backend tried to parse the Attestation Data as an `int` but failed. Make sure that the extracted value is an unsigned decimal integer up to 64 bits in size.

#### 1002
```decimalless scientific notation is not supported for floats```

Notarization backend tried to parse the Attestation Data in scientific notation format (e.g. 123456p-78) as a `float` but failed. Try using `string` format or provide a differently formatted value.

#### 1003
```scientific notation is not supported for floats```

Notarization backend tried to parse the Attestation Data in scientific notation format (e.g. 1.234456e+78 or 6.72×109) as a `float` but failed. Try using `string` format or provide a differently formatted value.

#### 1004
```extracted value expected to be float but failed to parse as float```

Notarization Backend tried to parse the Attestation Data as a `float` but failed. Make sure that the extracted value is an unsigned floating point number up to 64 bits in size.

#### 1005
```cannot parse float without losing information```

The floating point number in the Extracted Data is too big for Notarization Backend to be able to encode it to Aleo format without losing digits. Please try to provide a smaller floating point number, not bigger than 64 bits in size.

The oracle needs to be able to encode the data string and decode it back to the exact string. When encoding options specify the value as `float`, this process includes parsing a float from a string, which may involve rounding to the nearest floating-point number. It may cause the encoder to not be able to format it back to the original string, which means that we lose some of the information about the original floating point number.

Implementation of encoding/decoding of floats may change in the future to solve this problem.

#### 1006
```extracted value is more precise than given precision```

Extracted data have more digits in the fractional part than the provided precision. Precision should always be bigger or equal to the number of digits in the fractional part.

#### 1009
```negative numbers are not supported for floats```

Notarization Backend can only encode positive numbers. Please make sure that the Extracted Data contains a positive number.

### Internal Errors

Errors with codes `1` to `4`, `331`, `332`, `333`, `1000`, `1007`, and `1008` mean that there was an internal error related to marshalling or encoding information at some point in the attestation process. These errors should never occur, but in case they did - please contact developers.
