
type registration_params_type is [@layout:comb] record [
    registration_ticket    : consumable_item_type;
    callback              : contract(list(consumable_item_type));
  ]

type account_type       is [@layout:comb] record [
    account               : address;
]

type lvl_room_type      is list(account_type)

type lobby_type is big_map(nat, lvl_room_type)

type target_type        is
  Head
| Body

type duel_action_type   is
  Attack                 of nat
| Deffend                of nat
| Use_item               of item_id_type

type duel_actions_type is map(nat, duel_action_type)


type round_type         is [@layout:comb] record [
  actions                 : map(address, duel_actions_type);
  start_at                : timestamp;
]

type duel_type          is [@layout:comb] record [
  total_pot               : nat;
  rounds                  : map(nat, round_type);
  next_round              : nat;
  winner                  : option(address);
]

type pre_duel_type      is [@layout:comb] record[
  account                 : address;
  bet                     : nat;
]
type arena_type         is [@layout:comb] record [
  lobby                   : lobby_type;
  duels                   : big_map(nat, duel_type);
  duel_id                 : nat;
  pre_duel_cache          : big_map(address, pre_duel_type);
]