---
title: SDK overview
---

# Aleo Oracle SDK

To access the API, create an Oracle client. The client gives access to requesting attestation of HTTPS resources.

It also includes a function to test your Attestation Data selectors without performing actual attestation.

!!! info "SDK errors"

    === "JS"

        All client methods may throw errors.

    === "Go"

        Golang SDK returns an error along with the client when you create a client but it returns
        a list of errors along the list of results for client's methods.

    See [Errors](./errors.md) for more information.

## Create new Oracle client

An Oracle client may use more than one notarization enclaves under the hood, therefore all Client's methods return
arrays of results.

Arguments:

- [Client config](../sdk/js_api.md#type-clientconfig) - *optional*

Return:

- [Oracle client](../sdk/js_api.md#class-oracleclient)

=== "JS"

    ```js linenums="1"
    const { OracleClient } = require('@zkportal/aleo-oracle-sdk');

    const client = new OracleClient(); // will use default notarizer and verifier
    ```

=== "JS (client options)"

    ```js linenums="1"
    const { OracleClient } = require('@zkportal/aleo-oracle-sdk');

    const client = new OracleClient({
      notarizer: {
        address: "localhost",
        port: 8080,
        https: false,
        resolve: false,
      },
      verifier: {
        address: "localhost",
        port: 8081,
        https: false,
        resolve: false,
      },
    });
    ```

=== "Go"

    ```go linenums="1"
    import oracle "github.com/zkportal/aleo-oracle-sdk-go"

    func main() {
      client, err := oracle.NewClient() // will use default notarizer and verifier
      if err != nil {
        panic(err)
      }
    }
    ```

=== "Go (client options)"

    ```go linenums="1"
    import oracle "github.com/zkportal/aleo-oracle-sdk-go"

    func main() {
      client, err := oracle.NewClient(&oracle.ClientConfig{
        NotarizerConfig: &oracle.CustomBackendConfig{
          Address: "localhost",
          Port: 8080,
          HTTPS: false,
          Resolve: false,
        },
        VerifierConfig: &oracle.CustomBackendConfig{
          Address: "localhost",
          Port: 8081,
          HTTPS: false,
          Resolve: false,
        },
      })

      if err != nil {
        panic(err)
      }
    }
    ```

## Get enclave information

Requests information about enclaves that Notarization Backend is running in. Can be used to get such important information, like security level or enclave measurements, which can be used to verify that Notarization Backend is running the expected version of the code.

Arguments:

- ["Get enclave info" method options](../sdk/js_api.md#type-infooptions) - *optional*

Return:

- list of enclave information objects [`EnclaveInfo`](../sdk/js_api.md#type-enclaveinfo)

=== "JS"

    ```js linenums="1"
    const enclavesInfo = await client.enclavesInfo();
    ```

=== "Go"

    ```go linenums="1"
    infoList, errList := client.GetEnclavesInfo()
    ```

## Test Attestation Data selector

This function can be used to test your requests without performing attestation and verification.
Notarization Backend will try to request the attestation target and extract data with the provided selector.
You can use the same request that you would use for the Notarize method to see if the Notarization Backend is able to get your data and correctly extract it.
You will be able to see as a result the full response body, extracted data, response status code and errors if there are any.

Arguments:

- [Attestation Request](../sdk/js_api.md#type-attestationrequest)
- ["Test Selector" method options](../sdk/js_api.md#testselector) - *optional*

Return:

- list of debug responses [`DebugRequestResponse`](../sdk/js_api.md#type-debugrequestresponse)

=== "JS"

    ```ts linenums="1"
    const request = {
      url: 'google.com',
      requestMethod: 'GET',
      responseFormat: 'html',
      htmlResultType: 'value',
      selector: '/html/head/title',
      encodingOptions: {
        value: 'string'
      }
    };
    const debugResponses = await client.testSelector(request);
    ```

=== "Go"

    ```go linenums="1"
    request := &AttestationRequest{
      URL:            "google.com",
      RequestMethod:  "GET",
      ResponseFormat: "html",
      HtmlResultType: "value",
      Selector:       "/html/head/title",
      EncodingOptions: EncodingOptions{
        Value:     "string",
      },
    }
    debuResponses, errList := client.TestSelector(request)
    ```

## Notarize and attest

Requests notarization of the data at the provided URL and attestation of the data extracted from it using the provided selector. Attestation is created by one or more TEE. If more than one is used, all attestation requests should succeed.

It is highly recommended to use time insensitive historic data for notarization. In case of using live data, other people might see different results when requesting the same url with the same parameters.

Arguments:

- [Attestation Request](../sdk/js_api.md#type-attestationrequest)
- [Notarization options](../sdk/js_api.md#type-notarizationoptions) - *optional*

Return:

- list of notarization responses [`AttestationResponse`](../sdk/js_api.md#type-attestationresponse)

=== "JS"

    ```ts linenums="1"
    const request = {
      url: 'google.com',
      requestMethod: 'GET',
      responseFormat: 'html',
      htmlResultType: 'value',
      selector: '/html/head/title',
      encodingOptions: {
        value: 'string'
      }
    };
    const attestedResponses = await client.notarize(request);
    ```

=== "Go"

    ```go linenums="1"
    request := &AttestationRequest{
      URL:            "google.com",
      RequestMethod:  "GET",
      ResponseFormat: "html",
      HtmlResultType: "value",
      Selector:       "/html/head/title",
      EncodingOptions: EncodingOptions{
        Value:     "string",
      },
    }
    attestedResponses, errList := client.Notarize(request)
    ```

## Get an attested random number

The SDKs provide a method for getting an attested unsigned random number. It works similarly to the notarization flow
but the notarization backend doesn't perform any outgoing HTTP requests.

The method requires an exclusive upper bound `max` for generating a random number on interval `[0, max)`. The max value can be found in the
attestation request URL in the attestation response.

The upper limit corresponds to the maximum value of Leo's `u128` - 340282366920938463463374607431768211456.

Arguments:

- `max` - Upper bound for random generator
- [Notarization options](../sdk/js_api.md#type-notarizationoptions) - *optional*

Return:

- list of notarization responses [`AttestationResponse`](../sdk/js_api.md#type-attestationresponse)
