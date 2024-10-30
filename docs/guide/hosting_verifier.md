# Self-hosting Aleo Oracle verifier

[Verification backend :fontawesome-brands-github:]({{ variables.links.verification_backend_repo }})

At this moment the Aleo blockchain cannot natively verify our TEE reports. To allow for a transparent verification of the attested data we are making a backend available
for everyone to run and verify that each oracle update actually carries a valid TEE report. This does not require the user to have a TEE themselves.
As soon as Aleo is able to verify e.g. ECDSA signatures natively this will become superfluous.

## Prerequisites

- [Docker with compose](https://docs.docker.com/compose/) (**recommended**)

Or

- [EGo 1.5](https://docs.edgeless.systems/ego/)
- [Docker](https://docs.docker.com/engine/install/)
- [Quote provider](https://docs.edgeless.systems/ego/reference/attest#set-up-the-quote-provider)
- *Optionally* Node.js `18.17.0`-`18.19.1`, `20.0.0`-`20.11.1`, or `21.0.0`-`21.5.0`

!!! tip "Hosting your own PCCS"

    If you choose to host your own PCCS, make sure that it uses at least [DCAP 1.19](https://github.com/intel/SGXDataCenterAttestationPrimitives/releases/tag/DCAP_1.19).

## Running in Docker

In the repository you will find a `docker-compose.yml` file. Set `API_KEY` environment variable for `pccs` service.

!!! info "Get an API key for PCCS"

    To get your free API key, go to [Intel® Provisioning Certification Service for ECDSA Attestation](https://api.portal.trustedservices.intel.com/provisioning-certification), create an account and click on "Subscribe".

You can optionally also set `ADMINPASS` environment variable if you're planning to use administrative endpoints or [Intel® SGX Pccs Admin Tool](https://github.com/intel/SGXDataCenterAttestationPrimitives/blob/main/tools/PccsAdminTool/README.txt).

Adjust the configuration in `config.json` (See the [Configuration section](#configuration) below) before building the containers

```bash
docker compose build
```

then start them with

```bash
docker compose up -d
```

You can also change the config after you build the images, you just need to mount `config.json` to `/app/config.json` in the `verification-backend` service.

## Configuration

The program looks for `config.json` in the working directory.

| Key | Description | Required |
| --- | --- | --- |
| `port` | The port to bind to for the HTTP server | yes |
| `useTls` | Enable HTTPS for the server. Makes `tlsKey` and `tlsCert` required. | no |
| `tlsKey` | Path to the PEM certificate key for HTTPS. | depends on `useTls` |
| `tlsCert` | Path to the PEM certificate for HTTPS. | depends on `useTls` |
| `uniqueIdTarget` | Target SGX enclave unique ID as returned by [`get-enclave.id.sh`](https://github.com/zkportal/oracle-verification-backend/blob/main/get-enclave-id.sh) - 32-byte hex or base64 string | no |
| `pcrValuesTarget` | Target Nitro enclave PCR values as returned by [`get-enclave.id.sh`](https://github.com/zkportal/oracle-verification-backend/blob/main/get-enclave-id.sh) - an array of 3 48-byte hex or base64 strings | no |
| `liveCheck` | Configuration object for querying a live Aleo program's unique ID assertion | yes |

`liveCheck` configuration object:

| Key | Description |
| --- | --- |
| `skip` | If true, then will use the enclave measurements from the reproducible build or the configuration, and will not query the deployed program |
| `apiBaseUrl` | Base URL for Aleo node API |
| `contractName` | Aleo program that has `sgx_unique_id` and `nitro_pcr_values` mappings with the enclave measurements stored at keys `0u8`. |

## Setting up the target enclave measurements

When decoding and verifying enclave reports, this backend will compare the report's enclave measurements with the configured target measurements.
This means that this backend will be asserting the source code and configuration of the enclave that produced the report, thus verifying the code running in the Oracle backend enclave.

The target enclave measurements are cross-checked using two sources: the reproducible build of the Oracle backend and the configured measurements in an Aleo program that will be using the reports.

Reproducing a build of the Oracle backend ensures that the report-producing enclave is running the exact source code version this backend expects.

Aleo programs that utilize attestations from the Oracle need to perform certain assertions on an attestation and its report.
One of the assertions verifies the measurements of the enclave. By querying the enclave measurements from the program,
this backend ensures that the program is aware of the Oracle backend's current source code version and that it will be able to accept a report from it,
given that all other assertions pass.

### Query the notarizers for their enclave measurements

You can choose to verify the currently running default notarization backend. You can query `https://sgx.aleooracle.xyz/info` to get an SGX enclave measurement (unique ID):

```json
{
  "reportType": "sgx",
  "info": {
    "securityVersion": 1,
    "debug": false,
    "uniqueId": "RGpRmz/zATF9erKm0HQFGHjCPDRbP4XnbbxpFBMJq/w=",
    "signerId": "9H4s7YPOeZFug8XZRRRlc+Z7Vfit98IfkZsrDpb+Dxs=",
    "productId": "AQAAAAAAAAAAAAAAAAAAAA==",
    "aleoProductId": "1u128",
    "aleo": {
      "uniqueId": "{ chunk_1: 31929802673692760512905395015836068420u128, chunk_2: 335853521753947303372057454886636012152u128 }",
      "signerId": "{ chunk_1: 153386052680309655679396867527014121204u128, chunk_2: 35972203959719964238382729092704599014u128 }",
      "productId": "1u128",
    },
    "tcbStatus": 5
  },
  "signerPubKey": "aleo1skjdmt9s743jlgf378n38hud4jdnmf4tafsymsj8ta2hqmcc5qxqeuersv"
}
```

or query `https://nitro.aleooracle.xyz/info` to get the Nitro enclave measurements (PCR values):

```json
{
  "reportType": "nitro",
  "info": {
    "document": {
      "moduleID": "i-02dd0abe215ecea89-enc0191d5d43e5aa019",
      "timestamp": 1725869343469,
      "digest": "SHA384",
      "pcrs": {
        "0": "ifZLGoqBQ0TW/ngrKDUr19ax+HWFDb44GlIkKBuvcczPfBLO6bkhrTlOD3owImfg",
        "1": "A0OwVs2Ehcp4kN3YM0dteEYK7SqhYVSOTia+3zIXJmliV9Yj6IBfP2BZRrPYsMaq",
        "10": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "11": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "12": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "13": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "14": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "15": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "2": "EeFmnkqglQNR4pz7vla+0hDxl8AV3Hlb+ZyAVhkIloavkDQQxB5cJWJRbxdaixyl",
        "3": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "4": "aWOA5bTYYZ2R/C3qV+cV8017AqJAoCCxEGDeDXi9E7WozprebberstZz1d6ylbIA",
        "5": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "6": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "7": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "8": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
        "9": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
      },
      "certificate": "MIICfDCCAgOgAwIBAgIQAZHV1D5aoBkAAAAAZt6tHzAKBggqhkjOPQQDAzCBjzELMAkGA1UEBhMCVVMxEzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxDzANBgNVBAoMBkFtYXpvbjEMMAoGA1UECwwDQVdTMTowOAYDVQQDDDFpLTAyZGQwYWJlMjE1ZWNlYTg5LmFwLXNvdXRoLTIuYXdzLm5pdHJvLWVuY2xhdmVzMB4XDTI0MDkwOTA4MDkwMFoXDTI0MDkwOTExMDkwM1owgZQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApXYXNoaW5ndG9uMRAwDgYDVQQHDAdTZWF0dGxlMQ8wDQYDVQQKDAZBbWF6b24xDDAKBgNVBAsMA0FXUzE/MD0GA1UEAww2aS0wMmRkMGFiZTIxNWVjZWE4OS1lbmMwMTkxZDVkNDNlNWFhMDE5LmFwLXNvdXRoLTIuYXdzMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE6LkkDc1D0GRa/nuEIoQT4UqAzJUKGTUl9edj6s/MrpbjI5QeQJMbk4TV1Fmg9JssMpMB8qIKM2VNhpT9nXxqN8OLQTIynNoRZO32poYiYRQfjQ1ubqja/aRZTuS4MBSHox0wGzAMBgNVHRMBAf8EAjAAMAsGA1UdDwQEAwIGwDAKBggqhkjOPQQDAwNnADBkAjADNBy1odTkagfiiXi0pTcHkntzcFxyD/kFR4sGrMBp9AvBymz+xNzqdZ5Ng8NZGPMCMBfdRYLQoKGgmSWNB2LPa9M3PwQMq9Pv56KIEGy3bsW3vmjiEck6K/Iiora7Ty61qw==",
      "cabundle": [
        "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"
      ],
      "userData": "AAAAAAAAAAAAAAAAAAAAAA==",
      "nonce": "4UIy4LD0MRgF3RHuvzHQSr7du7kDvNLHwe9d95joyO4="
    },
    "protectedCose": "oQE4Ig==",
    "signature": "Z3a7keF4QSwfvejH6zfe4UJ8R6ediSAH2fnEe0DCrBmwajHHPi9eGfmLDDm0hlK6OtYLqqjbVrWUKnjlAEfJNUaRMxiZFs596hEWjV0OijnMrzgjbKENrfV6nkG+tCwL",
    "aleo": {
      "pcrs": "{ pcr_0_chunk_1: 286008366008963534325731694016530740873u128, pcr_0_chunk_2: 271752792258401609961977483182250439126u128, pcr_0_chunk_3: 298282571074904242111697892033804008655u128, pcr_1_chunk_1: 160074764010604965432569395010350367491u128, pcr_1_chunk_2: 139766717364114533801335576914874403398u128, pcr_1_chunk_3: 227000420934281803670652481542768973666u128, pcr_2_chunk_1: 280126174936401140955388060905840763153u128, pcr_2_chunk_2: 178895560230711037821910043922200523024u128, pcr_2_chunk_3: 219470830009272358382732583518915039407u128 }",
      "userData": "0u128"
    }
  },
  "signerPubKey": "aleo1l4xyshuw6mvpxdx35cws7djlnemwranp4s8acgdm9k8ev5u9ugzsfklmqq"
}
```

Use the `info.uniqueId` and `info.document.pcrs` 0-2 in the configuration file.

```bash
curl -s https://sgx.aleooracle.xyz/info -q | jq -r '.info.uniqueId'
curl -s https://nitro.aleooracle.xyz/info -q | jq -r '.info.document.pcrs["0"], .info.document.pcrs["1"], .info.document.pcrs["2"]'
```

### Reproducible build

You can get the reproducible enclave measurements of the Oracle backend by running  `get-enclave-id.sh`. Use `./get-enclave-id.sh -h` to get help.

The script will download the root CA certificate bundle and Oracle backend source code, then build an enclave (see script's help message for requirements).

The script can be configured with the following environment variables:

| Variable | Description | Default value |
| :------: | :---------: | :-----------: |
| `TEMP_WD` | A temporary working directory, where the script will be downloading files. It will be deleted automatically. | A random directory in the current working directory. |
| `CA_CERT_DATE` | CA file revisions per date of appearance as found at https://curl.se/docs/caextract.html | `2024-07-02` |
| `ORACLE_REVISION` | Git branch, or commit hash, or tag of Oracle backend to use for reproducible build | `main` |

The produced output is:

```
...
Oracle SGX unique ID:
<unique ID>
...
Oracle Nitro PCR:
<PCR0>
<PCR1>
<PCR2>
```

Use these values in `config.json` to configure the target unique ID and the target PCR values. If the configuration file doesn't have either the target unique ID or the PCR values configured, this backend will itself run the script. The same environment variables can be passed to the backend; the script will inherit the environment.

### Aleo program's configured enclave measurements

If the live check in the configuration is not skipped,
this backend will query an Aleo node for the configured Aleo program and
get the unique ID and PCR values that the program uses for enclave measurements assertions on the enclave reports.

The querying is done once at startup. If the obtained unique ID doesn't match the unique ID from the reproducible build, the backend will exit with an error.
If the obtained PCR values don't match the PCR values from the reproducible build, the backend will exit with an error.

Use the configuration [`liveCheck.skip`](#configuration) to skip comparing the report enclave measurements with the ones stored in the Oracle program.

## Building and running

If [EGo is installed with snap](https://snapcraft.io/ego-dev), run with:

`EGOPATH=/snap/ego-dev/current/opt/ego CGO_CFLAGS=-I$EGOPATH/include CGO_LDFLAGS=-L$EGOPATH/lib go run main.go`

If [EGo is installed from a deb package](https://github.com/edgelesssys/ego/releases), run with:

`CGO_CFLAGS=-I/opt/ego/include CGO_LDFLAGS=-L/opt/ego/lib go run main.go`

Each update on the blockchain carries also the report attesting to the data. Therefore, all data that is required to check the origin and security of the oracle data can be obtained via the blockchain.
E.g. from `https://explorer.aleo.org/transaction/<transactionId>`

## Backend information

### /info

Returns some basic information about the backend configuration. Includes the target enclave unique ID for verification (in different encoding),
the name of the Aleo program to query for the unique ID, and the time and date of the backend launch.

Method: **GET**

Response headers:

  - `Content-Type: application/json`

Response body:

```json
{
  "targetUniqueId": {
    "hexEncoded": "",
    "base64Encoded": "",
    "aleoEncoded": ""
  },
  "targetPcrValues": {
    "hexEncoded": ["", "", ""],
    "base64Encoded": ["", "", ""],
    "aleoEncoded": ""
  },
  "liveCheckProgram": "",
  "startTimeUTC": ""
}
```

<details>
  <summary><b>Example response</b></summary>

  ```json
  {
    "targetUniqueId": {
      "hexEncoded": "446a519b3ff301317d7ab2a6d074051878c23c345b3f85e76dbc69141309abfc",
      "base64Encoded": "RGpRmz/zATF9erKm0HQFGHjCPDRbP4XnbbxpFBMJq/w=",
      "aleoEncoded": "{ chunk_1: 31929802673692760512905395015836068420u128, chunk_2: 335853521753947303372057454886636012152u128 }"
    },
    "targetPcrValues": {
      "hexEncoded": [
        "89f64b1a8a814344d6fe782b28352bd7d6b1f875850dbe381a5224281baf71cccf7c12cee9b921ad394e0f7a302267e0",
        "0343b056cd8485ca7890ddd833476d78460aed2aa161548e4e26bedf321726696257d623e8805f3f605946b3d8b0c6aa",
        "11e1669e4aa0950351e29cfbbe56bed210f197c015dc795bf99c805619089686af903410c41e5c2562516f175a8b1ca5"
      ],
      "base64Encoded": [
        "ifZLGoqBQ0TW/ngrKDUr19ax+HWFDb44GlIkKBuvcczPfBLO6bkhrTlOD3owImfg",
        "A0OwVs2Ehcp4kN3YM0dteEYK7SqhYVSOTia+3zIXJmliV9Yj6IBfP2BZRrPYsMaq",
        "EeFmnkqglQNR4pz7vla+0hDxl8AV3Hlb+ZyAVhkIloavkDQQxB5cJWJRbxdaixyl"
      ],
      "aleoEncoded": "{ pcr_0_chunk_1: 286008366008963534325731694016530740873u128, pcr_0_chunk_2: 271752792258401609961977483182250439126u128, pcr_0_chunk_3: 298282571074904242111697892033804008655u128, pcr_1_chunk_1: 160074764010604965432569395010350367491u128, pcr_1_chunk_2: 139766717364114533801335576914874403398u128, pcr_1_chunk_3: 227000420934281803670652481542768973666u128, pcr_2_chunk_1: 280126174936401140955388060905840763153u128, pcr_2_chunk_2: 178895560230711037821910043922200523024u128, pcr_2_chunk_3: 219470830009272358382732583518915039407u128 }"
    },
    "liveCheckProgram": "official_oracle.aleo",
    "startTimeUTC": "2024-04-23 18:35:21"
  }
  ```
</details>

## Decoding report data from Leo contracts

### /decode

Method: **POST**

Request headers:
  - `Content-Type: application/json`

Request body:

```json
{
  "userData": "struct ReportData Leo value",
}
```

<details>
  <summary><b>Example request</b></summary>

  ```json
  {
    "userData": "{  c0: {    f0: 83078175999433947992440321595670532u128,    f1: 4194512u128,    f2: 0u128,    f3: 1703169427u128,    f4: 200u128,    f5: 146741781957618190040822128409835696737u128,    f6: 152036601506766190083586533414400257325u128,    f7: 68109414375938033788076837889450272867u128,    f8: 134773639525141431732596543682390863416u128,    f9: 133418429601737771259984878976133183293u128,    f10: 134450312385956222643437753982911870049u128,    f11: 60070679775571722300437058720291054702u128,    f12: 156118725222190617104317614334339854642u128,    f13: 109u128,    f14: 121200813359967904192723595955179970916u128,    f15: 23856u128,    f16: 0u128,    f17: 5522759u128,    f18: 36893488147419103234u128,    f19: 221360928884514619396u128,    f20: 13055389343712134841237569546u128,    f21: 13856407623565317u128,    f22: 156035770564570580066107481452631621659u128,    f23: 3900269670161044694030315513202u128,    f24: 162743726813863731210145153184655802480u128,    f25: 101188681738744639914108759155086748777u128,    f26: 149456393680743922584091041160660086377u128,    f27: 42816717959947032433996830433837802860u128,    f28: 132119436183189587630719372684727700264u128,    f29: 64042929165508395635299690384626118507u128,    f30: 61431102749981217983499061483759611950u128,    f31: 13875u128  },  c1: {    f0: 55340232221128654848u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c2: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c3: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c4: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c5: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c6: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c7: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  }}"
  }
  ```
</details>

Response headers:

  - `Content-Type: application/json`

Response body:

> **Note:** depending on the `success` value, either `decodedData` or `errorString` exist.
>
> In `decodedData`, properties `htmlResultType`, `requestBody`, and `requestContentType` are optional strings.

For more information on `decodedData` properties, see documentation for `AttestationResponse` in the [Aleo Oracle documentation](https://docs.aleooracle.xyz/guide/aleo_encoding/).

```json
{
  "decodedData": {
    "url": "",
    "requestMethod": "",
    "selector": "",
    "responseFormat": "",
    "requestHeaders": {
      "Header name": ""
    },
    "encodingOptions": {
      "value": "",
      "precision": 0
    },
    "htmlResultType": null,
    "requestBody": null,
    "requestContentType": null,
    "attestationData": "",
    "responseStatusCode": 200,
    "timestamp": 0
  },
  "success": true,
  "errorString": ""
}
```

<details>
  <summary><b>Example response</b></summary>

  ```json
  {
    "decodedData": {
      "url": "archive-api.open-meteo.com/v1/archive?latitude=38.9072&longitude=77.0369&start_date=2023-11-20&end_date=2023-11-21&daily=rain_sum",
      "requestMethod": "GET",
      "selector": "daily.rain_sum.[0]",
      "responseFormat": "json",
      "requestHeaders": {
        "Accept": "*/*",
        "DNT": "1",
        "Upgrade-Insecure-Requests": "1",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
      },
      "encodingOptions": {
        "value": "float",
        "precision": 2
      },
      "attestationData": "0.00",
      "responseStatusCode": 200,
      "timestamp": 1703169427
    },
    "success": true
  }
  ```
</details>

## Decoding and verifying report from Leo contracts

### /decodeReport

Method: **POST**

Request headers:
  - `Content-Type: application/json`

Request body:

```json
{
  "userData": "struct ReportData Leo value",
  "report": "struct Report Leo value"
}
```

<details>
<summary><b>Example request SGX</b></summary>

```json
{
  "userData": "{  c0: {    f0: 83078175999433947992440321595670532u128,    f1: 4194512u128,    f2: 0u128,    f3: 1703169427u128,    f4: 200u128,    f5: 146741781957618190040822128409835696737u128,    f6: 152036601506766190083586533414400257325u128,    f7: 68109414375938033788076837889450272867u128,    f8: 134773639525141431732596543682390863416u128,    f9: 133418429601737771259984878976133183293u128,    f10: 134450312385956222643437753982911870049u128,    f11: 60070679775571722300437058720291054702u128,    f12: 156118725222190617104317614334339854642u128,    f13: 109u128,    f14: 121200813359967904192723595955179970916u128,    f15: 23856u128,    f16: 0u128,    f17: 5522759u128,    f18: 36893488147419103234u128,    f19: 221360928884514619396u128,    f20: 13055389343712134841237569546u128,    f21: 13856407623565317u128,    f22: 156035770564570580066107481452631621659u128,    f23: 3900269670161044694030315513202u128,    f24: 162743726813863731210145153184655802480u128,    f25: 101188681738744639914108759155086748777u128,    f26: 149456393680743922584091041160660086377u128,    f27: 42816717959947032433996830433837802860u128,    f28: 132119436183189587630719372684727700264u128,    f29: 64042929165508395635299690384626118507u128,    f30: 61431102749981217983499061483759611950u128,    f31: 13875u128  },  c1: {    f0: 55340232221128654848u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c2: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c3: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c4: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c5: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c6: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c7: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  }}",
  "report": "{  c0: {    f0: 84855022739072527368193u128,    f1: 68385684764540665893611210958203650051u128,    f2: 242957950407643292263866366603922545911u128,    f3: 54648694067525505081604253854u128,    f4: 4082482497131797u128,    f5: 0u128,    f6: 0u128,    f7: 129127208515966861317u128,    f8: 67815920917700628759894811536473776728u128,    f9: 296690334406880757170225743286084577448u128,    f10: 0u128,    f11: 0u128,    f12: 153386052680309655679396867527014121204u128,    f13: 35972203959719964238382729092704599014u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 65537u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 194013037706606810471497707607567229514u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 293945546687975317560007689180664565828u128,    f29: 101319798806644299615994827200106732599u128,    f30: 288683837040491329007131885304923575713u128,    f31: 238936716134995001169573561693266943356u128  },  c1: {    f0: 117891055671150134937207207400070557u128,    f1: 327718390601232644976585669983462482511u128,    f2: 24330412716767774705623998119162324926u128,    f3: 138829435947332207818351983315511379419u128,    f4: 17534128811673485667330409u128,    f5: 0u128,    f6: 0u128,    f7: 554597137599850363245001965568u128,    f8: 51321760518872024617203618802506399744u128,    f9: 67728825339782400665172072549140061414u128,    f10: 3840007777u128,    f11: 0u128,    f12: 158837950468731255509735392413912924160u128,    f13: 90434782647414738426891946114991426246u128,    f14: 4286301584u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 2814754062073856u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 324754746029249963345795058866300387328u128,    f25: 262713569315817736053191240715644376071u128,    f26: 396987308u128,    f27: 0u128,    f28: 78783906986389290480429594716028272640u128,    f29: 47301204985573259198668388599829551565u128,    f30: 251573817981916842221204028300955393688u128,    f31: 60931249114056217298477870875766339282u128  },  c2: {    f0: 12004732790720997080891679054109673372u128,    f1: 33355783264191645768789692391696894730u128,    f2: 60049829442654824440068874493786594074u128,    f3: 86749189800108151757823289210582680109u128,    f4: 89408317962157473941141852435021382996u128,    f5: 116247298448171836707225814442806559810u128,    f6: 153298516702326844018032793253697894448u128,    f7: 97503207721845674876966991394193684528u128,    f8: 92066185763862219525981875178096847482u128,    f9: 158631690561421924035459988786500419911u128,    f10: 76333970513925110025764547352733963623u128,    f11: 86951652772898462981681034850997918314u128,    f12: 94896799011537378893460037220868506201u128,    f13: 116147467564052018692635533112133645142u128,    f14: 86754362688545102779307753469975033145u128,    f15: 112119725805968183605533498525349401716u128,    f16: 108017770325421329463318335114491808837u128,    f17: 86837782966952094203466333913022481712u128,    f18: 104299154292433981337878436150804502124u128,    f19: 102970007423461191398703387622748865914u128,    f20: 158756673053749662613813693058116962644u128,    f21: 120250821724838927997570695467201021027u128,    f22: 90731620886030983844249335288351250259u128,    f23: 64167425784331583248880956763149597011u128,    f24: 158714297810016602898334694321548514394u128,    f25: 76136666399556079529596080858030625618u128,    f26: 104215935482822920403569083451176409465u128,    f27: 104039541035603526609816581170645779030u128,    f28: 108114213427665675835456091415639513459u128,    f29: 65471119637970862968276758529751402833u128,    f30: 137254884056849384459604142725565400405u128,    f31: 142769694527016630226411770057918542179u128  },  c3: {    f0: 89112578245003088838611936818941153130u128,    f1: 112186499542433954375491037642502208106u128,    f2: 90784520335163547732013059839169092170u128,    f3: 88098580733429188304785517654213749060u128,    f4: 13818678782623848242017603879574981974u128,    f5: 147820478781135256057168735290326086470u128,    f6: 158601004626878902877599539347155414609u128,    f7: 113324135867913542756083826620225910600u128,    f8: 74972654877031102216601080268178673456u128,    f9: 118640788039913225795845957010654258442u128,    f10: 57522524206617649377895238896809301572u128,    f11: 76395809444991429016706081744091699303u128,    f12: 104055463043983720312313305835522974568u128,    f13: 94896799018974010676587692096514886252u128,    f14: 66925915710382479181304097458923270998u128,    f15: 140080186552622183050687868903337785686u128,    f16: 66924476944912156571061685914505720377u128,    f17: 98992299697508934570972255816522545477u128,    f18: 132156009718758105502505635427965556333u128,    f19: 161279583780376529355820241584231039338u128,    f20: 86988240499279864031395599405181786217u128,    f21: 90851712646405306649273966649867921772u128,    f22: 86910759077318896229532865192996655702u128,    f23: 89481269114107147013099085316803215693u128,    f24: 94922557363533324889281353390439350605u128,    f25: 97414248676890686064111993804100224299u128,    f26: 64162090082353134852911296187142010690u128,    f27: 68061606517752099038461575957851489346u128,    f28: 97414252019350595078397302451144248628u128,    f29: 108006557258706241659985402300131793474u128,    f30: 147935278331152620242894529988311204400u128,    f31: 109335559370310372277484484735535696218u128  },  c4: {    f0: 108006557258706241659985474927626385237u128,    f1: 100088524550901356562081163050370548272u128,    f2: 86749273541778128252673674470155180655u128,    f3: 86806937632782324422938379499129489745u128,    f4: 100088524550901337654184547093126983761u128,    f5: 89501715209068986181232175188938414703u128,    f6: 104222184131274927152875686304401412417u128,    f7: 94714031756334156656567492352616190273u128,    f8: 96085101416419075191047717346100738371u128,    f9: 130645070357909842285010588752337528641u128,    f10: 86744078235532168310844955291706020916u128,    f11: 97455544295713879545243905514477798215u128,    f12: 130645070357909843409829925202292064586u128,    f13: 88130178435234664984192167563704226868u128,    f14: 108006554474245330756093469187236906817u128,    f15: 97466053372950493505749323473483811913u128,    f16: 88130178435234981346425003090388464738u128,    f17: 86806224810738141373754240919543170881u128,    f18: 110696878246818504645480466692776544593u128,    f19: 102689462638219053953715929901094429257u128,    f20: 86806224810789133026584909959423017282u128,    f21: 94964376728773384814305555424564234577u128,    f22: 86760182472435095491075972571471169875u128,    f23: 104039701701017929686387466547358679629u128,    f24: 94964376747633841451467273574021681473u128,    f25: 86743850775774187631488817526718220627u128,    f26: 86738642548474510552846856696003380822u128,    f27: 130645070357890500596716091135427166529u128,    f28: 108011726166852882164521742062605915188u128,    f29: 108005175979728448444544556956631253831u128,    f30: 137254802922232358469698402495009801553u128,    f31: 137259792715934442779251126941000429935u128  },  c5: {    f0: 86743671559825713225810936288001212741u128,    f1: 65185195345608567120154475649334068045u128,    f2: 65357457586765783080977191293115922537u128,    f3: 86998423942360155305591100450693936961u128,    f4: 154472602469542241641585002430073029429u128,    f5: 13549021765187881145134586349375603269u128,    f6: 152073519918233207828023866234766653003u128,    f7: 104038968442143258462312395470080267333u128,    f8: 60049831370206298086862839912815861828u128,    f9: 92065270838263588161724692358245264685u128,    f10: 102403394931704788846174182320797996114u128,    f11: 86744001382976538097282952900259301705u128,    f12: 110935596339372355082162529425482467687u128,    f13: 102757753904718435832159428816450184530u128,    f14: 13641730763236203195338302233747353409u128,    f15: 102751686145939161927243829626473498445u128,    f16: 110669981079482448319058586804081677637u128,    f17: 90850942152570950481689628423833072226u128,    f18: 90731562025364983292125121457312321878u128,    f19: 92269112234738910460234604810152927754u128,    f20: 93307304611000405257194885735877070165u128,    f21: 87034648393070435116482161781592515701u128,    f22: 153283362559674347752342369129799828042u128,    f23: 162608910905757605780267968350111599223u128,    f24: 90789749960275843698637110143409874241u128,    f25: 141298973437060242123296827944779741013u128,    f26: 162547292534704897884193116506469267525u128,    f27: 133532497310657633341072149250505861185u128,    f28: 113521522523369678774676020478138865223u128,    f29: 102694834785533074997134942172914010696u128,    f30: 130649998573320348463870441913035747154u128,    f31: 138624983733330959992385555618662732398u128  },  c6: {    f0: 92159075952097798322699461462172911460u128,    f1: 138863807754577485370649275968502855490u128,    f2: 102886685864261067444504776195468258659u128,    f3: 108089793406502879224265658521229355841u128,    f4: 150832375731722087451752855924366591303u128,    f5: 69521351739172570572808364160782783303u128,    f6: 102756435944532396704924302022142279993u128,    f7: 120084626246215828157538855856678449776u128,    f8: 153391974005147988715650772534534875957u128,    f9: 86837725691842740968865538395725325867u128,    f10: 68198029715524678187548970722900193876u128,    f11: 151917789119366573768094736235530178167u128,    f12: 114668498408916468643246581063172640578u128,    f13: 65533711314949557364595280228358172754u128,    f14: 94796928902038869219176506719306281324u128,    f15: 135832155811633629464337931991323143034u128,    f16: 88197415573835596094480142823048037698u128,    f17: 64188965780662179399672137617773840481u128,    f18: 65517870053603420032645768010385741665u128,    f19: 114575036516425533478059638766758409059u128,    f20: 76198953448334894703426641276428962938u128,    f21: 109263499842199640047903063019382268490u128,    f22: 64230461842459213854876536461822480708u128,    f23: 62729141095620952142801360698998932047u128,    f24: 143849141874647537468077485084531455339u128,    f25: 158423513593444577201225835437018140268u128,    f26: 109372291527157337602447472214371550545u128,    f27: 86645324449472246601531337146191921741u128,    f28: 88026069454382460688250206663376717159u128,    f29: 137296078894976326897348732728908139841u128,    f30: 117311701563535690054873511157550047828u128,    f31: 94621683947702260380930330556642702925u128  },  c7: {    f0: 157266585692263169432748518083816618295u128,    f1: 86677348170789000027156131147443557186u128,    f2: 162521268531709082938246788278115119159u128,    f3: 104038968442143258459157865742129909300u128,    f4: 60049831370206298086862839912815861828u128,    f5: 92065270838263588161724692358245264685u128,    f6: 102403394931704788846174182320797996114u128,    f7: 86744001382976675045910956351848401225u128,    f8: 137546180655561108076056018404869753191u128,    f9: 89678581623839706670222579498013315895u128,    f10: 13911653348267379143928883463380883815u128,    f11: 109616997758559601014350933934427423841u128,    f12: 157234559050145056110467932273002239827u128,    f13: 114720701137339631629859795251332461410u128,    f14: 157255307963199385955327972200009384258u128,    f15: 108094807033958817984488532228539573002u128,    f16: 70902625428892611236952963291692877175u128,    f17: 142566462633127032433531710020361869616u128,    f18: 87034648392996604956291596012756222279u128,    f19: 88130565149443671870324176594388781642u128,    f20: 90794921967916445037846635642051909684u128,    f21: 112057438767757703995190256887814518869u128,    f22: 88130827461549207523091912353999911497u128,    f23: 119880831756198184460899244703266522983u128,    f24: 108203921181293991924616096290221553495u128,    f25: 92118795085093294238435397575365903664u128,    f26: 132207609996927537498699975159394430037u128,    f27: 90851712725643296445717670572126652013u128,    f28: 90731885812260910872707057926404133206u128,    f29: 92159075952138897077551333410263680866u128,    f30: 114720701132697431966616368839344472387u128,    f31: 118920583898637034375179436867628646722u128  },  c8: {    f0: 120208391563958328903418431752285145928u128,    f1: 146496827975129713628545140622596143689u128,    f2: 162516038770122090537536818276459181893u128,    f3: 116184260795578461401620612162842740065u128,    f4: 97300828021546254909120508427600292423u128,    f5: 118931901008424116384729958666790529898u128,    f6: 100036301301652645797615676665268169834u128,    f7: 88259985781804142268996583522069936693u128,    f8: 120177358927007647960329552767271456359u128,    f9: 157281614327971246846144182102493985361u128,    f10: 96152543435324426254685485864430223665u128,    f11: 90732169228477843146456407899029977170u128,    f12: 143962642878211164384679925272543652712u128,    f13: 64080597579852368723578581181397102179u128,    f14: 141461154356937785131350677709217230435u128,    f15: 76027425043751003220509970687738075226u128,    f16: 76333687204450208078758577613038439540u128,    f17: 104215936829747759056653563243130086518u128,    f18: 150764531549494692607960815007211538518u128,    f19: 162536115989282966984643484707285716580u128,    f20: 108006593375585103515344389694009011819u128,    f21: 65471116944522798882642801786913697608u128,    f22: 135920100576416446773842260002668373077u128,    f23: 162546687390846958021578236361531540280u128,    f24: 86941307401230900785174445205576036458u128,    f25: 104195206872586117789496688062422275919u128,    f26: 73654539828148610787525649008678104943u128,    f27: 86760223015317314675068160783488144199u128,    f28: 153107513048634507624915175849216461364u128,    f29: 133334437843788124256415413717389227608u128,    f30: 60049826688636443598812574127591215442u128,    f31: 111994015668589605791723790244161858861u128  },  c9: {    f0: 2864421821820229u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  }}"}
```
</details>

<details>
<summary><b>Example request Nitro</b></summary>

```json
{
    "userData": "{  c0: {    f0: 83077145937816122806495900722528270u128,    f1: 4194320u128,    f2: 5940801000000u128,    f3: 1725008028u128,    f4: 200u128,    f5: 63041935364884317995582503489240658017u128,    f6: 152114491104286018974290347557927874657u128,    f7: 110768634480232840853030308057786442601u128,    f8: 17220u128,    f9: 435459551856u128,    f10: 0u128,    f11: 5522759u128,    f12: 147573952589676412930u128,    f13: 0u128,    f14: 55340232221128654848u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c1: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c2: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c3: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c4: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c5: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c6: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c7: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  }}",
    "report": "{  c0: {    f0: 156041165208724867994893291255607936132u128,    f1: 130768977891686035315541715535712445804u128,    f2: 65383418747631845451668942677490086501u128,    f3: 133453554045781821053638368587514196281u128,    f4: 145433403805334237040584272683024607081u128,    f5: 134047651686532690120740824502951506789u128,    f6: 71320009559794699847772125248361751408u128,    f7: 267163029976570322151785657395876341806u128,    f8: 160817819495622755897725644230081684404u128,    f9: 272941851679105779343843431121167150575u128,    f10: 214228591534597146723694420824838276484u128,    f11: 308566972771111169730568573940310889569u128,    f12: 215777261078696533994066537595816337280u128,    f13: 17356695615235002434592379545030409878u128,    f14: 146588840453784884285507812561630496080u128,    f15: 116990698558086918130768530081118190705u128,    f16: 48u128,    f17: 0u128,    f18: 0u128,    f19: 311278127076315502006615865277573235712u128,    f20: 18434602281589478005382016318899087191u128,    f21: 296196923782346364347344515300785896824u128,    f22: 13607577391895986u128,    f23: 0u128,    f24: 0u128,    f25: 228297337001793638367232u128,    f26: 0u128,    f27: 0u128,    f28: 3830194944029703872942113292288u128,    f29: 0u128,    f30: 0u128,    f31: 64260028180503855944056814148438196224u128  },  c1: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 3168265u128,    f4: 0u128,    f5: 0u128,    f6: 53154683027456u128,    f7: 0u128,    f8: 0u128,    f9: 891787880038139953152u128,    f10: 0u128,    f11: 0u128,    f12: 14961722611948445101906198528u128,    f13: 0u128,    f14: 0u128,    f15: 251016131220905758603159897987088384u128,    f16: 0u128,    f17: 0u128,    f18: 18609191940988822220653298843924824064u128,    f19: 12376u128,    f20: 0u128,    f21: 0u128,    f22: 207635808256u128,    f23: 0u128,    f24: 0u128,    f25: 154696116615530903167519866259721158656u128,    f26: 1339686114168286448735870861768284517u128,    f27: 135581255570207101336025210130776719874u128,    f28: 63818581871520994197558765282350565585u128,    f29: 65564856601879393085149581411146108801u128,    f30: 146762389218449641779117774626249322515u128,    f31: 110362513673010855677066021725243667559u128  },  c2: {    f0: 16002746782972337931965864452478493029u128,    f1: 14644001385438238062873278203680342278u128,    f2: 65194540546214638698862418496839549708u128,    f3: 134768117700959723719257280041131715945u128,    f4: 129174978964704168457259762063276324961u128,    f5: 134866694584729194185650327887075505015u128,    f6: 66727286348430714979528598992816320627u128,    f7: 73368193228303744347168371053335894580u128,    f8: 112995150077927076331799319934264225882u128,    f9: 138838799990053843979198846947103551827u128,    f10: 15987169892396738171518823335662677609u128,    f11: 5758318542794315194352652920891462407u128,    f12: 113000079033902721746767398808555228170u128,    f13: 4010177419220567237219489109487913732u128,    f14: 134528217138634473357168884064207844876u128,    f15: 73369125904708743234871018926599398755u128,    f16: 156098356535284061250852425596261315684u128,    f17: 178334770360483737106279363259220715636u128,    f18: 5318899907487820504231327696051621448u128,    f19: 130544159967402717464703140836202167136u128,    f20: 61495433261378761377221569305893016452u128,    f21: 80109886944788069628892375208375689401u128,    f22: 223213547107148499901916691600191559011u128,    f23: 93526351341969599928395765756775853518u128,    f24: 328066967803286733555751173264571410849u128,    f25: 2684397273013657863757327789294886307u128,    f26: 64799986648361905643634998290972409904u128,    f27: 135830494139160250812376112114568791562u128,    f28: 6226578792937090300295406101972660482u128,    f29: 241132162914780200453623545392822081234u128,    f30: 112657146426367855321834513441987501799u128,    f31: 193292753893844622311951192780920792549u128  },  c3: {    f0: 311163283690559912319595038132737872778u128,    f1: 96760303577943996719386225872771831398u128,    f2: 175984715883559618610279183548964607604u128,    f3: 2663689140631008987834175462682460761u128,    f4: 304002739640275511601146520524025762050u128,    f5: 63818581871520994197558765282347383015u128,    f6: 20194532657874829472795971456592458057u128,    f7: 65705585491353666819468972964140420400u128,    f8: 63944136253868260283130058248467132428u128,    f9: 152136436337552610183698802060950701593u128,    f10: 76020683808724120286889026781408734575u128,    f11: 65429188436890075243984134354737705009u128,    f12: 12212509222610378100066101573975552560u128,    f13: 113000079271590835567049804839055065862u128,    f14: 4019044399327372785612463289840437764u128,    f15: 5758318546508191979303583952281470037u128,    f16: 132166776360273987790188185068208524291u128,    f17: 82153991858810144096373904179044180332u128,    f18: 111670647723901262781793287833563562242u128,    f19: 194328043647410908834518307650421696235u128,    f20: 218268041859500207966818706242788748915u128,    f21: 25079078371788882315331146770036815537u128,    f22: 148037775849631280873767365114792483542u128,    f23: 53176336557638053536612836490362515475u128,    f24: 64148960774512387748054266522875749897u128,    f25: 1345778839708529072769124175373611072u128,    f26: 240785304473646293300823356102159695617u128,    f27: 100853421796707580202719813319755421965u128,    f28: 1339673755189667405418948083040792726u128,    f29: 545252255993038001153125323912130694u128,    f30: 131224418951694307630119393457135052336u128,    f31: 186604200101300216237594832860654081660u128  },  c4: {    f0: 151442076454958694309384516259033397565u128,    f1: 53754267751600002420756380396769690548u128,    f2: 38583320317302191252033589232148405669u128,    f3: 269853629886089750274292477273977738090u128,    f4: 64799915674087223998116752404004073071u128,    f5: 173815066867041753444214543350864609922u128,    f6: 178334790641036958546392051632144785029u128,    f7: 5758318541556356263566715304038747720u128,    f8: 8037878704330480932469583941996778246u128,    f9: 16007939079830858592278783466347261249u128,    f10: 129028820562530910945368451283204653315u128,    f11: 134866694584729194185650327887075505015u128,    f12: 66716820545853108110057094893837103219u128,    f13: 70709696357167260236536860441195272757u128,    f14: 110767310955139920092937077096758718554u128,    f15: 148179743798592015176329736311643574065u128,    f16: 65564902153128363753206849316466733422u128,    f17: 133214566493886631259278718764959739959u128,    f18: 148142343282919460556148339148213270629u128,    f19: 60393926179409375322764523104801158261u128,    f20: 178334770360483737106274320019404058213u128,    f21: 5318899907487820504231327696051621448u128,    f22: 98392881053462357747614692325863362301u128,    f23: 47635620122499274817710854094932237211u128,    f24: 125916046238350769996723623603554030187u128,    f25: 42367073348703940210810668835456336584u128,    f26: 69554764448561284855044520706529522889u128,    f27: 321635777077897219814308680414906284556u128,    f28: 338958353018834612099369111560341782947u128,    f29: 38989018442987879910431595894032828420u128,    f30: 200585060456456416565815256016028697635u128,    f31: 113000080539404766151095454183708071619u128  },  c5: {    f0: 274058182310213073698379869567079157277u128,    f1: 38989018437727478354095503504011334152u128,    f2: 38989018466818849018979976600472322319u128,    f3: 154794870568586028593448885282733884447u128,    f4: 146740423057232991414017184122780203632u128,    f5: 145390441402958663473615571792072633443u128,    f6: 63036803915573807001153602030616410721u128,    f7: 66732315991791400914259992338106704481u128,    f8: 72289169275695393432103715267242976354u128,    f9: 274197533678460074080788847926867158583u128,    f10: 334358583771684749321960247644460876861u128,    f11: 20797246736834760897094759263011878477u128,    f12: 160265726160169792153968203618539673715u128,    f13: 297748065094797060768728541109671592157u128,    f14: 215806517135598662819482601730797108323u128,    f15: 83510800816051759528811546746845617447u128,    f16: 119366926145396660390153500802562349765u128,    f17: 2668861027275464144411438969854630915u128,    f18: 185329191995047802586170710604654706705u128,    f19: 134501318909712132046868727015199010724u128,    f20: 63881828690870785452010848156958853937u128,    f21: 16207398392744590735859235399005308429u128,    f22: 70699433466311116402404621507927345712u128,    f23: 76058820847395038697194334270189273862u128,    f24: 138844399869116665604734947900481942327u128,    f25: 132166776360273987790188185068210369069u128,    f26: 64053212901470901633388891906250269036u128,    f27: 66711708826815180080076296401322127922u128,    f28: 5758318557030842877664705160674357810u128,    f29: 132103495858426051336753595606505884675u128,    f30: 156098356535284062213126766919824925489u128,    f31: 134487941348414821035639062006692931700u128  },  c6: {    f0: 14644001385438238062874674566267691886u128,    f1: 8037878704330480932469583942034457356u128,    f2: 25286573566032590842024239942980431169u128,    f3: 86851591070750336455717937987011695874u128,    f4: 154794729368112024508226481531827261489u128,    f5: 7980605733146738993104216853291492716u128,    f6: 21891368437567396761060381594140879621u128,    f7: 48927288995289422670628128453884596142u128,    f8: 258188651161112957830656043132237877344u128,    f9: 247435350511448651532640503060700009726u128,    f10: 140991147185042726430993510609684020147u128,    f11: 186895855028583296067933636194189103675u128,    f12: 310380921606265369598655303329151504613u128,    f13: 1334545792534793299069618499518599728u128,    f14: 170256389449774264521830464052290192127u128,    f15: 32178906267433590123702827193682224660u128,    f16: 26605775637424637605596433644789711955u128,    f17: 189443622415353257762176334213025474188u128,    f18: 5342853264578653906286485592712968240u128,    f19: 161088312802107887170240490877921329667u128,    f20: 131838567438345711988079032373837068080u128,    f21: 158682700977576260881918787171669339250u128,    f22: 153388042540986923798725508525548514675u128,    f23: 129174978964704168457259762063275946798u128,    f24: 144150557102786809516715570544695206253u128,    f25: 69355541517365306346436702772240331567u128,    f26: 131854326534425953989548790807839257444u128,    f27: 96401035972455491226775938355212936549u128,    f28: 36838557113664131396806230051861577166u128,    f29: 93030620896728297997269087774846183437u128,    f30: 48455895159343022520539456815019007639u128,    f31: 60470462973832607739571719332693351496u128  },  c7: {    f0: 111286554045745700429853798980599170904u128,    f1: 159594491396310535145975996214441295118u128,    f2: 3123265584284528759357986443633098770u128,    f3: 27924213149871026489480577684460417220u128,    f4: 7537979505587813146428554020066871808u128,    f5: 4009706745221302873941599744029398120u128,    f6: 134522270638860758578803711981129904131u128,    f7: 61660537066589544772767795085874247220u128,    f8: 66697171745289973142282891567400120186u128,    f9: 129497900356820153087834974632772329774u128,    f10: 115980396730468778132908763026635842934u128,    f11: 162671684215386440705831070854483489107u128,    f12: 65564856601879393085149581411146100335u128,    f13: 18858750611153827423867564860201578507u128,    f14: 40128127238809624745549033018192364294u128,    f15: 31040649768467829140912371028387302679u128,    f16: 171721471415875595752886343608701301261u128,    f17: 25511444641014492964411199697713836431u128,    f18: 137483774148730903822291806016009277744u128,    f19: 134683131143311701818273052235679035252u128,    f20: 8037878704330480932469584019699561569u128,    f21: 16007939079830858592278783466347261249u128,    f22: 139823605731424817587317172651689459971u128,    f23: 129461553550906213592447633597354094637u128,    f24: 158682721259985864533589211118920677688u128,    f25: 153388042540986923798725508525548514931u128,    f26: 57182887077423529737261011594587960880u128,    f27: 155582633841412053171711489446214894721u128,    f28: 259618198756576975563839544825774460165u128,    f29: 285257540571690581012408279865360506395u128,    f30: 143942259101289254393138015735355735713u128,    f31: 276769091913700302687871694332370399472u128  },  c8: {    f0: 208677483843474381986081221282734144279u128,    f1: 4019206685837637110311393514962709811u128,    f2: 5253065169906424236904230356720981u128,    f3: 5327337380604407957546176503399976496u128,    f4: 215440179130053926629945665369049275696u128,    f5: 64735240520640672823619335956923168934u128,    f6: 223858872440293529203707385926348113439u128,    f7: 78364581925220137998008671925148662809u128,    f8: 63805033124481727400733895394750499376u128,    f9: 242353360541896434988764114239479612004u128,    f10: 304286754799359235557098391899398618111u128,    f11: 110980589699214444388363971697275108087u128,    f12: 322465345391463321235294760798432122653u128,    f13: 130965269470296274957418782707559732997u128,    f14: 195178764767643465785002849530402749153u128,    f15: 161363187247956332810885816167632432704u128,    f16: 132034620131090132027246741196878735862u128,    f17: 146793663587762942489245982343134624073u128,    f18: 16820681276197282378522478976777610595u128,    f19: 210599363278218916858823088773912449436u128,    f20: 154775816426403934613447333272912881744u128,    f21: 76226415949830531741703331500963753827u128,    f22: 39818987148463290154023705547098975773u128,    f23: 752527138646628024187522218718580494u128,    f24: 126257787084817754195514096142117481248u128,    f25: 194389006404874824774548496616347947362u128,    f26: 279001747494769u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  },  c9: {    f0: 0u128,    f1: 0u128,    f2: 0u128,    f3: 0u128,    f4: 0u128,    f5: 0u128,    f6: 0u128,    f7: 0u128,    f8: 0u128,    f9: 0u128,    f10: 0u128,    f11: 0u128,    f12: 0u128,    f13: 0u128,    f14: 0u128,    f15: 0u128,    f16: 0u128,    f17: 0u128,    f18: 0u128,    f19: 0u128,    f20: 0u128,    f21: 0u128,    f22: 0u128,    f23: 0u128,    f24: 0u128,    f25: 0u128,    f26: 0u128,    f27: 0u128,    f28: 0u128,    f29: 0u128,    f30: 0u128,    f31: 0u128  }}"
}
```
</details>

Response headers:

  - `Content-Type: application/json`

> **Note:** depending on the `success` value, either `decodedData` and `decodedReport` or `errorString` exist.
>
> In `decodedData`, properties `htmlResultType`, `requestBody`, and `requestContentType` are optional strings.

For more information on the `decodedData` properties, see documentation for `AttestationResponse` in the [Aleo Oracle documentation](https://docs.aleooracle.xyz/guide/aleo_encoding/).

A decoded TEE report is returned in the `decodedReport` object. It was decoded from the request's `report` string, parsed, and verified.

`decodedReport` will be different depending on the type of report detected - Nitro or SGX.

#### SGX

```json
{
  "decodedData": {
    "url": "",
    "requestMethod": "",
    "selector": "",
    "responseFormat": "",
    "requestHeaders": {
      "Header name": ""
    },
    "encodingOptions": {
      "value": "",
      "precision": 0
    },
    "htmlResultType": null,
    "requestBody": null,
    "requestContentType": null,
    "attestationData": "",
    "responseStatusCode": 200,
    "timestamp": 0
  },
  "decodedReport": {
    "data": "",
    "securityVersion": 0,
    "debug": false,
    "uniqueId": "",
    "aleoUniqueId": "{ chunk_1: \"0u128\", chunk_2: \"0u128\" }",
    "signerId": "",
    "aleoSignerId": "{ chunk_1: \"0u128\", chunk_2: \"0u128\" }",
    "productId": "",
    "aleoProductId": "0",
    "tcbStatus": 0
  },
  "reportValid": true,
  "errorString": ""
}
```

Decoded SGX report properties

| Name | Meaning |
| ---- | ------- |
| `data` | 64 bytes of data that was signed by the enclave. In this case it's a Poseidon8 hash of `decodedData` (16 bytes) |
| `securityVersion` | Enclave security version, which is bumped when a security patch is applied without changing the enclave code or data |
| `debug` | Whether the enclave is running in a debug mode |
| `uniqueId` | A unique ID of the enclave created by hashing the code and data of the enclave, 32 bytes |
| `aleoUniqueId` | `uniqueId` as an Aleo struct of 2 `u128` fields - `chunk_1` and `chunk_2` |
| `signerId` | A hash of the enclave signer's key, which was used to sign the enclave's code and data, 32 bytes |
| `aleoSignerId` | `uniqueId` as an Aleo struct of 2 `u128` fields - `chunk_1` and `chunk_2` |
| `productId` | Used to indicate different software modules within the same enclave, 16 bytes |
| `aleoProductId` | A string of `productId` encoded as 1 Leo value of type `u128` |
| `tcbStatus` | Trusted Computing Base - level of trustworthiness or security assurance |

<details>
<summary><b>Example response SGX</b></summary>

```json
{
  "decodedData": {
    "url": "archive-api.open-meteo.com/v1/archive?latitude=38.9072&longitude=77.0369&start_date=2023-11-20&end_date=2023-11-21&daily=rain_sum",
    "requestMethod": "GET",
    "selector": "daily.rain_sum.[0]",
    "responseFormat": "json",
    "requestHeaders": {
      "Accept": "*/*",
      "DNT": "1",
      "Upgrade-Insecure-Requests": "1",
      "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
    },
    "encodingOptions": {
      "value": "float",
      "precision": 2
    },
    "attestationData": "0.00",
    "responseStatusCode": 200,
    "timestamp": 1703169427
  },
  "decodedReport": {
    "data": "SuJJLAJ+CUBUrXDMSI31kQ==",
    "securityVersion": 1,
    "debug": false,
    "uniqueId": "WOJsqjAmTXTuSW83DN8EM6goCPE/smuIXT8eVNx6NN8=",
    "aleoUniqueId": "{ chunk_1: \"67815920917700628759894811536473776728u128\", chunk_2: \"296690334406880757170225743286084577448u128\" }",
    "signerId": "9H4s7YPOeZFug8XZRRRlc+Z7Vfit98IfkZsrDpb+Dxs=",
    "aleoSignerId": "{ chunk_1: \"153386052680309655679396867527014121204u128\", chunk_2: \"35972203959719964238382729092704599014u128\" }",
    "productId": "AQAAAAAAAAAAAAAAAAAAAA==",
    "aleoProductId": "1u128",
    "tcbStatus": 5
  },
  "reportValid": true
}
```
</details>

#### Nitro

```json
{
  "decodedData": {
    "url": "",
    "requestMethod": "",
    "selector": "",
    "responseFormat": "",
    "requestHeaders": {
      "Header name": ""
    },
    "encodingOptions": {
      "value": "",
      "precision": 0
    },
    "htmlResultType": null,
    "requestBody": null,
    "requestContentType": null,
    "attestationData": "",
    "responseStatusCode": 200,
    "timestamp": 0
  },
  "decodedReport": {
    "moduleID": "",
    "timestamp": 0,
    "digest": "SHA384",
    "pcrs": {
      "0": "",
      "1": "",
      "2": "",
      "3": "",
      "4": "",
      "5": "",
      "6": "",
      "7": "",
      "8": "",
      "9": "",
      "10": "",
      "11": "",
      "12": "",
      "13": "",
      "14": "",
      "15": ""
    },
    "aleoPcrs": "{ pcr_0_chunk_1: 0u128, pcr_0_chunk_2: 0u128, pcr_0_chunk_3: 0u128, pcr_1_chunk_1: 0u128, pcr_1_chunk_2: 0u128, pcr_1_chunk_3: 0u128, pcr_2_chunk_1: 0u128, pcr_2_chunk_2: 0u128, pcr_2_chunk_3: 0u128 }",
    "certificate": "",
    "cabundle": [
      ""
    ],
    "userData": "",
    "nonce": "",
    "protectedCose": "",
    "signature": ""
  },
  "reportValid": true
}
```

Decoded Nitro report properties

> PCR - Platform configuration registers. Some PCRs are automatically generated when the enclave is created, and they can be used to verify that no changes have been made to the enclave since it was created.

| Name | Meaning |
| ---- | ------- |
| `moduleID` | Issuing Nitro hypervisor module ID |
| `timestamp` | UTC time when document was created, in milliseconds since UNIX epoch |
| `digest` | The digest function used for calculating the register values |
| `pcrs` | Map of all locked PCRs at the moment the attestation document was generated |
| `aleoPcrs` | PCRs 0-2 encoded as one struct of 9 `u128` fields, 3 chunks per PCR value |
| `certificate` | The public key certificate for the public key that was used to sign the attestation document |
| `cabundle` | Issuing CA bundle for infrastructure certificate |
| `userData` | Additional signed user data. In this case it's a Poseidon8 hash of `decodedData` (16 bytes) |
| `nonce` | An optional cryptographic nonce provided by the attestation consumer as a proof of authenticity |
| `protectedCose` | Protected section from the COSE Sign1 payload |
| `signature` | Signature section from the COSE Sign1 payload of the Nitro enclave attestation document |

<details>
<summary><b>Example response Nitro</b></summary>

```json
{
  "decodedData": {
    "url": "api.binance.com/api/v3/ticker/price?symbol=BTCUSDC",
    "requestMethod": "GET",
    "selector": "price",
    "responseFormat": "json",
    "encodingOptions": {
      "value": "float",
      "precision": 8
    },
    "attestationData": "59408.01000000",
    "responseStatusCode": 200,
    "timestamp": 1725008028
  },
  "decodedReport": {
    "moduleID": "i-02dd0abe215ecea89-enc0191a27d4c6d8178",
    "timestamp": 1725008028632,
    "digest": "SHA384",
    "pcrs": {
      "0": "/MTO0/S7pzUuKJon+4+3NYJV1rNauv3ItKOYxBikR3mjd5ebqmL8eO9tiaprwRrw",
      "1": "A0OwVs2Ehcp4kN3YM0dteEYK7SqhYVSOTia+3zIXJmliV9Yj6IBfP2BZRrPYsMaq",
      "10": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "11": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "12": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "13": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "14": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "15": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "2": "VaKWvoYpjOfVi/KJutUpxw4NUIVLR1mQ1Pjq0r8C1vtHbnF8yAwFer980PIc38WW",
      "3": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "4": "aWOA5bTYYZ2R/C3qV+cV8017AqJAoCCxEGDeDXi9E7WozprebberstZz1d6ylbIA",
      "5": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "6": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "7": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "8": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      "9": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
    },
    "aleoPcrs": "{ pcr_0_chunk_1: 71402194384810807695471133674510927100u128, pcr_0_chunk_2: 161208568844425284329478584127483958658u128, pcr_0_chunk_3: 319153641741947202476283715452178757539u128, pcr_1_chunk_1: 160074764010604965432569395010350367491u128, pcr_1_chunk_2: 139766717364114533801335576914874403398u128, pcr_1_chunk_3: 227000420934281803670652481542768973666u128, pcr_2_chunk_1: 264733590264774658848247826143579120213u128, pcr_2_chunk_2: 334747434232414500511461632767813487886u128, pcr_2_chunk_3: 200411607119746324753107350992173755975u128 }",
    "certificate": "MIICfjCCAgOgAwIBAgIQAZGifUxtgXgAAAAAZtGIhzAKBggqhkjOPQQDAzCBjzELMAkGA1UEBhMCVVMxEzARBgNVBAgMCldhc2hpbmd0b24xEDAOBgNVBAcMB1NlYXR0bGUxDzANBgNVBAoMBkFtYXpvbjEMMAoGA1UECwwDQVdTMTowOAYDVQQDDDFpLTAyZGQwYWJlMjE1ZWNlYTg5LmFwLXNvdXRoLTIuYXdzLm5pdHJvLWVuY2xhdmVzMB4XDTI0MDgzMDA4NTMyNFoXDTI0MDgzMDExNTMyN1owgZQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApXYXNoaW5ndG9uMRAwDgYDVQQHDAdTZWF0dGxlMQ8wDQYDVQQKDAZBbWF6b24xDDAKBgNVBAsMA0FXUzE/MD0GA1UEAww2aS0wMmRkMGFiZTIxNWVjZWE4OS1lbmMwMTkxYTI3ZDRjNmQ4MTc4LmFwLXNvdXRoLTIuYXdzMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAEYLtGTsIaI5j2nFBAA+Q1YoQTxug0eR35wx15ZPKWQy65IAlcmO4KixSXL+temkQ8Y5XULsM5BpDWMbFBjV3tp85tw8Y3fI6rdxgE6CKFXEahqXhbloCG/dYgURxTZs/2ox0wGzAMBgNVHRMBAf8EAjAAMAsGA1UdDwQEAwIGwDAKBggqhkjOPQQDAwNpADBmAjEA06nCyMfeZBNUCTKvBNLWcaWn0D6RdVmkCYVdaLXnHrih81laLWIY/yYo+sBU5SXvAjEAz+ccBSTzjNRqkYoTQ8CcD4pByt+ATFreF+pmVv2MWMuiBnChJLhKW8tIdBazOE2o",
    "cabundle": [
      "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"
    ],
    "userData": "X/FUY0m5UiimPFAzL9O0ag==",
    "nonce": "zM5D5X8cRLqdi6cMnNFRZy7w+QbjuYqsRfZvnlBoY20=",
    "protectedCose": "oQE4Ig==",
    "signature": "K3j8xHNw6rxwdGNvnSJAFqLrt7KWznesWDkdbnK8zyazRkcAY/Oj2/QdDs8WyscTWVe1fjTWc+6QACCru5DBl4EH10v5X4Nd/F5iUUQvCtYZBw/Hxuv49T2ScRcNKMD9"
  },
  "reportValid": true
}
```
</details>
