# Aleo Oracle architecture

On the high level, the Oracle architecture consists of:

- Oracle client
- one or more Oracle notarization backends running inside TEEs
- an Oracle verification backend
- Oracle Aleo program

## Architecture diagrams

The diagrams below show what happens when an application uses Oracle client to acquire and attest data,
then how the application uses the data in Aleo blockchain.

### Oracle client sequence diagram for acquiring and attesting data

```mermaid
sequenceDiagram
    autonumber
    actor A as Application
    participant OC as Oracle client
    participant OBN as Oracle notarization backend #35;N
    note over OBN: Runs inside a TEE
    participant DS as Data source
    participant OV as Oracle verification backend

    A->>OC: Request data for using in Aleo
    activate A
    activate OC
    loop For every Oracle notarization backend
        OC->>OBN: Request attestation of Data source
        activate OBN
        OBN->>DS: HTTP request for data
        activate DS
        DS->>OBN: HTTP response
        deactivate DS
        note over OBN: Attest to the response<br/> and encode for Aleo
        OBN->>OC: Respond to client
        deactivate OBN
    end
    deactivate OC
    note over OC: Checks responses from all backends
    loop For every attestation response
        OC->>OV: Request verification
        activate OC
        activate OV
        note over OV: Verifies attestation using reproducible builds
        OV->>OC: Approves attestation
        deactivate OV
    end
    deactivate OC
    OC->>A: Returns attestation results
    deactivate A
    note over A: Uses attestation results<br/>in a web app
```

### Aleo program sequence diagram after the client has acquired data

```mermaid
sequenceDiagram
    autonumber
    actor A as Application
    box Aleo blockchain
    participant O as Oracle program
    participant P as Application program
    end
    A->>O: Submits data and attestation<br/> to an Aleo program
    Note over O: Verifies attestation report<br/>and saves the data
    A->>P: Executes a transition in the application program
    activate A
    activate P
    P->>O: Requests verified data from Oracle
    activate O
    O->>P: Provides data
    deactivate O
    note over P: Uses attested data
    P->>A: Successful transition execution
    deactivate P
    deactivate A
    note over A: Success
```

## Oracle client

The Oracle client is a dApp that needs to consume data from web2.0 in a secure way. This is most likeyly you - the developer!

By using one of the Oracle SDKs you can integrate the functionality of requesting web2.0 resources and using them in Aleo blockchain and your dApp.

Depending on the use case, you could use one of the deployed application-specific Oracle programs or develop your own.

The client is not required if all you need is to consume the data that has already been submitted to an existing Oracle program.

See [Using the Oracle](../guide/index.md) for tutorials on using the Oracle SDK and examples.

## Oracle backend

[Oracle backend repository :fontawesome-brands-github:]({{ variables.links.oracle_backend_repo }})

An Oracle backend receives a notarization request from a client. The request contains information about the web2.0 resource to notarize,
how to reach it, how to extract the relevant data from the resource and encode it for later usage.

The backend performs an HTTPS request to the specified resource, receives a response, then applies a selector to the response body, producing the relevant information in the resource.

The results are signed and attested by the TEE enclave.

## Oracle verification backend

[Oracle verification backend repository :fontawesome-brands-github:]({{ variables.links.verification_backend_repo }})

An Oracle verification backend received attested responses and verifies the attestation reports. One of the steps is verifying that the unique ID of the attesting enclave
matches the expected one. This is done using reproducible builds of the Oracle notarization backend.

This backend is also capable of decoding Aleo-encoded Report Data, decoding and verifying Aleo-encoded Attestation Reports, e.g. if you want
to verify someone else's reports/data.

You can self-host this backend by following [this Guide](../guide/hosting_verifier.md).

## Oracle program

An Aleo program that is capable of accepting Oracle attestation reports and attested data. See more information about how it works in the [Guide about the oracle program](../guide/oracle_program.md).
