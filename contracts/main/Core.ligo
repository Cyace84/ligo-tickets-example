#include "../partial/Items.ligo"
#include "../partial/CoreTypes.ligo"



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
                   addr         = new_acc;
                   status       = Free;
                   current_duel = 0n;
                ]
end;

function get_account (
  const addr            : address;
  const s               : storage_type)
                        : account_type is
  case s.accounts[addr] of
    Some(acc) -> acc
  | None      -> failwith("Core/no-registered")
  end

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


function clear_lobby (
  const key             : lvl_type;
  var s                 : lobby_type)
                        : lobby_type   is
  block {
    remove key from map s
  } with s


function go_pvp_arena (
  const params          : arena_params_type;
  var   s               : storage_type)
                        : storage_type is
  case params of
    record[arena_pass; hero_stats] -> block {
      const t_info =
      case (Tezos.read_ticket (arena_pass)) of
        (content, ticket) -> case content of
          (addr, x) ->
            case x of
              (payload, amt) -> block {
                if payload.id = 1n then skip
                else failwith("Core/not-pvp-ticket");

                const return = record[
                  addr = addr;
                  bet = amt;
                ]
              } with return
            end
        end
      end;
      var account := get_account(t_info.addr, s);
      if t_info.addr = Tezos.sender then skip
      else failwith("Core/unknown-sender");

      if t_info.bet = hero_stats.lvl then skip
      else failwith("Core/low-bet");

      var arena := s.arena;
      var accounts := s.accounts;
      case account.status of
        Free ->
          case arena.lobby[hero_stats.lvl]  of
            Some(acc) -> {
              const new_duel = record[
                total_pot   = acc.bet + t_info.bet;
                rounds      = (map[] : map(nat, round_type));
                next_round  = 1n;
                winner      = (None: option(address));
              ];
              arena.duels[arena.duel_id] := new_duel;
              arena.duel_id := arena.duel_id + 1n;

              var updated_lobby := clear_lobby(arena.duel_id, arena.lobby);
              arena.lobby := updated_lobby;

              account.status := In_duel;
              account.current_duel := arena.duel_id;

              var acc2  := acc.account;
              acc2.status := In_duel;
              acc2.current_duel := arena.duel_id;

              accounts[account.addr] := account;
              accounts[acc2.addr]    := account;

            }
          | None     ->
            arena.lobby[hero_stats.lvl] := record[
                                            account = account;
                                            bet     = t_info.bet;
            ]
          end
      | Pending_duel -> failwith("Core/pending-duel-already")
      | In_duel -> failwith("Core/in-duel-already")
      end;
      const updated_storage = record[
        owner    = s.owner;
        accounts = accounts;
        arena    = arena;
      ];

    } with updated_storage
  end

type parameter_type     is
  Registration            of registration_params_type
| Go_pvp_arena            of arena_params_type
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