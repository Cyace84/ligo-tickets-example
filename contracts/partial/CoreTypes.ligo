
type registration_params_type is [@layout:comb] record [
    registration_ticket    : consumable_item_type;
    callback              : contract(list(consumable_item_type));
  ]

type account_status_type is
  Pending_duel
| In_duel
| Free

type account_type       is [@layout:comb] record [
    addr                  : address;
    status                : account_status_type;
    current_duel          : nat;
]


type target_type        is
  Head
| Body

type duel_action_type   is
  Attack                 of nat
| Deffend                of nat
| Use_item               of item_id_type

type duel_actions_type  is map(nat, duel_action_type)

type hero_status_type   is [@layout:comb] record [
  hp                      : nat;
  buff                    : nat;
  debuff                  : nat;
]

type round_type         is [@layout:comb] record [
  actions                 : map(address, duel_actions_type);
  hero_status             : map(address, hero_status_type);
  start_at                : timestamp;
]

type duel_type          is [@layout:comb] record [
  total_pot               : nat;
  rounds                  : map(nat, round_type);
  next_round              : nat;
  winner                  : option(address);
]


type lvl_type           is nat

type pending_hero_type  is [@layout:comb] record [
  account                   : account_type;
  bet                       : nat;
]

type lobby_type         is big_map(lvl_type, pending_hero_type)
type arena_type         is [@layout:comb] record [
  lobby                   : lobby_type  ;
  duels                   : big_map(nat, duel_type);
  duel_id                 : nat;
]

type hero_stats_type    is [@layout:comb] record [
  lvl                     : nat;
  hp                      : nat;
  damage                  : nat;
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