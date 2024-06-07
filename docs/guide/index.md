# Getting started

This guide will walk you through creating your first attestation and using it in Aleo.

To get started, install the SDK by following the [SDK overview](../sdk/index.md) and create a client.

## Step 1: identify the data

First, you need to identify the data that you want to use in an Aleo program. Generally,
the Oracle SDK supports any static HTTPS website that can be accessed publicly or by providing
the right headers, and/or cookies, and/or request body.

!!! warning "On attesting dynamically rendered content"

    The data you want to use must be "statically rendered", meaning it must be present in the raw HTTP response.

    That means you cannot use the data that is rendered after the website is loaded, e.g. if it's fetched using XHR or Websocket.

    But you will probably be able to use directly the API that the website has used to fetch the data.

Some examples of the data you may want to use in a program:

- price feeds for fiat/crypto
- bank statements
- invoices, receipts
- identity-related information, e.g. age or citizenship
- media resources

For this example we'll use weather data for Amsterdam and put the precipitation amount into an Aleo program.

[https://archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum](https://archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum)

!!! info ""

    It is highly recommended to use time insensitive historic data. In case of using live data, other people might see different results when requesting the same url with the same parameters.

### Whitelist

The notarizer maintains a list of hosts that are allowed to be notarized. You can query the list at `https://sgx.aleooracle.xyz/whitelist`. If you would like to whitelist a host, please contact us.

??? info "Current whitelist"

    This list may be outdated, always query the list from the URL.

    ```json
    [
        "google.com",
        "api-testnet.bybit.com",
        "verifier.aleooracle.xyz",
        "api.bitfinex.com",
        "api.coinbasecloud.net",
        "api-pub.bitfinex.com",
        "sgx.aleooracle.xyz",
        "api.international.coinbase.com",
        "api.bybit.com",
        "www.kraken.com",
        "pro-api.coinmarketcap.com",
        "docs.aleooracle.xyz",
        "api.exchange.coinbase.com",
        "www.okx.com",
        "data-api.binance.vision",
        "testnet.binance.vision",
        "www.coinbase.com",
        "api.kraken.com",
        "archive-api.open-meteo.com",
        "public.bybit.com",
        "api.prime.coinbase.com",
        "www.bitstamp.net",
        "www.bitfinex.com",
        "api.kucoin.com",
        "www.kucoin.com",
        "api.binance.com",
        "api-futures.kucoin.com",
        "iapi.kraken.com",
        "www.bybit.com"
    ]
    ```

## Step 2: create an HTTP request to get the data

Now you need to create an HTTP request that results in a response containing the data you want.

In our example, the request is pretty straightforward. We perform a GET request and expect a JSON response.

```bash
$ curl "https://archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum"
```

The response:
```json
--8<-- "example_weather_api_response.json"
```

## Step 3: select the data from the response

Now that we have a response and we know how it looks, it's time to extract the data that we want in the contract, or Attestation Data.

This SDK uses a selector, which is applied to the response.

For HTML responses, it uses [XPath](https://en.wikipedia.org/wiki/XPath).

For JSON, it uses a JSON key path similar to [JQ](https://jqlang.github.io/jq/) query syntax.

See the [Selector section](#selector) for examples.

## Step 4: build an attestation request

Now you can put everything we have done so far into the source code.

Attestation Request describes a notarization request to the attestation target, how the attestation target is expected to respond and how to parse its response to extract target data.

<div class="grid cards" markdown>

-   __JS SDK__

    ---

    [`AttestationRequest`](../sdk/js_api.md#type-attestationrequest)

-   __Go SDK__

    ---

    [`AttestationRequest`](../sdk/go_api.md#AttestationRequest)

</div>

Not all of the properties in the Attestation Request are mandatory.

Below we will describe every property of an Attestation Request and give examples of them.

You can also jump to the [Attestation Request example](#attestation-request-example) for our weather example.

### URL

URL of a resource to attest - attestation target. URL should be specified without a scheme - assumes HTTPS.

!!! example

    `archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum`

### Request method

HTTP method to be used for a request to the attestation target.

The following methods are supported:

- `GET`
- `POST`

### Selector

Optional element selector for extracting data from the attestation resource - XPath for HTML, JSON key path for JSON.
When not provided or empty, the oracle attests to the whole response unless the response size limit of `{{ variables.constants.attestation_text_size_limit }}` is exceeded.

!!! example

    === "JSON key path"

        For JSON, a selector is a JSON key path similar to [JQ](https://jqlang.github.io/jq/) query syntax.

        In our example response, this is how the JSON selectors could look:

        - `latitude` will select `42.917397`
        - `daily_units.rain_sum` will select `"mm"`
        - `daily.rain_sum.[0]` will select `9.90`

    === "XPath"

        For HTML responses, it uses [XPath](https://en.wikipedia.org/wiki/XPath).

        For a page like
        ```html
        <html>
          <head>
            <title>Page title</title>
          </head>
        </html>
        ```

        a selector selecting the page title is `/html/head/title`.

### Response format

Expected attestation target response format.

Supported values:

- `JSON`
- `HTML`

In our example, the response format is `JSON`.

### HTML result type

When Response format is `HTML` you also need to indicate the type of extraction for the response after applying the selector.

Supported values:

- `element`
- `value`

If the data after applying the selector is `<a href="/test">Nice link</a>`

- using `element` will make `<a href="/test">Nice link</a>` the Attestation Data
- using `value` will make `Nice link` the Attestation Data

### Request body

Can be used to provide a POST request body for the attestation target request. Max allowed size is `{{ variables.constants.attestation_text_size_limit }}`. Has effect only when Request method is `POST`.

!!! example

    Any HTTP request body

    `{"userName": "user","firstName": "first","lastName": "last"}`

### Request content type

Can be used to provide a Content-Type request header for the attestation target request.
Has effect only when Request method is `POST`.

!!! example

    `application/json`

### Request headers

Optional dictionary of HTTP headers to add to the request to attestation target.
The header values that may contain sensitive information (like `Authorization`, `X-Auth-Token` or `Cookie`) and any non-standard header values used by the attestation target will be replaced with `*****` in the attestation report. Note that the headers are used "as is" for the Attestation Request.

!!! info

    Here is a list of [known headers that will not be replaced](./accepted_headers.md).

The SDK will use some default headers, which can be overriden.

<div class="grid cards" markdown>

-   __JS SDK__

    ---

    [`DEFAULT_NOTARIZATION_HEADERS`](../sdk/js_api.md#default_notarization_headers)

-   __Go SDK__

    ---

    [`DEFAULT_NOTARIZATION_HEADERS`](../sdk/go_api.md#DEFAULT_NOTARIZATION_HEADERS)

</div>

### Encoding options

Object containing information about how Notarization Backend should interpret the Attestation Data to encode it to Aleo format. Data will be encoded to Aleo `u128` to allow for usage inside of Aleo programs.

For more information about encoding see the [Guide to understanding Attestation Response](./understanding_response.md).

<div class="grid cards" markdown>

-   __JS SDK__

    ---

    [`EncodingOptions`](../sdk/js_api.md#type-encodingoptions)

-   __Go SDK__

    ---

    [`EncodingOptions`](../sdk/go_api.md#EncodingOptions)

</div>

Encoding options have 2 properties:

- Value
- Precision

#### Value

Defines how Notarization Backend should interpret the Attestation Data to encode it to an Aleo-compatible format.

Supported values:

- `string` - extracted value is a string
- `int` - extracted value is an unsigned decimal integer up to 64 bits in size
- `float` - extracted value is an unsigned floating point number up to 64 bits in size

#### Precision

This property has effect only when Value is `float`.

Since Aleo doesn't support floating point numbers, they need to be represented as integers.

Defines how many digits are expected in the fractional part of the extracted Attestation Data. Maximum supported precision is `{{ variables.constants.attestation_precision_limit }}`. Required when `value` is `float`.

Precision should always be more or equal to the number of digits in the fractional part of the extracted number. If the number has more digits in the fractional part than the provided precision, it will be sliced to the provided precision.

!!! example "Precision slicing example"

    Precision: 3

    - 123.45 -> 123.45
    - 123.456 -> 123.456
    - 123.4567 -> 123.456

    Precision: 0

    - 123.4 -> 123
    - 123.456 -> 123

To learn the effect is has on the Aleo encoded Attestation Data, see the [Attestation Data as a floating point number](./understanding_response.md#attestationdata-as-a-floating-point-number) section of the [Guide to understanding Attestation Response](./understanding_response.md).

### Attestation request example

Now that we have covered all the properties, we could see how a request will look like
for the weather example.

!!! example

    === "JS"

        ```js linenums="1"
        const req = {
            url: 'archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum',
            requestMethod: 'GET',
            selector: 'daily.rain_sum.[0]',
            responseFormat: 'json',
            encodingOptions: {
                value: 'float',
                precision: 2
            },
        }
        ```

    === "Go"

        ```go linenums="1"
        req := &AttestationRequest{
            URL:            "archive-api.open-meteo.com/v1/archive?latitude=42.93869&longitude=-74.18819&start_date=2024-02-28&end_date=2024-02-28&daily=rain_sum",
            ResponseFormat: "json",
            RequestMethod:  "GET",
            Selector:       "daily.rain_sum.[0]",
            EncodingOptions: EncodingOptions{
                Value:     "float",
                Precision: 2,
            },
        }
        ```

## Step 5: requesting attestation

Once we have an Attestation Request, we can call Notarize on the client.

<div class="grid cards" markdown>

-   __JS SDK__

    ---

    [`OracleClient.notarize`](../sdk/js_api.md#notarize)

-   __Go SDK__

    ---

    [`Client.Notarize`](../sdk/go_api.md#Client.Notarize)

</div>

It accepts a request and Notarization Options.

!!! tip "Debugging attestation requests"

    You can use the Test Selector method in the SDK of your choice to perform notarization without attestation.

    Notarization Backend will try to request the attestation target and extract data with the provided selector.
    You can use the same request that you would use for Notarize method to see if the Notarization Backend is able to get your data and correctly extract it.
    You will be able to see as a result the full response body, extracted data, response status code and errors if there are any.

    The difference between Test Selector and Notarize is that Notarize will not return the response body if the extraction fails.

The Notarization Backend(s) will send a request to the Attestation Target, extract the data using the selector, then create an attestation report.

The results are returned to the SDK. Then it sends the results to the Verification Backend, which will make sure that the Notarization Backends are running
the desired source code revision, and that the chain of trust was not broken. Only then the SDK will return the attestation result from the Notarize call.

### Notarization options

<div class="grid cards" markdown>

-   __JS SDK__

    ---

    [`NotarizationOptions`](../sdk/js_api.md#type-notarizationoptions)

-   __Go SDK__

    ---

    [`NotarizationOptions`](../sdk/go_api.md#NotarizationOptions)

</div>


#### Data should match

If multiple attesters are used, the client will check that the attestation data is exactly the same in all attestation responses.

The SDK will return an error if attestation succeeds in all Notarization Backends but the results don't match.

#### Timeout

Attestation request timeout in milliseconds. If not set, a default value will be used (depends on the environment).

#### Maximum time deviation

If multiple attesters are used this option controls the maximum deviation in milliseconds between attestation timestamps.

- if set to 0, requires that all attestations are done at the same time (not recommended). Note that the attestation timestamp is set by the attestation server using server time.
- if is not set, no time deviation checks are performed.
- if time deviation is set to less then a second, attestation might fail due to naturally occuring network delays between the Oracle SDK, the notarization backends, and the attestation target.
- if deviation is set to more than 10 seconds (10 * 1000 ms), the attestation target responses might differ from each other if one of the requests took too long, and the requested information either had changed or was not available anymore.

