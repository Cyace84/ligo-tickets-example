#include "../partial/Items.ligo"
#include "../partial/CoreTypes.ligo"



function get_receiver_contract(
  const receiver        : address)
                        : contract(consumable_item_type) is
  case (Tezos.get_entrypoint_opt(
    "%receive_item",
     receiver)
     : option(contract(consumable_item_type))) of
    Some(contr) -> contr
    | None -> (failwith("No receiver contract") : contract(consumable_item_type))
  end;

function create_account (
    const new_acc         : address;
    const s               : storage_type)
                          : account_type is
  case s.accounts[new_acc] of
    Some(acc) ->  failwith("Core/registered-acc")
  | None      ->  record[
                    addr         = new_acc;
                    status       = Free;
                    current_duel = 0n;
                    last_stats   = record[
                      lvl     = 0n;
                      hp      = 0n;
                      damage  = 0n;
                      str     = 0n;
                      con     = 0n;
                      dex     = 0n;
                      acc     = 0n;
                    ];
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
                        : consumable_item_type is
  block {
    // const weapon_ticket : consumable_type =
    //   record [
    //     id  = 2n;
    //     name = "Noob weapon ticket";
    //     value = 1n;
    // ];

    const stat_point : consumable_type =
      record [
        id    = 3n;
        name  = "Noob stat point";
        value = 1n;
      ];

    // const start_weapon : consumable_item_type =
    //   Tezos.create_ticket (weapon_ticket, 1n);

    const start_points : consumable_item_type =
      Tezos.create_ticket (stat_point, 10n);

  } with start_points;

function registration (
  const reg_ticket      : consumable_item_type;
  var s                 : storage_type)
                        : return is
  block {
    var result : return := ((nil : list (operation)), s);
    case (Tezos.read_ticket (reg_ticket)) of
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
                  const bonus : consumable_item_type = create_reg_bonus(unit);
                  const contr : contract(consumable_item_type)  = get_receiver_contract(Tezos.sender);
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
              var account_2  := get_account(acc.addr, s);
              const new_duel = record[
                hero_1      = acc.addr;
                hero_2      = account.addr;
                total_pot   = acc.bet + t_info.bet;
                rounds      = (map[] : map(nat, round_type));
                next_round  = 1n;
                winner      = (None: option(address));
                p_already   = 0n;
              ];
              arena.duels[arena.duel_id] := new_duel;
              arena.duel_id := arena.duel_id + 1n;

              var updated_lobby := clear_lobby(arena.duel_id, arena.lobby);
              arena.lobby := updated_lobby;

              account.status := In_duel;
              account.current_duel := arena.duel_id;
              account.last_stats := record[
                lvl                     = hero_stats.lvl;
                hp                      = hero_stats.hp;
                damage                  = hero_stats.damage;
                str                     = hero_stats.str;
                con                     = hero_stats.con;
                dex                     = hero_stats.dex;
                acc                     = hero_stats.acc;
              ];

              account_2.status := In_duel;
              account_2.current_duel := arena.duel_id;

              accounts[account.addr]   := account;
              accounts[account_2.addr] := account;

            }
          | None     ->
            arena.lobby[hero_stats.lvl] := record[
                                            addr    = account.addr;
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

function receive_battle_params (
  const params          : receive_battle_params;
  var s                 : storage_type)
                        : return is
  block {
    var result : return := ((nil : list (operation)), s);
    var account := get_account(Tezos.sender, s);
    var arena := s.arena;
    var duel : duel_type:= case arena.duels[account.current_duel] of
      Some(duel) -> case duel.winner of
        Some(addr) -> failwith("Core/duel-over")
      | None     -> duel
      end
    | None       -> failwith("Core/oops")
    end;

    if duel.p_already = 0n
    then {
      const actions = map[account.addr -> params];
      const new_round = record[
        actions           = actions;
        hero_status       = (map[] : hstatus_map_type);
        started_at        = Tezos.now;
      ];
      duel.rounds[duel.next_round] := new_round;
      duel.p_already := 1n;

      arena.duels[account.current_duel] := duel;
      s.arena := arena;
    } else {
      var account_1 := get_account(duel.hero_1, s);
      var account_2 := account;

      account_1.status := Free;
      account_2.status := Free;
      s.accounts[account_1.addr] := account_1;
      s.accounts[account_2.addr] := account_2;


      var round := case duel.rounds[account_2.current_duel] of
        Some(d) -> d
        | None  -> (failwith("Core/oops") : (round_type))
      end;

      round.actions[account_2.addr] := params;

      var h1_action : p_action :=
      case round.actions[duel.hero_1] of
        Some(d) -> d
      | None  -> failwith("Core/oops")
      end;

      var hero_2_action : p_action :=
      case round.actions[duel.hero_2] of
        Some(d) -> d
      | None  -> failwith("Core/oops")
      end;
      const  h2_action = params;

      (* PVP *)
      const h1_stat = record[
        hp         = 10n;
        buff       = 0n;
        debuff     = 0n;
      ];

      const h2_stat = record[
        hp         = 0n;
        buff       = 0n;
        debuff     = 0n;
      ];

      var h1_alive := if h1_stat.hp > 0n then True else False;
      var h2_alive := if h2_stat.hp > 0n then True else False;

      if h1_alive = True and h2_alive = True then skip
      else {
        if h1_alive = True
        then duel.winner := Some(account_1.addr)
        else duel.winner := Some(account_2.addr)
      };

      duel.rounds[duel.next_round] := round;
      arena.duels[account.current_duel] := duel;
      s.arena := arena;

      const money : consumable_type =
      record [
        id    = 4n;
        name  = "Money";
        value = 1n;
      ];

      const exp : consumable_type =
      record [
        id    = 5n;
        name  = "exp";
        value = 1n;
      ];

      const prize_1 : consumable_item_type =
        Tezos.create_ticket (money, duel.total_pot);
      const prize_2 : consumable_item_type =
        Tezos.create_ticket (exp, 5n);

      const winner :address = case duel.winner of
        Some(w) -> w
        | None -> failwith("Core/oops")
      end;
      const contr : contract(consumable_item_type)  = get_receiver_contract(winner);
      const op_1 = Tezos.transaction(prize_1, 0mutez, contr);
      const op_2 = Tezos.transaction(prize_2, 0mutez, contr);
      result := (list[op_1; op_2], s);
    }
  } with result

function send_invite(
  const receiver        : address;
  const s               : storage_type)
                        : return is
block {
  const inv : consumable_type =
      record [
        id    = 0n;
        name  = "Reg ticket";
        value = 1n;
      ];

  const invite : consumable_item_type =
      Tezos.create_ticket (inv, 1n);
  const contr = get_receiver_contract(receiver);

  const op = Tezos.transaction(invite, 0mutez, contr);

} with (list[op], s)

type parameter_type     is
  Registration            of consumable_item_type
| Go_pvp_arena            of arena_params_type
| Buy_item                of item_id_type
| Receive_battle          of receive_battle_params
| Send_invite             of address

function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
    Registration  (params)      -> registration (params, s)
  | Buy_item (params)           -> ((nil : list (operation)), buy_item (params, s))
  | Go_pvp_arena (params)       -> ((nil : list (operation)), go_pvp_arena (params, s))
  | Receive_battle (params)     -> receive_battle_params(params, s)
  | Send_invite (params)        -> send_invite(params, s)
  end