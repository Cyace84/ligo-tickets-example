const { migrate } = require("../scripts/helpers");
const { MichelsonMap } = require("@taquito/michelson-encoder/");
const storage = require("../storage/Hero");

module.exports = async tezos => {
  const contractAddress = await migrate(tezos, "Hero", storage);
  console.log(`Hero contract address: ${contractAddress}`);
};
