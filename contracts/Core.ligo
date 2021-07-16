#include "./partial/Items.ligo"

type storage_type       is [@layout:comb] record [
  owner                   : address;
  ticketer                : address;
  accounts                : big_map(address, nat)
]


function registration (
  const reg_ticket      : consumable_item_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s

function Buy_item (
  const item_id         : item_id_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s

function go_pvp_arena (
  const arena_pass      : consumable_item_type;
  const s               : storage_type)
                        : storage_type is
  block {
    skip
} with s


type parameter_type     is
  Regstration             of consumable_item_type
| Go_pvp_arena            of consumable_item_type

function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
    Registration  (params)      -> ((nil : list (operation)), registration (params, s))
  | Buy_item (params)           -> buy_item (params, s)
  | Go_pvp_arena (params)       -> ((nil : list (operation)), go_pvp_arena (params, s))
  end