
// type registration_params_type is [@layout:comb] record [
//     registration_ticket    : consumable_item_type;
//     callback              : contract(consumable_item_type);
//   ]

type account_status_type is
  Pending_duel
| In_duel
| Free

type hero_stats_type    is [@layout:comb] record [
  lvl                     : nat;
  hp                      : nat;
  damage                  : nat;
  str                     : nat;
  con                     : nat;
  dex                     : nat;
  acc                     : nat;
]

type account_type       is [@layout:comb] record [
  addr                  : address;
  status                : account_status_type;
  current_duel          : nat;
  last_stats            : hero_stats_type;
]


type target_type        is
  Head
| Body

type duel_action_type   is
  Attack                 of target_type
| Deffend                of target_type
| Use                    of item_id_type

// type duel_actions_type  is map(nat, duel_action_type)

type hero_status_type   is [@layout:comb] record [
  hp                      : nat;
  buff                    : nat;
  debuff                  : nat;
]

type hstatus_map_type   is map(address, hero_status_type)

type p_action           is (duel_action_type * duel_action_type)

type round_type         is [@layout:comb] record [
  actions                 : map(address, p_action);
  hero_status             : hstatus_map_type;
  started_at              : timestamp;
]

type duel_type          is [@layout:comb] record [
  hero_1                  : address;
  hero_2                  : address;
  total_pot               : nat;
  rounds                  : map(nat, round_type);
  next_round              : nat;
  winner                  : option(address);
  p_already               : nat;
]


type lvl_type           is nat

type pending_hero_type  is [@layout:comb] record [
  addr                      : address;
  bet                       : nat;
]

type lobby_type         is big_map(lvl_type, pending_hero_type)

type arena_type         is [@layout:comb] record [
  lobby                   : lobby_type  ;
  duels                   : big_map(nat, duel_type);
  duel_id                 : nat;
]

type arena_params_type  is [@layout:comb] record [
  arena_pass              : consumable_item_type;
  hero_stats              : hero_stats_type;
]

type storage_type       is [@layout:comb] record [
  owner                   : address;
  accounts                : big_map(address, account_type);
  arena                   : arena_type;
]

type return             is list (operation) * storage_type


type receive_battle_params is (duel_action_type * duel_action_type)

