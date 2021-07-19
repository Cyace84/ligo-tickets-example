const { MichelsonMap } = require("@taquito/michelson-encoder");

const { alice, bob } = require("../scripts/sandbox/accounts");

const inventory = {
  weapons: MichelsonMap.fromLiteral({}),
  consumable_items: MichelsonMap.fromLiteral({}),
  inventory_size: 10,
  next_slot_weapon: 1,
  next_slot_item: 1,
};

const stats = {
  str: 1,
  con: 1,
  dex: 1,
  acc: 1,
};

const equip = {
  weapon: null,
};
const { address } = require("../scripts/sandbox/core_latest.json");
module.exports = {
  owner: alice.pkh,
  game_server: address,
  nickname: "777NaGiBatoR777",
  inventory: inventory,
  stats: stats,
  // equip: equip,
  hp: 10,
  damage: 0,
  exp: 0,
  lvl: 1,
};
