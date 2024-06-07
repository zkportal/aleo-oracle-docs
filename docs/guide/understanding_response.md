# Understanding Attestation Response

A successful Notarize call will return an Attestation Response, which we will break down here.

??? example "Example weather attestation response formatted as JSON"

    ```json
    --8<-- "example_weather_attestation.json"
    ```

For a developer, the most interesting parts of the response will be the Attestation Data and Oracle Data.

Attestation Data is the data that was extracted, attested and verified. You can use it in your Web2.0 app however you please. It will always be a string
in the response, as seen in the raw HTTP notarization response from the attestation target.

Oracle Data is an object that contains everything you need to use Attestation Data in an Aleo program.

## About encoding data for Aleo

In order to verify the Attestation Report about the data we needed a way to represent the Attestation Request and attestation results in Aleo programs
and classic programming languages. The Attestation results consist of Attestation Data, response status code, and attestation timestamp. From now on, the
Attestation Request + Attestation results combination will be called Report Data.

!!! warning "userData and Report Data"

    The report data is called `userData` in the SDK response! See [`OracleData.userData` in JS SDK](../sdk/js_api.md#type-oracledata) and [`OracleData.UserData` in Go SDK](../sdk/go_api.md#type-oracledata).

The Aleo program that uses it should be able to hash it and make asserts on certain properties while also taking the least amount of space.

Below is a type that is used in Aleo programs for using Report Data. It's called `ReportData` and it consists of 8 512-byte data chunks.

??? note "Leo definition of `ReportData`"

    ```leo linenums="1"
    // a 512-byte data chunk
    struct DataChunk {
        f0: u128,
        f1: u128,
        f2: u128,
        f3: u128,
        f4: u128,
        f5: u128,
        f6: u128,
        f7: u128,
        f8: u128,
        f9: u128,
        f10: u128,
        f11: u128,
        f12: u128,
        f13: u128,
        f14: u128,
        f15: u128,
        f16: u128,
        f17: u128,
        f18: u128,
        f19: u128,
        f20: u128,
        f21: u128,
        f22: u128,
        f23: u128,
        f24: u128,
        f25: u128,
        f26: u128,
        f27: u128,
        f28: u128,
        f29: u128,
        f30: u128,
        f31: u128
    }

    struct ReportData {
        c0: DataChunk,
        c1: DataChunk,
        c2: DataChunk,
        c3: DataChunk,
        c4: DataChunk,
        c5: DataChunk,
        c6: DataChunk,
        c7: DataChunk
    }
    ```

The backend serializes the Report Data to bytes. It follows a defined order of serializing properties, using a defined serializing method.

Then all useful properties are padded and aligned in a certain way so that they can be encoded into Aleo `u128`s where a property occupies at least one `u128`.

It means that a program will be able to use the properties of Report Data by accessing them using chunk and property numbers, e.g. `ReportData.c0.f2` -
the first chunk, the third property.

To help you find the positions of the different properties, the Report Data in the SDK will contain positional information in <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).[encodedPositions](../sdk/js_api.md#type-proofpositionalinfo)</code>. In our example, the Attestation Data in Aleo will
be in `ReportData.c0.f2`.

!!! note "Position of Attestation Data"

    See the [encoding documentation](./aleo_encoding.md#encoding-header) for the explanation of why it's in the third property of the first chunk.

    Depending on encoding options, the Attestation Data can take more than one property

The Oracle supports serializing Attestation Data, in a way that Aleo program could use it, in the following 3 ways:

- as a string
- as an integer
- as a floating point number

### Attestation Data as a string

To seriailze and encode Attestation Data as a string for Aleo, you set <code>[AttestationRequest](../sdk/js_api.md#type-attestationrequest).[encodingOptions](../sdk/js_api.md#type-encodingoptions).value</code> to `string`.

Since Aleo didn't support strings at the moment of development of the SDK, strings are serialized to bytes, split into chunks of 16 bytes,
then encoded into one or more 16-byte numbers - Aleo's `u128`.

!!! example "Encoding a string shorter than 16 bytes"

    Attestation Data: `"Hello, world!"`

    Bytes: `48 65 6c 6c 6f 2c 20 77 6f 72 6c 64 21`

    The bytes are padded with 0 to 16: `48 65 6c 6c 6f 2c 20 77 6f 72 6c 64 21 00 00 00`

    Interpreting the byte array as little endian representation of a 16-byte number: `2645608968347327576478451524936`

    `ReportData.c0.f2` will be `2645608968347327576478451524936u128`

!!! example "Encoding a string longer than 16 bytes"

    Attestation Data: `"Your balance: 1000000BTC"`

    Bytes: `59 6f 75 72 20 62 61 6c 61 6e 63 65 3a 20 31 30 30 30 30 30 30 42 54 43`

    The bytes are padded with 0 to 16: `59 6f 75 72 20 62 61 6c 61 6e 63 65 3a 20 31 30 30 30 30 30 30 42 54 43 00 00 00 00 00 00 00 00`

    Interpreting the byte array as little endian representation of two 16-byte numbers: `64058020007463102039520502111813332825 4851575473319194672`

    `ReportData.c0.f2` will be `64058020007463102039520502111813332825u128`.

    `ReportData.c0.f3` will be `4851575473319194672u128`.

Let's now look into using this encoded string in an Aleo program.

You can make asserts on single bytes, part of the string, or the whole string.

For the sake of simplicity, the following examples will not use `ReportData` struct just yet.

??? example "Make asserts on the whole string"

    It's as simple as comparing two numbers.

    ```leo linenums="1"
    program encoded_string_example.aleo {
        transition main(public input1: u128, public input2: u128) -> bool {
            // Assert that the text is "Your balance: 1000000BTC"
            assert_eq(input1, 64058020007463102039520502111813332825u128);
            assert_eq(input2, 4851575473319194672u128);
            return true;
        }
    }
    ```

    As input we will use the `"Hello, world!"` string encoded to `2645608968347327576478451524936u128`.

    ```bash
    $ leo run main 64058020007463102039520502111813332825u128 4851575473319194672u128
            Leo ✅ Compiled 'main.leo' into Aleo instructions

    Output true in 'encoded_string_example.aleo' is a literal, ensure this is intended
    ⛓  Constraints

    •  'encoded_string_example.aleo/main' - 6 constraints (called 1 time)

    ➡️  Output

    • true

            Leo ✅ Finished 'encoded_string_example.aleo/main'
    ```

??? example "Make asserts on single bytes"

    ```leo linenums="1"
    program encoded_string_example.aleo {
        inline get_nth_byte(num: u128, n: u32) -> u8 {
            let shift: u32 = n * 8u32;
            let shifted_number: u128 = num.shr(shift);
            let byte: u8 = (shifted_number & 255u128) as u8;
            return byte;
        }

        transition main(public input: u128) -> bool {
            let char0: u8 = get_nth_byte(input, 0u32);

            // ASCII code for "H" is 72
            assert_eq(char0, 72u8);
            return true;
        }
    }
    ```

    As input we will use the `"Hello, world!"` string encoded to `2645608968347327576478451524936u128`.

    ```bash
    $ leo run main 2645608968347327576478451524936u128
            Leo ✅ Compiled 'main.leo' into Aleo instructions

    Output true in 'encoded_string_example.aleo' is a literal, ensure this is intended
    ⛓  Constraints

    •  'encoded_string_example.aleo/main' - 3 constraints (called 1 time)

    ➡️  Output

    • true

            Leo ✅ Finished 'encoded_string_example.aleo/main'
    ```

??? example "Make asserts on a part of the text"

    For this example we will need to reconstruct a part of the string, then make it match the length of the input string,
    and use zeroes in place of the characters we are not interested in.

    Let's try to prove that the string `"Your balance: 1000000BTC"` contains the substring `"1000000"`. In this case we were unlucky because
    the string we want is split between two `u128`s.

    1. `u128` - <code>59 6f 75 72 20 62 61 6c 61 6e 63 65 3a 20 <mark>31 30</ma></code> - `64058020007463102039520502111813332825u128`.
    2. `u128` - <code><mark>30 30 30 30 30</mark> 42 54 43 00 00 00 00 00 00 00 00</code> - `4851575473319194672u128`.

    We're interested in the bytes highlighted in bold.

    We will construct 2 numbers that have those bytes in the same positions:

    1. <code>00 00 00 00 00 00 00 00 00 00 00 00 00 00 <mark>31 30</mark></code> - `64057366343744168453180733213588324352u128`
    2. <code><mark>30 30 30 30 30</mark> 00 00 00 00 00 00 00 00 00 00 00</code> - `206966894640u128`

    This is how we could use it in Leo

    ```leo linenums="1"
    program encoded_string_example.aleo {
        transition main(public input1: u128, public input2: u128) -> bool {
            // Assert that the text contains "1000000" in the last 2 bytes of input1 and the beginning of input2
            assert_eq(input1 & 64057366343744168453180733213588324352u128, 64057366343744168453180733213588324352u128);
            assert_eq(input2 & 206966894640u128, 206966894640u128);
            return true;
        }
    }
    ```

    ```bash
    $ leo run main 64058020007463102039520502111813332825u128 4851575473319194672u128
            Leo ✅ Compiled 'main.leo' into Aleo instructions

    Output true in 'encoded_string_example.aleo' is a literal, ensure this is intended
    ⛓  Constraints

    •  'encoded_string_example.aleo/main' - 6 constraints (called 1 time)

    ➡️  Output

    • true

            Leo ✅ Finished 'encoded_string_example.aleo/main'
    ```

### Attestation Data as an integer

To seriailze and encode Attestation Data for Aleo as an unsigned integer up to 64 bits in size, you set <code>[AttestationRequest](../sdk/js_api.md#type-attestationrequest).[encodingOptions](../sdk/js_api.md#type-encodingoptions).value</code> to `int`.

When working with numbers, they must be encoded in a way that makes them look the same in an Aleo program and in the Report Data in the SDK.

To give a more specific example, if the Attestation Data is a number "42", we want our Aleo program to be able to assert it as `ReportData.c0.f2 == 42u128`.

As a developer you don't need to do anything. When backend prepares <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).userData</code> that you see in the SDK response, it serializes the number as bytes in little-endian order and pads them to 16. Then the encoder turns those bytes into Aleo's `u128`,
which produces the same number you have in the SDK response.

!!! example

    SDK's example attestation response, where the irrelevant for this example properties were omitted:

    ```json hl_lines="2 5 9"
    [{
        "attestationData": "42"
        "attestationRequest": {
            "encodingOptions": {
                "value": "int",
            }
        }
        "oracleData": {
            "userData": "{  c0: {    f0: 83078176003060725451284209119789060u128,    f1: 4194512u128,    f2: 42u128,    f3: 1709730029u128, ..."
        }
    }]
    ```

    If you look at `userData`, you'll see that the encoded Attestation Data in `c0.f2` is `42u128`.

    It makes it very easy to use in Aleo programs.

    ```leo linenums="1"
    program meaning_of_life.aleo {
        transition main(answer: u128, public oracle_data: ReportData) -> u128 {
            assert(answer < oracle_data.c0.f2);

            return answer;
        }
    }
    ```

### AttestationData as a floating point number

To seriailze and encode Attestation Data for Aleo as an unsigned integer up to 64 bits in size, you set <code>[AttestationRequest](../sdk/js_api.md#type-attestationrequest).[encodingOptions](../sdk/js_api.md#type-encodingoptions).value</code> to `int`. This is the only encoding option where you also need to provide desired precision. See the [Guide to encoding options](./index.md#precision).

Not all floats can be encoded to an Aleo-compatible format at the moment.

The encoder implementation requires that the encoded value could be decoded to exactly the same floating point string as it was in the original Attestation Response.

When the backend encodes a floating point number, it first multiplies it by <code>10<sup>precision</sup></code> to get rid of the fractional part,
then it works the same as the integer encoding.

Let's take a look at our weather example again

!!! example

    SDK's example attestation response for the weather, where the irrelevant for this example properties were omitted:

    ```json hl_lines="2 5 10"
    [{
        "attestationData": "9.90"
        "attestationRequest": {
            "encodingOptions": {
                "value": "float",
                "precision": 2
            }
        }
        "oracleData": {
            "userData": "{  c0: {    f0: 83078176003060725451284209119789060u128,    f1: 4194512u128,    f2: 990u128,    f3: 1709730029u128, ..."
        }
    }]
    ```

    With precision 2, the `9.90` is encoded as `990u128`. With precision 4, the `9.90` is encoded as `99000u128`. With precision 1, the `9.90` is encoded as `99u128` etc.

    ```leo linenums="1"
    program is_heavy_rain.aleo {
        transition main(public oracle_data: ReportData) {
            assert(oracle_data.c0.f2 > 400u128);
        }
    }
    ```

## About Attestation Report

An Attestation Report is a report document about some data. The document is signed by the TEE enclave, and it contains additional information about the enclave such as
unique ID, signer ID, security information.

Verifying the Attestation Report provides assurances that the enclave running a specific version of source code, with some specific configuration. In case of Intel SGX,
the Intel corporation acts as a security collateral. They also provide a list of combinations of software and hardware and their security level.

In the SDK's response, the Attestation Report is encoded in the `attestationReport` using Base64 encoding. This report is verified by the verification backend during the SDK's
Notarize procedure. The verification backend makes asserts on the enclave unique ID during the verification - it uses the reproducibility of enclave build process to find the expected unique ID.

The Attestation Report can include up to 64 bytes of user data. In our case, the data is Aleo's Poseidon8 hash of serialized and formatted Report Data.

The Attestation Report is an array of bytes that doesn't need serialization but it still needs to be formatted into a type compatible with Aleo.

We are reusing the `DataChunk` type from the [beginning of this page](#about-encoding-data-for-aleo) and define the Attestation Report as `Report`.

```leo linenums="1"
struct Report {
    c0: DataChunk,
    c1: DataChunk,
    c2: DataChunk,
    c3: DataChunk,
    c4: DataChunk,
    c5: DataChunk,
    c6: DataChunk,
    c7: DataChunk,
    c8: DataChunk,
    c9: DataChunk
}
```

The 64 bytes of user data in the Report will be located in `Report.c0.f24`, `Report.c0.f25`, `Report.c0.f26`, and `Report.c0.f27`. The Poseidon8 hash of the user data is
only 16 bytes - one `u128`.

```leo linenums="1" hl_lines="3 5"
program verify_report.aleo {
    transition main(data: ReportData, report: Report) -> bool {
        let data_hash: u128 = Poseidon8::hash_to_u128(data);
        // verify that the hash of the data signed by TEE and is included in the report
        assert_eq(data_hash, report.c0.f24);
        assert_eq(0u128, report.c0.f25);
        assert_eq(0u128, report.c0.f26);
        assert_eq(0u128, report.c0.f27);

        return true;
    }
}
```

Here are some more enclave flags and properties you can use:

- `report.c0.f4` - CPU security version
- `report.c0.f6` - enclave extended product ID
- `report.c0.f7` - enclave attributes - a bitmask:
    - `assert_eq(report.c0.f7 & 1u128, 1u128)` - assert that the enclave was initialized
    - `assert_eq(report.c0.f7 & 2u128, 0u128)` - assert that the enclave is not in debug mode
    - `assert_eq(report.c0.f7 & 4u128, 4u128)` - assert that the enclave is in 64-bit mode
- `report.c0.f8`, `report.c0.f9` - enclave's unique ID
- `report.c0.12`, `report.c0.f13` - enclave's signer ID
- `report.c0.f20` - 2 bytes of product ID + 2 bytes of security version + 2 bytes of config security version + 10 bytes of zeroes
- `report.c0.f23` - enclave family ID
- `report.c0.f24`-`c0.f27` - 4 `u128` (64 bytes) of report data

See [Open Enclave SDK headers for SGX](https://github.com/openenclave/openenclave/blob/e9a0423e3a0b242bccbe0b5b576e88b640f88f85/include/openenclave/bits/sgx/sgxtypes.h#L1088) for more flags.

See Intel SGX and Open Enclave official documentation for more information.

### Verifying Attestation Report signature

The enclave Attestation Report from Intel SGX contains an ECDSA signature. At the moment Aleo doesn't support ECDSA signatures, and [uses Schnorr instead](https://developer.aleo.org/leo/language#signatures).

To work around that, the backend will be generating an Aleo private key on startup. This key is then used to sign the whole Attestation Report after it serialized and encoded for Aleo.

That way, the signature can be verified in an Aleo program.

In our weather attestation example you can find the signature in <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).signature</code>. The public key of the key that created the signature can be found in <code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).address</code>.

!!! example

    SDK's example attestation response for the weather, where the irrelevant for this example properties were omitted:

    ```json
    [
        {
            "timestamp": 1709730029,
            "oracleData": {
                "signature": "sign1x2kx7gssjd9a5davpazug4mj5k82634q5n4cha03akp734cwgsqwhrm4rfxpd4h6fpkz253v9yqp00s9fqpgpyfafcdjk08sy4fhvpps9fyug6x7nlr2ws0209uhsps4dv9g6998qnhc2g6f6vw4pug7qmefrdv65eg2d6v2lq2r5ezldy9rfgw2xrauwzfms3d5r793ldzsyjag5g2",
                "address": "aleo1jpz58re8eydtcmxr3s2gdp4cdtumuyumnnvf2mmwq6shllkhusgqn53vja",
            }
        }
    ]
    ```

This brings us to a full example of verifying the Attestation Report and Report Data.

???+ example

    ```leo linenums="1"
    program verify_report.aleo {
        function verify_report(data: ReportData, report: Report, sig: signature, pub_key: address) -> bool {
            let data_hash: u128 = Poseidon8::hash_to_u128(data);

            // https://github.com/openenclave/openenclave/blob/e9a0423e3a0b242bccbe0b5b576e88b640f88f85/include/openenclave/bits/sgx/sgxtypes.h#L1088
            // verify enclave flags
            // chunk 0 field 7 contains enclave flags
            let enclave_flags: u128 = report.c0.f7;
            assert_eq(enclave_flags & 1u128, 1u128); // enclave initted
            assert_eq(enclave_flags & 2u128, 0u128); // enclave is not in debug mode
            assert_eq(enclave_flags & 4u128, 4u128); // enclave is in 64-bit mode

            // verify that the hash of the data signed by TEE and is included in the report
            assert_eq(data_hash, report.c0.f24);
            assert_eq(0u128, report.c0.f25);
            assert_eq(0u128, report.c0.f26);
            assert_eq(0u128, report.c0.f27);

            let report_hash: u128 = Poseidon8::hash_to_u128(report);

            // verify that the report was signed by TEE
            return signature::verify(sig, pub_key, report_hash);
        }
    }
    ```

## About request hash

The oracle data contains an Encoded Request and an Encoded Request Hash. The Encoded Request is the same as the Report Data but
with the Attestation Data and Attestation Timestamp zeroed out. Attestation Data and Timestamp are the only parts of Report Data that can be different every time you perform notarization. By zeroing out these 2 fields, we can create a constant Report Data, which is going to represent a request to the attestation target.

<code>[AttestationResponse](../sdk/js_api.md#type-attestationresponse).[oracleData](../sdk/js_api.md#type-oracledata).encodedRequest</code>

When an Aleo program is going to verify that a request was done using the correct parameters,
like URL, Request Body, Request Headers etc., it can take the Report Data provided, replace the Attestation Data
and the Timestamp with `0u128` and then compare the result with the constant `UserData` in the program.

You can also hash it and, for example, compare it with the expected hash to make sure the data comes from attesting the target
with the desired parameters. When hashed, it's also easier to store in a mapping.

The Encoded Request Hash is created using Aleo's Poseidon8 hash as `u128`.

!!! example "Using Request Hash"

    ```leo linenums="1" hl_lines="9 10 42 52 58 60"
    program check_request.aleo {
        // assume that the hash is stored in key 0u8
        mapping expected_request_hash: u8 => u128;

        transition check_request(public report_data: ReportData) {
            let first_data_chunk: DataChunk = DataChunk {
                f0: report_data.c0.f0,
                f1: report_data.c0.f1,
                f2: 0u128,
                f3: 0u128,
                f4: report_data.c0.f4,
                f5: report_data.c0.f5,
                f6: report_data.c0.f6,
                f7: report_data.c0.f7,
                f8: report_data.c0.f8,
                f9: report_data.c0.f9,
                f10: report_data.c0.f10,
                f11: report_data.c0.f11,
                f12: report_data.c0.f12,
                f13: report_data.c0.f13,
                f14: report_data.c0.f14,
                f15: report_data.c0.f15,
                f16: report_data.c0.f16,
                f17: report_data.c0.f17,
                f18: report_data.c0.f18,
                f19: report_data.c0.f19,
                f20: report_data.c0.f20,
                f21: report_data.c0.f21,
                f22: report_data.c0.f22,
                f23: report_data.c0.f23,
                f24: report_data.c0.f24,
                f25: report_data.c0.f25,
                f26: report_data.c0.f26,
                f27: report_data.c0.f27,
                f28: report_data.c0.f28,
                f29: report_data.c0.f29,
                f30: report_data.c0.f30,
                f31: report_data.c0.f31,
            };

            let request_data: ReportData = ReportData {
                c0: first_data_chunk,
                c1: report_data.c1,
                c2: report_data.c2,
                c3: report_data.c3,
                c4: report_data.c4,
                c5: report_data.c5,
                c6: report_data.c6,
                c7: report_data.c7
            };

            let request_hash: u128 = Poseidon8::hash_to_u128(request_data);

            return then finalize(request_hash);
        }

        finalize check_request(public request_hash: u128) {
            let expected_request_hash: u128 = Mapping::get(0u8);

            assert_eq(request_hash, expected_request_hash);
        }
    }
    ```
