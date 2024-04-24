# Overview

## What is an oracle?

!!! quote "What is an oracle in blockchain?"

    "Blockchain oracles are entities that connect blockchains to external systems, thereby enabling smart contracts to execute based upon inputs and outputs from the real world."

    [Chainlink: What Is a Blockchain Oracle?](https://chain.link/education/blockchain-oracles)

In the blockchain realm, trust holds immense significance. As the blockchain problem is to reach consensus, extrinsic information cannot be provided along with transaction data, since other nodes would detect information coming from an “untrusted” source. Therefore, information coming from the real world should come from a third-party univocal source, whose reliability is undisputed for all nodes: the oracle. Using an oracle unfortunately introduces a problem known as The Blockchain Oracle Problem.

??? quote "The Blockchain Oracle Problem"

    "The Blockchain Oracle Problem refers to the ==inability of confirming the veracity of the data collected by oracles==. Also, depending on the type, the chances of malfunction, and deliberate tampering."

    "As oracles are not distributed, ==they reintroduced the single-point-of-failure==. Additionally, since they operate on non-deterministic data, ==their reliability needs to be trusted==, removing trustless peer-to-peer interaction. Their implementation through smart contracts into the blockchain could also jeopardize users’ trust who consider the blockchain as more reliable than legacy systems."

    "... if the data are trusted and verified, ==the oracle may fail to operate correctly== on the smart contract either due to malfunction or deliberate tampering."

    [Scholarly Community Encyclopedia: Blockchain Oracle Problem](https://encyclopedia.pub/entry/2959)

## Aleo Oracle solution

Aleo Oracle minimizes the problem above by using a combination of the following components:

- full transparency;
- TLS response attestations using TEEs;
- Aleo zero-knowledge proofs;

!!! quote "Trusted execution environment"

    "A trusted execution environment (TEE) is a secure area of a main processor. It helps code and data loaded inside it to be protected with respect to confidentiality and integrity. Data integrity prevents unauthorized entities from outside the TEE from altering data, while code integrity prevents code in the TEE from being replaced or modified by unauthorized entities..."

    "... allows user-level code to allocate private regions of memory, called enclaves, which are designed to be protected from processes running at higher privilege levels. A TEE as an isolated execution environment provides security features such as isolated execution, integrity of applications executing with the TEE, along with confidentiality of their assets."

    [Wikipedia: Trusted execution environment](https://en.wikipedia.org/wiki/Trusted_execution_environment)

!!! info inline end " "

    To be transparent, using a TEE still involves a degree of trust, specifically in the TEE provider's implementation of the isolated compute environment.
    Historically, TEEs, such as [Intel's SGX](https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html), have faced challenges and vulnerabilities, but they have been subsequently addressed and resolved.

Using a TEE resolves many of the known Blockchain Oracle issues.

By the virtue of having an open source code, reproducible builds, and source code signatures, users can verify the data veracity and that the oracle operates correctly and does what it's supposed to be doing.

The Oracle client supports multiple attestation backends in different TEEs, thus eliminating the single-point-of-failure.

See the [Architecture](./architecture.md) page to learn more on how Aleo Oracle solution works.
