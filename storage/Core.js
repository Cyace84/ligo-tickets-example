const { MichelsonMap } = require("@taquito/michelson-encoder");

const { alice, bob } = require("../scripts/sandbox/accounts");

const arena = {
  lobby: MichelsonMap.fromLiteral({}),
  duels: MichelsonMap.fromLiteral({}),
  duel_id: 1,
};

module.exports = {
  owner: alice.pkh,
  accounts: MichelsonMap.fromLiteral({}),
  arena: arena,
};
