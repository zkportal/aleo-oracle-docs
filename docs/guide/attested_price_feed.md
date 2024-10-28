# Attested Price Feed

Aleo Network Foundation is sponsoring prices of `Aleo`, `Bitcoin`, and `Ethereum` in the `official_oracle.aleo` program for everybody to use on mainnet. So if you need a current price for any of those currencies, you can now simply query those without paying. Prices are being updated every hour using our notarization backends. We use multiple exchanges and produce an average weighted price based on every exchange trading volume.

!!! note "Exchanges used in average price calculations per coin"
    * Aleo:
        - XT, Gate.io, Coinbase, MEXC

    * Bitcoin:
        - Binance, Bybit, Coinbase, Crypto.com

    * Ethereum:
        - Binance, Bybit, Coinbase, Crypto.com

We use the 3 biggest exchanges based on volume and data from coinmarketcap or exchanges themselves, we do however always include coinbase no matter the volume.

## Price calculation process

In order to calculate the weighted average price the notarization backend queries each of the 4 exchanges for prices of each coin against all of the `USD` stable coins or spot available on the exchange (for example, `BTC/USDC`, `BTC/USDT`, `ALEO/USD`) and the corresponding trading volume for each currency on each exchange (if available). Once the data is collected, a weighted average price is calculated. The weight of each price is determined based on the volume of trades from the respective exchange. This approach ensures that higher-volume exchanges contribute more heavily to the final average, reflecting a more accurate market value. At least 2 exchanges should successfully reply in order to calculate the weighted average price.

After the calculation the notarization backend produces an attestation report containing the calculated price which we later use to update the `official_oracle.aleo`.

!!! note "Using multiple TEE's"
    We have multiple notarization backends running in both `SGX` and `Nitro` enclaves to have a more secure setup and to not rely on just one source of trust in case there is a breach of one of the TEE's that we are using. We are randomizing which TEE is used for every price update separately for each coin. This means that if you want to always have the latest available data, you would have to check which TEE was used for the last update and query the corresponding mapping from the `official_oracle.aleo` program. More on that in the example bellow.

## Request hash

Here are the request hashes for each currency to use as a key to read the oracle mappings, which contain the latest updated prices:
```
Aleo - 325436984254736568690754472542545613141u128
Bitcoin - 298333406399166460220216814461649767877u128
Ethereum - 77627430694699498847744475143514157246u128
```

For the curious, to get an idea how to make such a hash we below provide a mock example request which could be the input to generating such a request hash above. This request is representing a specific call to our notarization backend which can be uniquely identified:
```
{
 "url": "price_feed: btc",
 "requestMethod": "GET",
 "selector": "weightedAvgPrice",
 "responseFormat": "json",
 "encodingOptions": {
   "value": "float",
   "precision": 6
 }
}
```
*Where `url` is in a `price_feed: <coin>` format, where coin is `btc`, `eth`, or `aleo`*

Then we take a Poseidon8 hash of this request and use it as a key when querying the oracle program:
!!! example "Poseidon8 hash in leo"
    ```
    async transition check_request(public report_data: ReportData) -> u128 {
      let request_hash: u128 = Poseidon8::hash_to_u128(report_data);

      return request_hash;
    }
    ```

!!! danger "What goes into the request hash"
    This example is simplified and was made just to explain how the `request hash` works. The actual request hash includes more fields, for example request headers, response status code etc. and is calculated without timestamp and the attestation data. To get more information on how a request hash is calculated visit [About request hashes](./understanding_response.md#about-request-hashes). To get a more detailed explanation of what is included into the request hash visit [Encoding data for an Aleo program](./aleo_encoding.md#encoding-data-for-an-aleo-program).


## Update timestamps

During every oracle update we save the timestamps of every currency update so that users can query the market price of a currency at a specific time. We publish timestamps of every update of every currency in a file in the [price feed index GitHub repository](https://github.com/zkportal/aleo-price-feed-index). You can take a timestamp of an update and combine it with the request hash like explained earlier (see [Historical Data](./oracle_program.md#historical-data)) to get the Timestamped Request hash, which you can use to get data from the oracle program.

!!! note "Understanding the timestamps prefix"
    Timestamps in our [GitHub repository](https://github.com/zkportal/aleo-price-feed-index) are being stored in the `<tee timestamp>` format:
        ```
        s 1729861708
        s 1729862055
        n 1729864084
        ```
    Where **`s`** and **`n`** in the beginning of the line indicates which TEE was used for respective update. **`s`** represents that an update was done using an `SGX` enclave and **`n`** represents an update with `AWS Nitro` enclave.

    Keep in mind that each TEE has its own mapping to read from in the `official_oracle.aleo` program. `sgx_attested_data` for `SGX` and `nitro_attested_data` for `Nitro`.

Next to querying historic prices we also have a convenience function that allows you to get just the latest available quote, see the example below to always just query that.

## Using the price feed

Here is an example of how to get quotes stored in the oracle.

!!! example "Querying the Aleo Oracle from Aleo program"

    === "Leo"

        ```leo linenums="1"
        import official_oracle.aleo;

        program use_oracle.aleo {
          struct TimestampedHash {        // Aleo struct definition for calculating the timestamped hash
            request_hash: u128,           // This is the hash from above depending on the coin
            attestation_timestamp: u128   // This is the timestamp you got from the git repo
          }

          ...

          async function finalize_query_oracle() {
            // use the correct request hash for the respective coin
            let aleo_request_hash: u128 = 325436984254736568690754472542545613141u128;

            // read latest available value from the oracle
            // you get the latest published quote when request hash used at it is

            // read data attested by an SGX enclave
            let sgx_latest_data_from_oracle: AttestedData = official_oracle.aleo/sgx_attested_data.get(aleo_request_hash);
            // read data attested by a Nitro enclave
            let nitro_latest_data_from_oracle: AttestedData = official_oracle.aleo/nitro_attested_data.get(aleo_request_hash);

            sgx_latest_data_from_oracle.data                        // latest available Aleo price attested by an SGX
            sgx_latest_data_from_oracle.attestation_timestamp       // timestamp of when this quote was created

            // compare the timestamps to identify which quote is newer to use the latest available
            let sgx_is_newer: bool = sgx_latest_data_from_oracle.attestation_timestamp.gte(nitro_latest_data_from_oracle.attestation_timestamp);
            // use the newer price
            let latest_available_price: u128 = sgx_is_newer ? sgx_latest_data_from_oracle.data : nitro_latest_data_from_oracle.data;



            // to get a quote at a specific timestamp you need to create a timestamped request hash
            // you can get all the available timestamps from our GitHub repository
            // https://github.com/zkportal/aleo-price-feed-index
            let target_timestamp: u128 = 1729697539u128;

            let struct_to_hash: TimestampedHash = TimestampedHash {
              request_hash: 325436984254736568690754472542545613141u128,      // same request hash
              attestation_timestamp: target_timestamp                         // time of attestation
            };

            let timestamped_hash: u128 = Poseidon8::hash_to_u128(struct_to_hash);

            // read oracle with created hash
            let sgx_historic_data_from_oracle: AttestedData = official_oracle.aleo/sgx_attested_data.get(timestamped_hash);
            let nitro_historic_data_from_oracle: AttestedData = official_oracle.aleo/nitro_attested_data.get(timestamped_hash);

            historic_data_from_oracle.data                     // aleo price at a specific timestamp attested by an SGX
            historic_data_from_oracle.attestation_timestamp    // timestamp of when this quote was created, 1729697539u128 in the current example
          }
        }
        ```

If you want to have more detailed guide on how to read information from the oracle mappings visit [How to use the oracle](./oracle_program.md#how-to-use-the-oracle).
