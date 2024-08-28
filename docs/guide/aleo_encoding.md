# Encoding data for an Aleo program

In order to have trust in attestation data the oracle contract needs to verify the attestation response and attestation report.

To do that, the response and report must be inputs to the contract in some format that makes it possible to read and make asserts on
them. For example, an oracle should verify the report's signature, TEE unique ID, make assertions on the attestation URL, status code, etc.

To achieve that, the response and report must be serialized and encoded in a specific way.

Encoding of the [Attestation Response](../sdk/js_api.md#type-attestationresponse) + attestation results (Report Data) happens on the backend.

## Encoding header

The encoded Report Data contains a header in the first 2 `u128` that contains meta information about the encoded properties.
It helps decoding and deserializing the Report Data in Aleo back to the human-readable form.

**Number of `u128`**: 2.

## Encoding Report Data

Here's the description of the encoding of a response. Every item in the list is written to a single buffer,
every item is padded at the end with zeroes to align to 16, every item takes at least 16 bytes.

Here are the steps that are done for serialization and encoding Report Data:

1. [Encode Attestation Data](#1-encode-attestation-data)
2. [Encode Attestation Timestamp](#2-encode-attestation-timestamp)
3. [Encode HTTP response status code](#3-encode-http-response-status-code)
4. [Encode Attestation Target URL as bytes of the string](#4-encode-attestation-target-url-as-bytes-of-the-string)
5. [Encode selector as bytes of the string](#5-encode-selector-as-bytes-of-the-string)
6. [Encode response format](#6-encode-response-format)
7. [Encode request method as bytes of the string](#7-encode-request-method-as-bytes-of-the-string)
8. [Encode encoding options object](#8-encode-encoding-options-object)
9. [Encode request headers](#9-encode-request-headers)
10. [Encode HTML result type, request content type and request body](#10-encode-optional-properties). These 3 fields are optional in the request, and they are encoded even if they are empty.

### 1. Encode Attestation Data

Encoding the Attestation Data is described in the [Guide to understanding the Attestation Response](./understanding_response.md#about-encoding-data-for-aleo).

**Number of `u128`**: variable, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).data</code>.

### 2. Encode Attestation Timestamp

Encoding the Attestation Timestamp is done the same as [encoding integer Attestation Data](./understanding_response.md#attestation-data-as-an-integer) - the number is converted to little
endian bytes, padded to 16 bytes, then encoded as Aleo's `u128`.

### 3. Encode HTTP response status code

The Attestation HTTP response status code is encoded the same way as [the Timestamp](#step-2).

**Number of `u128`**: 1.

### 4. Encode Attestation Target URL as bytes of the string

The Attestation Target URL is serialized and encoded the same way as [encoding string Attestation Data](./understanding_response.md#attestation-data-as-a-string).

**Number of `u128`**: variable, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).url</code>.

### 5. Encode selector as bytes of the string

The notarization selector is serialized and encoded the same way as [encoding string Attestation Data](./understanding_response.md#attestation-data-as-a-string).

**Number of `u128`**: variable, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).selector</code>.

### 6. Encode response format

The response format encoded as 1 byte with the values:

- `0` for JSON
- `1` for HTML

The value is set in the first little endian byte.

**Number of `u128`**: 1.

### 7. Encode request method as bytes of the string

The notarization request method is serialized and encoded the same way as [encoding string Attestation Data](./understanding_response.md#attestation-data-as-a-string).

**Number of `u128`**: variable, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).method</code>.

### 8. Encode encoding options object

The encoding options themselves are encoded in 2 bytes.

The first little endian byte indicates the encoding options value:

- `0` for `string`
- `1` for `int`
- `2` for `float`

If the encoding options value is `float`, the ninth little endian byte will contain the encoding precision.

!!! example

    | Description | `u128` bytes |
    | --- | --- |
    | Encoding string encoding options | <code><mark>0</mark> 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0</code> |
    | Encoding integer encoding options | <code><mark>1</mark> 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0</code> |
    | Encoding float encoding options with precision 5 | <code><mark>2</mark> 0 0 0 0 0 0 0 <mark>5</mark> 0 0 0 0 0 0 0</code> |

**Number of `u128`**: 1.

### 9. Encode request headers

Encoding Attestation Request headers starts with sorting headers alphabetically, then the headers are encoded using
the following format:

1. The first `u128` consists of the number of header key-value pairs in the first 8 little endian bytes, followed by
8 bytes of the **number of `u128**` that the encoded headers take (minus this one).
2. The following `u128` are constructed for every header key-value pair using the following format:
    1. 2 bytes of length of "key:value" string as bytes
    2. "key:value" string as bytes
    3. Padding to 16

**Number of `u128`**: variable, at least 1, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).requestHeaders</code>.

### 10. Encode optional properties

Fields that are optional in the Attestation Request are encoded all together, even when empty.

The first `u128` is a header - the first little endian byte is a bitmask, which encodes existence of HTML result type (1st bit),
request content type (2nd bit), request body (3rd bit). The last 8 little-endian bytes are a little-endian byte representation of
the number of `u128`s following the header, that contain all the optional parameters. There will always be at least 3 `u128`s after the header - zero-byte `u128`s encoding the lengths of the (non-existent) components.

The header is followed by the following content:

1. 1 `u128` encoding HTML result type. The first little endian byte encodes the value - `1` for `element`, `2` for `value`.
If there's no HTML result type, then the whole `u128` is 0.

2. At least 1 `u128` encoding the Attestation Request's content type.
The first 8 little endian bytes encode the number of the following `u128`s encoding the actual content type as character
codes. If there is no content type, there is 1 `u128` of 0, followed by 0 `u128`s of content.

3. At least 1 `u128` encoding the Attestation Request's body. The first 8 little endian bytes encode the number of the following `u128`s encoding the actual request body as character codes.
If there is no request body, there's 1 `u128` of 0, followed by 0 `u128`s of content.

**Number of `u128`**: variable, at least 4, check <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo).optionalFields</code>.

