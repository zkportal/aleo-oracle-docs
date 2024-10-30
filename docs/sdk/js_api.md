# JS API

The Aleo Oracle SDK for JavaScript is a Node.js package.

[JS SDK :fontawesome-brands-github:]({{ variables.links.js_sdk_repo }})

This SDK doesn't use default exports.

Internally, this API uses [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API). It may be possible to use it in any JS environment,
given that you provide an implementation for the Fetch API.

Since the client allows configuring custom Notarization and Verification backends, it also allows providing
an override for Fetch options that are used for communicating with those backends - see [`OracleClient` constructor](#constructor).

## Index

- [Installation](#installation)
- [Constants](#constants):
    - [`DEFAULT_FETCH_OPTIONS`](#default_fetch_options)
    - [`DEFAULT_NOTARIZATION_BACKENDS`](#default_notarization_backends)
    - [`DEFAULT_NOTARIZATION_HEADERS`](#default_notarization_headers)
    - [`DEFAULT_NOTARIZATION_OPTIONS`](#default_notarization_options)
    - [`DEFAULT_VERIFICATION_BACKEND`](#default_verification_backend)
- [Types](#types):
    - [class `AttestationError`](#class-attestationerror)
    - [class `AttestationIntegrityError`](#class-attestationintegrityerror)
    - [class `DebugAttestationError`](#class-debugattestationerror)
    - [class `OracleClient`](#class-oracleclient):
        - [*constructor*](#constructor)
        - [`notarize`](#notarize)
        - [`testSelector`](#testselector)
        - [`enclavesInfo`](#enclavesinfo)
        - [`getAttestedRandom`](#getattestedrandom)
    - [type `AttestationRequest`](#type-attestationrequest)
    - [type `AttestationResponse`](#type-attestationresponse)
    - [type `ClientConfig`](#type-clientconfig)
    - [type `CustomBackendAllowedFetchOptions`](#type-custombackendallowedfetchoptions)
    - [type `CustomBackendConfig`](#type-custombackendconfig)
    - [type `DebugRequestResponse`](#type-debugrequestresponse)
    - [type `EnclaveInfo`](#type-enclaveinfo)
    - [type `EncodingOptions`](#type-encodingoptions)
    - [type `InfoOptions`](#type-infooptions)
    - [type `NitroDocument`](#type-nitrodocument)
    - [type `NitroInfo`](#type-nitroinfo)
    - [type `NitroReportExtras`](#type-nitroreportextras)
    - [type `NotarizationOptions`](#type-notarizationoptions)
    - [type `OracleData`](#type-oracledata)
    - [type `PositionInfo`](#type-positioninfo)
    - [type `ProofPositionalInfo`](#type-proofpositionalinfo)
    - [type `SgxInfo`](#type-sgxinfo)

## Installation

Install the SDK by running `npm install @zkportal/aleo-oracle-sdk`.

## Constants

### `DEFAULT_FETCH_OPTIONS`

Default Fetch API options that are applied to all requests towards the Notarization and Verification backends.

```js
{
  cache: 'no-store',
  mode: 'cors',
  redirect: 'follow',
  referrer: '',
  keepalive: false,
}
```

### `DEFAULT_NOTARIZATION_BACKENDS`

List of notarization backend configurations that is going to be used if no `notarizer` configuration is provided to the client.

Type: [`CustomBackendConfig[]`](#type-custombackendconfig).

```js
[
  {
    address: 'sgx.aleooracle.xyz',
    port: 443,
    https: true,
    apiPrefix: '',
    resolve: true,
    init: DEFAULT_FETCH_OPTIONS,
  },
]
```

### `DEFAULT_NOTARIZATION_HEADERS`

Default HTTP request headers that are added to all requests towards the Attestation Target.

```js
{
  'Accept': '*/*',
  'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36',
  'Upgrade-Insecure-Requests': '1',
  'DNT': '1',
}
```

### `DEFAULT_NOTARIZATION_OPTIONS`

Type: [`NotarizationOptions`](#type-notarizationoptions)

```js
{
  dataShouldMatch: true,
  timeout: 5000,
  maxTimeDeviation: undefined,
}
```

### `DEFAULT_VERIFICATION_BACKEND`

List of notarization backend configurations that is going to be used if no `verifier` configuration is provided to the client.

Type: [`CustomBackendConfig`](#type-custombackendconfig).

```js
{
  address: 'verifier.aleooracle.xyz',
  port: 443,
  https: true,
  apiPrefix: '',
  resolve: true,
  init: DEFAULT_FETCH_OPTIONS,
}
```

## Types

### class `AttestationError`

Extends: `Error`

| Property | Type | Description |
| --- | --- | --- |
| `errorDetails` | `string | undefined` | Extra error details |
| `responseStatusCode` | `number | undefined` | Attestation target's response status code, which will be present if the error has occurred during or after performing a request to the target |

### class `AttestationIntegrityError`

Extends: `Error`

### class `DebugAttestationError`

Extends: `Error`

| Property | Type | Description |
| --- | --- | --- |
| `errorDetails` | `string | undefined` | Extra error details |
| `responseStatusCode` | `number | undefined` | Attestation target's response status code, which will be present if the error has occurred during or after performing a request to the target |
| `responseBody` | `string` | Full response body received in the attestation target's response. |
| `extractedData` | `string` | Extracted data from `responseBody` using the provided selector. |

### class `OracleClient`

#### *constructor*

| Argument | Description | Required | Default value |
| --- | --- | --- | --- |
| `config`: [`ClientConfig`](#type-clientconfig) | Client configuration for setting up Notarization and Verification backends, logging, etc. | :fontawesome-solid-x: | `undefined` |

#### `notarize`

| Argument | Description | Required | Default value |
| --- | --- | --- | --- |
| `req`: [`AttestationRequest`](#type-attestationrequest) | Attestation request | :fontawesome-solid-check: | |
| `options`: [`NotarizationOptions`](#type-notarizationoptions) | Options for client-side notarization behavior | :fontawesome-solid-x: | [`DEFAULT_NOTARIZATION_OPTIONS`](#default_notarization_options) |

| Return type | Description |
| --- | --- |
| <code>Promise<[AttestationResponse](#type-attestationresponse)[]></code> | List of the attestation results. Returns all successfully produced and verified attestations and discards the invalid ones. |

| Thrown type | Reason |
| --- | --- |
| [`AttestationError`](#class-attestationerror) | All the Notarization Backends failed to perform notarization or attestation. |
| `Error` | Failed to parse one or more responses. |
| [Fetch API errors](https://developer.mozilla.org/en-US/docs/Web/API/fetch#exceptions) | Fetch failed. |

#### `testSelector`

| Argument | Description | Required | Default value |
| --- | --- | --- | --- |
| `req`: [`AttestationRequest`](#type-attestationrequest) | Attestation request | :fontawesome-solid-check: | |
| `timeout`: `number` | Request timeout | :fontawesome-solid-check: | [`DEFAULT_NOTARIZATION_OPTIONS`](#default_notarization_options) |

| Return type | Description |
| --- | --- |
| <code>Promise<[DebugRequestResponse](#type-debugrequestresponse)[]></code> | List of results of notarization and Attestation Data extraction. Returns all successfully produced notarizations.

| Thrown type | Reason |
| --- | --- |
| [`DebugAttestationError`](#class-debugattestationerror) | One of the Notarization Backends failed to perform a selector test. |
| `Error` | Failed to parse one or more responses. |
| [Fetch API errors](https://developer.mozilla.org/en-US/docs/Web/API/fetch#exceptions) | Fetch failed. |

#### `enclavesInfo`

| Argument | Description | Required | Default value |
| --- | --- | --- | --- |
| `options`: [`InfoOptions`](#type-infooptions) | Get enclaves information request options | :fontawesome-solid-x: | `undefined` |

| Return type | Description |
| --- | --- |
| <code>Promise<[EnclaveInfo](#type-enclaveinfo)[]></code> | List of results containing enclave information |

| Thrown type | Reason |
| --- | --- |
| [`AttestationError`](#class-attestationerror) | Failed to fetch enclave information from one or more Notarization Backends. |
| `Error` | Failed to parse one or more responses. |
| [Fetch API errors](https://developer.mozilla.org/en-US/docs/Web/API/fetch#exceptions) | Fetch failed. |

#### `getAttestedRandom`

| Argument | Description | Required | Default value |
| --- | --- | --- | --- |
| `max`: `bigint` | Upper bound for the random number, exclusive - `[0, max)` | :fontawesome-solid-check: | |
| `options`: [`NotarizationOptions`](#type-notarizationoptions) | Options for client-side notarization behavior | :fontawesome-solid-x: | [`DEFAULT_NOTARIZATION_OPTIONS`](#default_notarization_options) |

| Return type | Description |
| --- | --- |
| <code>Promise<[AttestationResponse](#type-attestationresponse)[]></code> | List of the attestation results. Returns all successfully produced and verified attestations and discards the invalid ones. |

| Thrown type | Reason |
| --- | --- |
| [`AttestationError`](#class-attestationerror) | One of the Notarization Backends failed to perform notarization or attestation. |
| `Error` | Failed to parse one or more responses. |
| [Fetch API errors](https://developer.mozilla.org/en-US/docs/Web/API/fetch#exceptions) | Fetch failed. |

### type `AttestationRequest`

A request for notarization and notarization of an HTTPS resource, and extraction of Attestation Data from the response using a data selector.
Also describes the expected response format, and the way to encode the extracted Attestation Data for an Aleo program.

| Property | Type | Description |
| --- | --- | --- |
| `url` | `string` | URL of a resource to attest - Attestation Target. Should be specified without a scheme - **assumes HTTPS**. |
| `requestMethod` | `'GET' | 'POST'` | HTTP method to be used for a request to the Attestation Target. |
| `selector` | `string | undefined` | Element selector for extracting data from the attestation resource - XPath for HTML, JSON key path for JSON. See the [Guide about selectors](../guide/index.md#step-3-select-the-data-from-the-response). |
| `responseFormat` | `'html' | 'json'` | Expected Attestation Target response format. |
| `htmlResultType` | `'element' | 'value'` | The type of extraction for the HTML response after applying the selector. See the [Guide about the HTML extraction result types](../guide/index.md#html-result-type). Ignored if `responseFormat` is not `html`. |
| `requestBody` | `string | undefined` | A body for a POST request to the Attestation Target. |
| `requestContentType` | `string | undefined` | Content-Type request header for the Attestation Target request. |
| `requestHeaders` | `{ [header: string]: string }` | HTTP headers to add to the request to the Attestation Target. See the [Guide about request headers](../guide/index.md#request-headers). Will merge [`DEFAULT_NOTARIZATION_HEADERS`](#default_notarization_headers) with this dictionary. |
| `encodingOptions` | [`EncodingOptions`](#type-encodingoptions) | Information about how to encode Attestation Data to an Aleo program-compatible format. See the [Guide about Aleo encoding](../guide/understanding_response.md#about-encoding-data-for-aleo) and [encoding documentation](../guide/aleo_encoding.md). |

### type `AttestationResponse`

Notarization backend's response for an attestation request.

| Property | Type | Description |
| --- | --- | --- |
| `enclaveUrl` | `string` | Url of the Notarization Backend the report came from. |
| `attestationReport` | `string` | Attestation Report in Base64 encoding, created by the TEE using the extracted data. |
| `attestationType` | `'sgx'` | Which TEE technology produces the attestation report within this response. |
| `attestationData` | `string` | Data extracted from the Attestation Target's response using the provided selector. The data is always a string, as seen in the raw HTTP response. See the [Guide about the Attestation Data](../guide/understanding_response.md). |
| `responseBody` | `string` | Full response body received in the Attestation Target's response. |
| `responseStatusCode` | `number` | Status code of the Attestation Target's response. |
| `nonce` | `string | undefined` | |
| `timestamp` | `number` | Unix timestamp of the attestation date time as seen by the server. |
| `oracleData` | [`OracleData`](#type-oracledata) | Information formatted for a direct use in an Aleo program, like Aleo-formated attestation report. |
| `attestationRequest` | [`AttestationRequest`](#type-attestationrequest) | Original attestation request. |

### type `ClientConfig`

Oracle client configuration object.

| Property | Type | Description |
| --- | --- | --- |
| `notarizer` | <code>[CustomBackendConfig](#type-custombackendconfig) \| undefined</code> | Can be set to use self-hosted Oracle Notarization service for testing. |
| `verifier` | <code>[CustomBackendConfig](#type-custombackendconfig) \| undefined</code> | Can be set to use a self-hosted Oracle Notarization Verification service. |
| `quiet` | `boolean | undefined` | Disables Oracle Client logging. |
| `logger` | `((...args: any[]) => void) | undefined` | Custom logging function to use if not `quiet`. Default value is `console.log`. |

### type `CustomBackendAllowedFetchOptions`

```js
Omit<RequestInit, 'body' | 'integrity' | 'method'>
```

### type `CustomBackendConfig`

Configuration for a backend that an Oracle client will be using for notarization/verification.

| Property | Type | Description |
| --- | --- | --- |
| `address` | `string` | Domain name or IP address of the backend |
| `port` | `number` | The port that the backend listens on for the API requests |
| `https` | `boolean` | Whether the client should use HTTPS to connect to the backend |
| `apiPrefix` | `string | undefined` | Optional API prefix to prepend to the API endpoints |
| `resolve` | `boolean` | Whether the client should resolve the backend (when it's a domain name). If the domain name is resolved to more than one IP, then the requests will be sent to all of the resolved servers, and the first response will be used. Must be used with the default backends. |
| `init` | <code>[CustomBackendAllowedFetchOptions](#type-custombackendallowedfetchoptions) \| undefined</code> | Custom Fetch API options for requests towards this backend. If not provided, will use [`DEFAULT_FETCH_OPTIONS`](#default_fetch_options). |

### type `DebugRequestResponse`

Notarization response for debugging selectors.

| Property | Type | Description |
| --- | --- | --- |
| `responseBody` | `string` | Full response body received in the Attestation Target's response. |
| `responseStatusCode` | `number` | Status code of the Attestation Target's response. |
| `extractedData` | `string` | Extracted data from `responseBody` using attestation request selector. |

### type `EnclaveInfo`

Information about the TEE the Notarization Backend is running in.

| Property | Type | Description |
| --- | --- | --- |
| `enclaveUrl` | `string` | URL of the Notarization Backend the report came from. |
| `reportType` | `string` | Which TEE technology produces the attestation report within this response. |
| `info` | <code>[SgxInfo](#type-sgxinfo) \| [NitroInfo](#type-nitroinfo)</code> | Information about the TEE. |
| `signerPubKey` | `string` | Public key of the report signing key that was generated in the enclave. |

### type `EncodingOptions`

Describes the way to interpret extracted Attestation Data for encoding to an Aleo program-compatible format.

See the [Guide about Aleo encoding](../guide/understanding_response.md#about-encoding-data-for-aleo).

| Property | Type | Description |
| --- | --- | --- |
| `value` | `'string' | 'int' | 'float'` | Attestation Data type to use to interpret the Attestation Data to encode it to the Aleo format. |
| `precision` | `number | undefined` | If the value is `'float'`, it sets the precision of the Attestation Data. Must be equal or more than the number of digits in the fractional part. |

### type `InfoOptions`

Request options for the enclave information request

| Property | Type | Description |
| --- | --- | --- |
| `timeout` | `number | undefined` | Request timeout in ms. If not set, the default timeout for the Fetch API implementation will be used. |

### type `NitroDocument`

| Property | Type | Description |
| --- | --- | --- |
| `moduleID` | `string` | Issuing Nitro hypervisor module ID. |
| `timestamp` | `number` | UTC time when document was created, in milliseconds since UNIX epoch. |
| `digest` | `string` | The digest function used for calculating the register values. |
| `pcrs` | `Record<string, string>` | Map of all locked PCRs at the moment the attestation document was generated. All PCR values are 48 bytes long. Will always have keys from "0" to "15". Base64. |
| `certificate` | `string` | The public key certificate for the public key that was used to sign the attestation document. Base64. |
| `cabundle` | `string[]` | Issuing CA bundle for infrastructure certificate. Base64. |
| `userData` | `string` | Additional signed user data. Always zero in a self report. Base64. |
| `nonce` | `string` | An optional cryptographic nonce provided by the attestation consumer as a proof of authenticity. Base64. |

### type `NitroInfo`

| Property | Type | Description |
| --- | --- | --- |
| `document` | [`NitroDocument`](#type-nitrodocument) | Nitro enclave attestation document. |
| `protectedCose` | `string` | Protected section from the COSE Sign1 payload of the Nitro enclave attestation result. Base64. |
| `signature` | `string` | Signature section from the COSE Sign1 payload of the Nitro enclave attestation document. Base64. |
| `aleo` | `{ pcrs: string, userData: string }` | PCRs 0-2 encoded for Aleo as one struct of 9 `u128` fields, 3 chunks per PCR value, and Self report user data (always zero) encoded for Aleo as a `u128` |

??? example "Example value of `aleo.pcrs` property"

    ```json
    "{ pcr_0_chunk_1: 286008366008963534325731694016530740873u128, pcr_0_chunk_2: 271752792258401609961977483182250439126u128, pcr_0_chunk_3: 298282571074904242111697892033804008655u128, pcr_1_chunk_1: 160074764010604965432569395010350367491u128, pcr_1_chunk_2: 139766717364114533801335576914874403398u128, pcr_1_chunk_3: 227000420934281803670652481542768973666u128, pcr_2_chunk_1: 280126174936401140955388060905840763153u128, pcr_2_chunk_2: 178895560230711037821910043922200523024u128, pcr_2_chunk_3: 219470830009272358382732583518915039407u128 }"
    ```

### type `NitroReportExtras`

Aleo-encoded structs with information that helps to extract user data and PCR values from the report.

| Property | Type | Description |
| --- | --- | --- |
| `pcr0Pos` | `string` | Aleo-encoded struct with information for extracting PCR 0. |
| `pcr1Pos` | `string` | Aleo-encoded struct with information for extracting PCR 1. |
| `pcr2Pos` | `string` | Aleo-encoded struct with information for extracting PCR 2. |
| `userDataPos` | `string` | Aleo-encoded struct with information for extracting additional report user data. |

### type `NotarizationOptions`

Client options for notarization. See the [Guide to notarization and attestation](../guide/index.md#step-5-requesting-attestation).

| Property | Type | Description |
| --- | --- | --- |
| `dataShouldMatch` | `boolean` | If multiple attesters are used, the client will check that the attestation data is exactly the same in all attestation responses. |
| `timeout` | `number | undefined` | Attestation request timeout in ms. If not set, the default timeout for the Fetch API implementation will be used. |
| `maxTimeDeviation` | `number | undefined` | If multiple attesters are used this option controls the maximum deviation in milliseconds between attestation timestamps. |

### type `OracleData`

Attestation-related information formatted for direct use in an Aleo program. See the [Guide about Aleo encoding](../guide/understanding_response.md#about-encoding-data-for-aleo) and [encoding documentation](../guide/aleo_encoding.md) for details on
how these values are created.

| Property | Type | Description |
| --- | --- | --- |
| `signature` | `string` | Schnorr signature of a verified Attestation Report as Aleo's `signature`. |
| `userData` | `string` | Aleo-encoded data that was used to create the request hash included in the Attestation Report. See the [Guide about Aleo encoding](../guide/understanding_response.md#about-encoding-data-for-aleo). |
| `report` | `string` | Aleo-encoded Attestation Report. |
| `address` | `string` | A public key the signature was created against. |
| `encodedPositions` | [`ProofPositionalInfo`](#type-proofpositionalinfo) | Object containing information about positions of data included in the Attestation Response hash. |
| `encodedRequest` | `string` | Aleo-encoded request. See the [Guide to understanding encoded request and request hash](../guide/understanding_response.md#about-request-hashes). |
| `requestHash` | `string` | Poseidon8 hash of the `encodedRequest` as Aleo's `u128`. |
| `timestampedRequestHash` | `string` | Poseidon8 hash of the `requestHash` with the attestation timestamp. |
| `reportExtras` | <code>[NitroReportExtras](#type-nitroreportextras) \| undefined</code> | Object containing extra information about the attestation report. If the attestation type is "nitro", it contains Aleo-encoded structs with information that helps to extract user data and PCR values from the report. |

### type `PositionInfo`

Describes position and length of a property encoded to an Aleo program format.

| Property | Type | Description |
| --- | --- | --- |
| `Pos` | `number` | Index of the `u128` where the encoded property starts. |
| `Len` | `number` | Number of `u128`s the encoded property takes. |

### type `ProofPositionalInfo`

Information about positions of different properties in the Aleo-encoded [Attestation Response](#type-attestationresponse). Counting is done on Aleo `u128` properties. Counting starts from 0.

Positions don't take nested structs into account, and can overflow the limit on the number properties that types are allowed to have in Aleo.

See the [encoding documentation](../guide/aleo_encoding.md).

| Property | Type | Description |
| --- | --- | --- |
| `data` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[oracleData](#type-oracledata).userData</code>. |
| `timestamp` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).timestamp</code>. |
| `statusCode` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).responseStatusCode</code> |
| `method` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).requestMethod</code> |
| `responseFormat` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).responseFormat</code> |
| `url` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).url</code>. |
| `selector` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).selector</code>. |
| `encodingOptions` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).encodingOptions</code>. |
| `requestHeaders` | [`PositionInfo`](#type-positioninfo) | Position and length of <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest).requestHeaders</code>. |
| `optionalFields` | [`PositionInfo`](#type-positioninfo) | Position and length of `htmlResultType`, `requestBody`, and `requestContentType` in <code>[AttestationResponse](#type-attestationresponse).[attestationRequest](#type-attestationrequest)</code>. |

### type `SgxInfo`

Information about Intel SGX enclave a Notarization Backend is running in. Includes some extra properties that are encoded for use in Aleo programs for convenience.

| Property | Type | Description |
| --- | --- | --- |
| `securityVersion` | `number` | Security version of the enclave. For SGX enclaves, this is the ISVSVN value. |
| `debug` | `boolean` | If true, the enclave is running in debug mode. |
| `uniqueId` | `string` | The unique ID for the enclave. For SGX enclaves, this is the MRENCLAVE value. Encoded to Base64. |
| `signerId` | `string` | The signer ID for the enclave. For SGX enclaves, this is the MRSIGNER value. Encoded to Base64. |
| `productId` | `string` | The Product ID for the enclave - ISVPRODID value. Encoded to Base64. |
| `tcbStatus` | `number` | The status of the enclave's TCB level. |
| `aleo` | `{ uniqueId: string, signerId: string, productId: string }` | The Unique ID, Signer ID, and Product ID encoded for Aleo. Unique ID and Signer ID are encoded as structs of two `u128`,
Product ID is a single `u128`. |

??? example "Example value of `aleo` properties"

    ```json
    {
      "uniqueId": "{ chunk_1: 182463194922434241099279556506927504877u128, chunk_2: 195059457426944486782769680982131545140u128 }",
      "signerId": "{ chunk_1: 153386052680309655679396867527014121204u128, chunk_2: 35972203959719964238382729092704599014u128 }",
      "productId": "0u128"
    }
    ```
