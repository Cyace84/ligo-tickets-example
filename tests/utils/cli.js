const { TezosToolkit } = require("@taquito/taquito");
const { InMemorySigner } = require("@taquito/signer");

const { alice, bob } = require("../../scripts/sandbox/accounts");

const env = require("../../env");
const networkConfig = env.networks.development;

const rpc = networkConfig.rpc;
const Tezos = new TezosToolkit(rpc);

const signerAlice = new InMemorySigner(networkConfig.secretKey);
const signerBob = new InMemorySigner(bob.sk);

Tezos.setSignerProvider(signerAlice);

// const { getDeploydAddress } = require("../../scripts/helpers");

// const deployedContract = getDeploydAddress("Governance");

module.exports = { Tezos, signerAlice, signerBob, alice, bob };
