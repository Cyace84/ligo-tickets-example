const { migrate } = require("../scripts/helpers");
const { MichelsonMap } = require("@taquito/michelson-encoder/");

module.exports = async tezos => {
  const contractAddress = await migrate(tezos, "Ticketer", {
    tickets: MichelsonMap.fromLiteral({}),
    ticket_id: 0,
  });
  console.log(`Ticketer contract address: ${contractAddress}`);
};
