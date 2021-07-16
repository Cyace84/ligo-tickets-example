#include "../partial/Items.ligo"
#include "../partial/CoreTypes.ligo"

type storage_type       is [@layout:comb] record [
  owner                   : address;
  accounts                : big_map(address, account_type)
]
type return             is list (operation) * storage_type

function get_receive_contract(
  const receiver        : address)
                        : contract(list(consumable_item_type)) is
  case (Tezos.get_entrypoint_opt(
    "%receive_item",
     receiver)
     : option(contract(list(consumable_item_type)))) of
    Some(contr) -> contr
    | None -> (failwith("No receiver contract") : contract(list(consumable_item_type)))
  end;

function create_account (
    const new_acc         : address;
    const s               : storage_type)
                          : account_type is
  case s.accounts[new_acc] of
    Some(acc) -> failwith("Core/registered-acc")
  | None      -> record[
                   account = new_acc;
                ]
end;


function create_reg_bonus (
  const _unit           : unit)
                        : list(consumable_item_type) is
  block {
    const weapon_ticket : consumable_type =
      record [
        id  = 2n;
        name = "Noob weapon ticket";
        value = 1n;
    ];

    const stat_point : consumable_type =
      record [
        id    = 1n;
        name  = "Noob stat point";
        value = 1n;
      ];

    const start_weapon : consumable_item_type =
      Tezos.create_ticket (weapon_ticket, 1n);

    const start_points : consumable_item_type =
      Tezos.create_ticket (stat_point, 10n);

  } with list[start_weapon; start_points];

function registration (
  const reg_params      : registration_params_type;
  var s                 : storage_type)
                        : return is
  block {
    var result : return := ((nil : list (operation)), s);
    case (Tezos.read_ticket (reg_params.registration_ticket)) of
        (content, ticket) -> {
          case content of
            (addr, x) -> {
              if addr = Tezos.self_address then skip
              else failwith("Core/unknown-ticketer");
              case x of
                (payload, amt) -> {
                  if payload.id = 0n then skip
                  else failwith("Core/not-reg-ticket");
                  const new_account : account_type = create_account(Tezos.sender, s);
                  s.accounts[Tezos.sender] := new_account;
                  const bonus : list(consumable_item_type) = create_reg_bonus(unit);
                  const contr : contract(list(consumable_item_type))  = get_receive_contract(Tezos.sender);
                  const op = Tezos.transaction(bonus, 0mutez, contr);
                  result := (list[op], s);
                } end
          } end
    } end
} with result

function buy_item (
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
  Registration            of registration_params_type
| Go_pvp_arena            of consumable_item_type
| Buy_item                of item_id_type

function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
    Registration  (params)      -> registration (params, s)
  | Buy_item (params)           -> ((nil : list (operation)), buy_item (params, s))
  | Go_pvp_arena (params)       -> ((nil : list (operation)), go_pvp_arena (params, s))
  end