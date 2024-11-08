# Go API

[Go SDK :fontawesome-brands-github:]({{ variables.links.go_sdk_repo }})

<details><summary>Example</summary>
<p>

```go
// Create a client
client, err := NewClient(nil)
if err != nil {
	log.Fatalln(err)
}

attestedRandoms, errList := client.GetAttestedRandom(big.NewInt(43), nil)
if errList != nil {
	log.Fatalln(errList)
}

// The URL was notarized, the extracted result was attested by the enclaves, enclave signatures were verified by the verifier, you can now use the data
log.Println()
log.Println("Data extracted from the URL using the selector:", attestedRandoms[0].AttestationData)
log.Println()

// Fetch enclave info for all attesters
infoList, errList := client.GetEnclavesInfo(nil)
if errList != nil {
	log.Fatalln(errList)
}

for _, info := range infoList {
	log.Println()
	log.Println("Enclave info:", info, info.SgxInfo)
	log.Println()
}

// Build attestation request
req := &AttestationRequest{
	URL:            "archive-api.open-meteo.com/v1/archive?latitude=38.9072&longitude=77.0369&start_date=2023-11-20&end_date=2023-11-21&daily=rain_sum",
	ResponseFormat: "json",
	RequestMethod:  http.MethodGet,
	Selector:       "daily.rain_sum.[0]",
	EncodingOptions: EncodingOptions{
		Value:     "float",
		Precision: 2,
	},
}

// Use TestSelector in development if you need to figure out what kind of response you're getting from the attestation target
responses, errList := client.TestSelector(req, nil)
if errList != nil {
	log.Fatalln(errList)
}

log.Println()
log.Println("Test selector result:", *responses[0])
log.Println()

// Use attested notarization once you've figured out what request options you want
timeDeviation := int64(500) // 500ms
options := &NotarizationOptions{
	AttestationContext:  context.Background(),
	VerificationContext: context.Background(),
	DataShouldMatch:     true,
	MaxTimeDeviation:    &timeDeviation,
}

attestations, errList := client.Notarize(req, options)
if errList != nil {
	log.Fatalln(errList)
}

// The URL was notarized, the extracted result was attested by the enclaves, enclave signatures were verified by the verifier, you can now use the data
log.Println("Number of attestations", len(attestations))
for _, at := range attestations {
    log.Println("Attested with", at.ReportType)
    log.Println("Data extracted from the URL using the selector:", at.AttestationData)
    log.Println()
    log.Println("Attestation response prepared for using in an Aleo contract:", at.OracleData.UserData)
    log.Println()
}

// Output:
```

</p>
</details>

## Index

- [Constants](#constants)
- [Variables](#variables)
- [type AttestationRequest](#type-attestationrequest)
- [type AttestationResponse](#type-attestationresponse)
- [type Client](#type-client)
    - [func NewClient\(config \*ClientConfig\) \(\*Client, error\)](#func-newclient)
    - [func \(c \*Client\) GetAttestedRandom\(max \*big.Int, options \*NotarizationOptions) \(\[\]\*AttestationResponse, \[\]error\)](#func-client-getattestedrandom)
    - [func \(c \*Client\) GetEnclavesInfo\(options \*EnclaveInfoOptions\) \(\[\]\*EnclaveInfo, \[\]error\)](#func-client-getenclavesinfo)
    - [func \(c \*Client\) Notarize\(req \*AttestationRequest, options \*NotarizationOptions\) \(\[\]\*AttestationResponse, \[\]error\)](#func-client-notarize)
    - [func \(c \*Client\) TestSelector\(req \*AttestationRequest, options \*TestSelectorOptions\) \(\[\]\*TestSelectorResponse, \[\]error\)](#func-client-testselector)
- [type ClientConfig](#type-clientconfig)
- [type CustomBackendConfig](#type-custombackendconfig)
- [type EnclaveInfo](#type-enclaveinfo)
- [type EnclaveInfoOptions](#type-enclaveinfooptions)
- [type EncodingOptions](#type-encodingoptions)
- [type EncodingOptionsValueType](#type-encodingoptionsvaluetype)
- [type HtmlResultType](#type-htmlresulttype)
- [type NitroAleoInfo](#type-nitroaleoinfo)
- [type NitroDocument](#type-nitrodocument)
- [type NitroInfo](#type-nitroinfo)
- [type NitroReportExtras](#type-nitroreportextras)
- [type NotarizationOptions](#type-notarizationoptions)
- [type OracleData](#type-oracledata)
- [type PositionInfo](#type-positioninfo)
- [type ProofPositionalInfo](#type-proofpositionalinfo)
- [type ResponseFormat](#type-responseformat)
- [type SgxAleoInfo](#type-sgxaleoinfo)
- [type SgxInfo](#type-sgxinfo)
- [type TestSelectorOptions](#type-testselectoroptions)
- [type TestSelectorResponse](#type-testselectorresponse)


## Constants

```go
const (
    REPORT_TYPE_SGX   = "sgx"
    REPORT_TYPE_NITRO = "nitro"
)
```

```go
const (
    // Request timeout used by default for Client's methods
    DEFAULT_TIMEOUT = 5 * time.Second
)
```

## Variables

```go
var (
    DEFAULT_NOTARIZATION_OPTIONS = &NotarizationOptions{
        AttestationContext:  nil,
        VerificationContext: nil,
        DataShouldMatch:     true,
        MaxTimeDeviation:    nil,
    }

    DEFAULT_NOTARIZATION_BACKENDS = []*CustomBackendConfig{
        {
            Address:   "sgx.aleooracle.xyz",
            Port:      443,
            HTTPS:     true,
            ApiPrefix: "",
            Resolve:   true,
        },
        {
            Address:   "nitro.aleooracle.xyz",
            Port:      443,
            HTTPS:     true,
            ApiPrefix: "",
            Resolve:   true,
        },
    }

    DEFAULT_VERIFICATION_BACKEND = &CustomBackendConfig{
        Address:   "verifier.aleooracle.xyz",
        Port:      443,
        HTTPS:     true,
        ApiPrefix: "",
        Resolve:   true,
    }
)
```

```go
var (
    // Default headers that will be added to the attestation request.
    DEFAULT_NOTARIZATION_HEADERS = map[string]string{
        "Accept":                    "*/*",
        "User-Agent":                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36",
        "Upgrade-Insecure-Requests": "1",
        "DNT":                       "1",
    }
)
```

## type AttestationRequest

AttestationRequest contains information about a request to the attestation target, how the attestation target is expected to respond and how to parse its response to extract target data.

IMPORTANT: Max allowed field size is 4kb\!

```go
type AttestationRequest struct {
    // URL of a resource to attest - attestation target. Must not include schema - HTTPS is assumed
    URL string `json:"url"`

    // HTTP method to be used for a request to the attestation target. Supports only GET and POST
    RequestMethod string `json:"requestMethod"`

    // Optional element selector for extracting data from the attestation resource - XPath for HTML, JSON key path for JSON.
    // When empty, the oracle attests to the whole response unless the response size limit of **4kb** is hit.
    //
    // JSON key path example - given an example JSON
    // {
    //  "primitive": "value",
    //  "list": [123, 223, 3],
    //  "dictionary": {
    //    "key1": "value1",
    //    "key2": "value2"
    //  }
    // }
    // 	- selector "primitive" will select "value"
    // 	- selector "list.[1]"" will select "223"
    // 	- selector "dictionary.key2" will select "value2".
    Selector string `json:"selector,omitempty"`

    // Expected attestation target response format
    ResponseFormat ResponseFormat `json:"responseFormat"`

    // When ResponseFormat is RESPONSE_FORMAT_HTML, this field indicates the type of extraction
    // for the response after applying the selector.
    HtmlResultType *HtmlResultType `json:"htmlResultType,omitempty"`

    // Information about how to encode Attestation Data to Aleo-compatible format
    EncodingOptions EncodingOptions `json:"encodingOptions"`

    // Can be used to provide a POST request body for the attestation target request.
    //
    // Has effect only when RequestMethod is POST.
    //
    RequestBody *string `json:"requestBody,omitempty"`

    // Can be used to provide a Content-Type request header for the attestation target request.
    //
    // Has effect only when RequestMethod is POST.
    RequestContentType *string `json:"requestContentType,omitempty"`

    // Optional dictionary of HTTP headers to add to the request to attestation target.
    //
    // Value of headers which might contain sensitive information (like "Authorization", "X-Auth-Token" or "Cookie")
    // and any non-standard headers used by attestation target would be replaced with "*****" in attestation report.
    //
    // This SDK will use some default request headers like User-Agent. See DEFAULT_NOTARIZATION_HEADERS.
    //
    RequestHeaders map[string]string `json:"requestHeaders,omitempty"`
}
```

## type AttestationResponse

AttestationResponse is notarization backend's response to an attestation request

```go
type AttestationResponse struct {
    // URL of the Notarization Backend the report came from.
    EnclaveUrl string `json:"enclaveUrl"`

    // Attestation Report in Base64 encoding, created by the Trusted Execution Environment using the extracted data.
    AttestationReport string `json:"attestationReport"`

    // Which TEE produced the attestation report. Only Intel SGX and AWS Nitro are supported at the moment.
    ReportType string `json:"reportType"`

    // Data extracted from the attestation target's response using the provided selector. The data is always a string, as seen in the raw HTTP response.
    AttestationData string `json:"attestationData"`

    // Full response body received in the attestation target's response.
    ResponseBody string `json:"responseBody"`

    // Status code of the attestation target's response.
    ResponseStatusCode int `json:"responseStatusCode"`

    // Reserved.
    Nonce string `json:"nonce,omitempty"`

    // Unix timestamp of the attestation date time as seen by the attestation server (not attestation target).
    Timestamp int64 `json:"timestamp"`

    // Information that can be used in your Aleo program, like Aleo-formatted attestation report.
    OracleData OracleData `json:"oracleData"`

    // Original attestation request included in the AttestationReport hash.
    // Keep in mind that all request headers that are not in the list of known headers will be replaced with "*****"".
    // Also the order might be different from the original request (which is important when calculating a hash of AttestationReport).
    AttestationRequest *AttestationRequest `json:"attestationRequest"`
}
```

## type Client

Aleo Oracle client.

```go
type Client struct {
    // contains filtered or unexported fields
}
```

### func NewClient

```go
func NewClient(config *ClientConfig) (*Client, error)
```

NewClient creates a new client using the provided configuration. Configuration is optional. If no configuration is provided, then only one notarizer is used with a verifier hosted by zkPortal, and a transport similar to \[http.DefaultTransport\], and no logging.

### func \(\*Client\) GetAttestedRandom

```go
func (c *Client) GetAttestedRandom(max *big.Int, options *NotarizationOptions) ([]*AttestationResponse, []error)
```

Requests an attested random number within a \[0, max\) interval.

### func \(\*Client\) GetEnclavesInfo

```go
func (c *Client) GetEnclavesInfo(options *EnclaveInfoOptions) ([]*EnclaveInfo, []error)
```

GetEnclavesInfo requests information about the enclaves that the Notarization Backends are running in.

Can be used to get such important information as security level or enclave measurements, which can be used to verify that Notarization Backend is running the expected version of the code.

Options are optional, will use 5\-second timeout context if options are nil.

### func \(\*Client\) Notarize

```go
func (c *Client) Notarize(req *AttestationRequest, options *NotarizationOptions) ([]*AttestationResponse, []error)
```

Notarize requests attestation of data extracted from the provided URL using the provided selector. Attestation is created by one or more Trusted Execution Environments \(TEE\). Returns all successfully produced and verified attestations and discards the invalid ones.

It is highly recommended to use time insensitive historic data for notarization. In case of using live data, other people might see different results when requesting the same url with the same parameters.

Use options to configure attestation. If not provided, will use default options \- 5 sec timeouts, DataShouldMatch, no time deviation checks.

### func \(\*Client\) TestSelector

```go
func (c *Client) TestSelector(req *AttestationRequest, options *TestSelectorOptions) ([]*TestSelectorResponse, []error)
```

TestSelector is a function that can be used to test your requests without performing attestation and verification.

Notarization Backend will try to request the attestation target and extract data with the provided selector. You can use the same request that you would use for Notarize to see if the Notarization Backend is able to get your data and correctly extract it. You will be able to see as a result the full ResponseBody, extracted data, response status code and errors if there are any.

Options are optional. If nil, will use a 5\-second timeout context.

## type ClientConfig

ClientConfig contains client instantiation configuration.

```go
type ClientConfig struct {
    // NotarizerConfig is a an optional field for configuring the client to use a self-hosted Oracle Notarization service for testing.
    // If not provided, the client will use the default Oracle Notarization service/services hosted by the developer.
    NotarizerConfig *CustomBackendConfig

    // VerifierConfig is a an optional field for configuring the client to use a self-hosted Oracle Notarization Verification service.
    // If not provided, the client will use the default Oracle Notarization Verification service hosted by the developer.
    VerifierConfig *CustomBackendConfig

    // Optional Client logger. No logs will be used if not provided.
    Logger *log.Logger

    // Optional transport configuration. If not provided, the a transport similar to [http.DefaultTransport] will be used.
    Transport http.RoundTripper
}
```

## type CustomBackendConfig

CustomBackendConfig is a configuration object for using custom notarizer or verifier.

```go
type CustomBackendConfig struct {
    // Domain name or IP address of the backend
    Address string

    // The port that the backend listens on for the API requests
    Port uint16

    // Whether the client should use HTTPS to connect to the backend
    HTTPS bool

    // Whether the client should resolve the backend (when it's a domain name).
    // If the domain name is resolved to more than one IP, then the requests will be
    // sent to all of the resolved servers, and the first response will be used.
    Resolve bool

    // Optional API prefix to use before the API endpoints
    ApiPrefix string
}
```

## type EnclaveInfo

Contains information about the TEE enclave that the Notarization Backend is running in

```go
type EnclaveInfo struct {
    json.Unmarshaler

    // Url of the Notarization Backend the report came from.
    EnclaveUrl string

    // TEE that backend is running in
    ReportType string

    // This is a public key of the report signing key that was generated in the enclave.
    // The signing key is used to create Schnorr signatures,
    // and the public key is to be used to verify that signature inside of a program.
    // The public key is encoded to Aleo "address" type.
    SignerPubKey string

    // Information about the SGX enclave. Exists only when ReportType is "sgx"
    SgxInfo *SgxInfo

    // Information about the Nitro enclave. Exists only when ReportType is "nitro"
    NitroInfo *NitroInfo
}
```

## type EnclaveInfoOptions

GetEnclavesInfo options.

```go
type EnclaveInfoOptions struct {
    // Optional enclave information request context. If not provided, uses a context with timeout of 5s.
    Context context.Context
}
```

## type EncodingOptions

EncodingOptions is a type containing information about how Notarization Backend should interpret the Attestation Data to encode it to Aleo format. Data will be encoded to Aleo "u128" to allow for usage inside of Aleo programs.

```go
type EncodingOptions struct {
    // Defines how Notarization Backend should interpret the Attestation Data to encode it to Aleo format.
    Value EncodingOptionsValueType

    // Aleo program encoding precision of the Attestation Data when interpreting as float and encoding it to Aleo format.
    // Must be equal or bigger than the number of digits after the comma. Maximum is 12.
    //
    // Required if Value is ENCODING_OPTIONS_VALUE_FLOAT
    //
    // Precision should always be bigger or equal to the number of digits in the fractional part of the extracted number.
    // If the number has more digits in the fractional part than the provided precision, it will be sliced to the provided precision.
    //
    // With Precision=3, the slicing examples:
    //   - 123.456 -> 123.456
    //   - 123.45 -> 123.45
    //   - 123.4567 -> 123.456
    //
    // With Precision=0, the slicing examples:
    //   - 123.456 -> 123
    //   - 123.45 -> 123
    //   - 123.4567 -> 123
    Precision int
}
```

## type EncodingOptionsValueType

The expected type of value that should be used to interpret Attestation Data to encode it to Aleo format \(to be used in an Aleo program\).

```go
type EncodingOptionsValueType string
```

Available options for EncodingOptionsValueType

```go
const (
    ENCODING_OPTIONS_VALUE_STRING EncodingOptionsValueType = "string" // Extracted value is interpretted as a string
    ENCODING_OPTIONS_VALUE_FLOAT  EncodingOptionsValueType = "float"  // Extracted value is interpreted as a positive floating point number up to 64 bits in size
    ENCODING_OPTIONS_VALUE_INT    EncodingOptionsValueType = "int"    // Extracted value is interpreted as an unsigned decimal integer up to 64 bits in size
)
```

## type HtmlResultType

Type of value extraction on a HTML element after applying a selector.

```go
type HtmlResultType string
```

Available options for HTML result type. Given a selected HTML element

```
<a href="/test">Nice link</a>
```

```go
const (
    HTML_RESULT_TYPE_ELEMENT HtmlResultType = "element" // will extract "<a href="/test">Nice link</a>"
    HTML_RESULT_TYPE_VALUE   HtmlResultType = "value"   // will extract "Nice link"
)
```

## type NitroAleoInfo

```go
type NitroAleoInfo struct {
    // PCRs 0-2 encoded for Aleo as one struct of 9 `u128` fields, 3 chunks per PCR value.
    //
    // Example:
    //
    // "{ pcr_0_chunk_1: 286008366008963534325731694016530740873u128, pcr_0_chunk_2: 271752792258401609961977483182250439126u128, pcr_0_chunk_3: 298282571074904242111697892033804008655u128, pcr_1_chunk_1: 160074764010604965432569395010350367491u128, pcr_1_chunk_2: 139766717364114533801335576914874403398u128, pcr_1_chunk_3: 227000420934281803670652481542768973666u128, pcr_2_chunk_1: 280126174936401140955388060905840763153u128, pcr_2_chunk_2: 178895560230711037821910043922200523024u128, pcr_2_chunk_3: 219470830009272358382732583518915039407u128 }"
    PCRs string `json:"pcrs"`

    // Self report user data (always zero) encoded for Aleo as a `u128`.
    //
    // Example:
    //
    // "0u128"
    UserData string `json:"userData"`
}
```

## type NitroDocument

```go
type NitroDocument struct {
    // Issuing Nitro hypervisor module ID.
    ModuleID string `json:"moduleID"`

    // UTC time when document was created, in milliseconds since UNIX epoch.
    Timestamp int64 `json:"timestamp"`

    // The digest function used for calculating the register values.
    Digest string `json:"digest"`

    // Map of all locked PCRs at the moment the attestation document was generated.
    // The PCR keys are 0-15. All PCR values are 48 bytes long. Base64.
    PCRs map[string]string `json:"pcrs"`

    // The public key certificate for the public key that was used to sign the attestation document. Base64.
    Certificate string `json:"certificate"`

    // Issuing CA bundle for infrastructure certificate. Base64.
    CABundle []string `json:"cabundle"`

    // Additional signed user data. Always zero in a self report. Base64.
    UserData string `json:"userData"`

    // An optional cryptographic nonce provided by the attestation consumer as a proof of authenticity. Base64.
    Nonce string `json:"nonce"`
}
```

## type NitroInfo

```go
type NitroInfo struct {
    // Nitro enclave attestation document.
    Document NitroDocument `json:"document"`

    // Protected section from the COSE Sign1 payload of the Nitro enclave attestation result. Base64.
    ProtectedCose string `json:"protectedCose"`

    // Signature section from the COSE Sign1 payload of the Nitro enclave attestation document. Base64.
    Signature string `json:"signature"`

    // Some of the Nitro document values encoded for Aleo.
    Aleo NitroAleoInfo `json:"aleo"`
}
```

## type NitroReportExtras

```go
type NitroReportExtras struct {
    Pcr0Pos     string `json:"pcr0Pos"`
    Pcr1Pos     string `json:"pcr1Pos"`
    Pcr2Pos     string `json:"pcr2Pos"`
    UserDataPos string `json:"userDataPos"`
}
```

## type NotarizationOptions

NotarizationOptions contains ptional parameters that you can provide to Notarize method.

If not provided, default values will be used.

```go
type NotarizationOptions struct {
    // Optional attestation request context. If not provided, uses a context with timeout of 5s.
    AttestationContext context.Context

    // Optional verification request context. If not provided, uses a context with timeout of 5s.
    VerificationContext context.Context

    // If multiple attesters are used, the client will check that the attestation data is exactly the same in all attestation responses.
    DataShouldMatch bool

    // If multiple attesters are used this option controls the maximum deviation in milliseconds between attestation timestamps.
    //
    // 	- if set to 0, requires that all attestations are done at the same time (not recommended). Note that the attestation timestamp
    // is set by the attestation server using server time.
    // 	- if nil, no time deviation checks are performed.
    //  - if time deviation is set to less then a second, attestation might fail due to naturally occuring network delays between the Oracle SDK, the notarization backends, and the attestation target.
    //  - if deviation is set to more than 10 seconds (10 * 1000 ms), the attestation target responses might differ from each other because one of the requests took too long, and the requested information either has changed or is not available anymore.
    MaxTimeDeviation *int64
}
```

## type OracleData

OracleData contains information that can be used in your Aleo program. All fields are encoded to Aleo\-compatible formats and represented as strings.

```go
type OracleData struct {
    // Schnorr signature of a verified Attestation Report.
    Signature string `json:"signature"`

    // Aleo-encoded data that was used to create the hash included in the Attestation Report.
    //
    // See ProofPositionalInfo for an idea of what data goes into the hash.
    UserData string `json:"userData"`

    // Aleo-encoded Attestation Report.
    Report string `json:"report"`

    // Public key the signature was created against.
    Address string `json:"address"`

    // Object containing information about the positions of data included in the Attestation Report hash.
    EncodedPositions ProofPositionalInfo `json:"encodedPositions"`

    // Aleo-encoded request. Same as UserData but with zeroed Data and Timestamp fields. Can be used to validate the request in Aleo programs.
    //
    // Data and Timestamp are the only parts of UserData that can be different every time you do a notarization request.
    // By zeroing out these 2 fields, we can create a constant UserData which is going to represent a request to the attestation target.
    // When an Aleo program is going to verify that a request was done using the correct parameters, like URL, request body, request headers etc.,
    // it can take the UserData provided with the Attestation Report, replace Data and Timestamp with "0u128" and then compare the result with the constant UserData in the program.
    // If both UserDatas match, then we know that the Attestation Report was made using the correct attestation target request!
    //
    // To avoid storing the full UserData in an Aleo program, we can hash it and store only the hash in the program. See RequestHash.
    EncodedRequest string `json:"encodedRequest"`

    // Poseidon8 hash of the EncodedRequest. Can be used to verify in an Aleo program that the report was made with the correct request.
    RequestHash string `json:"requestHash"`

    // Poseidon8 hash of the RequestHash with the attestation timestamp. Can be used to verify in an Aleo program that the report was made with the correct request.
    TimestampedRequestHash string `json:"timestampedRequestHash"`

    // Object containing extra information about the attestation report.
    // If the attestation type is "nitro", it contains Aleo-encoded structs with
    // information that helps to extract user data and PCR values from the report.
    ReportExtras *NitroReportExtras `json:"reportExtras"`
}
```

## type PositionInfo

PositionInfo contains extra information about the way attestation response was encoded for Aleo. Useful in development to find the positions of different response elements for Aleo program development.

```go
type PositionInfo struct {
    // Index of the block where the write operation started. Indexing starts from 0. Note that this number doesn't account the fact that each chunk contains 32 blocks.
    //
    // If Pos is >32, it means that there was an "overflow" to the next chunk of 32 blocks, e.g. Pos 31 means chunk 0 field 31, Pos 32 means chunk 1, field 0.
    Pos int

    // Number of blocks written in the write operation.
    Len int
}
```

## type ProofPositionalInfo

ProofPositionalInfo is an object containing information about the positions of data included in the Attestation Report hash. This object is created to help developers understand how to extract fields to verify or use them in Aleo programs.

No element will occupy positions 0 and 1. Positions 0 and 1 in OracleData.UserData are reserved for information about data positioning, i.e. meta header \(which can be used later to decode and verify OracleData.UserData\).

```go
type ProofPositionalInfo struct {
    Data            PositionInfo `json:"data"`
    Timestamp       PositionInfo `json:"timestamp"`
    StatusCode      PositionInfo `json:"statusCode"`
    Method          PositionInfo `json:"method"`
    ResponseFormat  PositionInfo `json:"responseFormat"`
    Url             PositionInfo `json:"url"`
    Selector        PositionInfo `json:"selector"`
    EncodingOptions PositionInfo `json:"encodingOptions"`
    RequestHeaders  PositionInfo `json:"requestHeaders"`
    OptionalFields  PositionInfo `json:"optionalFields"` // Optional fields are HTML result type, request content type, request body. They're all encoded together.
}
```

## type ResponseFormat

Attestation target response format

```go
type ResponseFormat string
```

Available options for ResponseFormat

```go
const (
    RESPONSE_FORMAT_JSON ResponseFormat = "json"
    RESPONSE_FORMAT_HTML ResponseFormat = "html"
)
```

## type SgxAleoInfo

```go
type SgxAleoInfo struct {
    UniqueID  string `json:"uniqueId"`  // Same as UniqueID but encoded for Aleo as 2 uint128
    SignerID  string `json:"signerId"`  // Same as SignerID but encoded for Aleo as 2 uint128
    ProductID string `json:"productId"` // Same as ProductID but encoded for Aleo as 1 uint128
}
```

## type SgxInfo

Contains information about an SGX enclave.

```go
type SgxInfo struct {
    SecurityVersion uint        `json:"securityVersion"` // Security version of the enclave. For SGX enclaves, this is the ISVSVN value.
    Debug           bool        `json:"debug"`           // If true, the report is for a debug enclave.
    UniqueID        []byte      `json:"uniqueId"`        // The unique ID for the enclave. For SGX enclaves, this is the MRENCLAVE value.
    SignerID        []byte      `json:"signerId"`        // The signer ID for the enclave. For SGX enclaves, this is the MRSIGNER value.
    ProductID       []byte      `json:"productId"`       // The Product ID for the enclave. For SGX enclaves, this is the ISVPRODID value.
    Aleo            SgxAleoInfo `json:"aleo"`            // Some of the SGX report values encoded for Aleo.
    TCBStatus       uint        `json:"tcbStatus"`       // The status of the enclave's TCB level.
}
```

## type TestSelectorOptions

TestSelector method options.

```go
type TestSelectorOptions struct {
    Context context.Context
}
```

## type TestSelectorResponse

TestSelector response, which contains information for debugging selectors for extracting AttestationData for calling Notarize.

```go
type TestSelectorResponse struct {
    // URL of the Notarization Backend the response came from.
    EnclaveUrl string `json:"enclaveUrl"`

    // Full response body received in the attestation target's response
    ResponseBody string `json:"responseBody"`

    // Status code of the attestation target's response
    ResponseStatusCode int `json:"responseStatusCode"`

    // Extracted data from ResponseBody using the provided selector
    ExtractedData string `json:"extractedData"`
}
```
