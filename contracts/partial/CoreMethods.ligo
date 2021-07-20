(* Helper function to get entrypoint that accepts a consumable ticket *)
function get_receiver_contract(
  const receiver        : address)
                        : contract(consumable_item_type) is
  case (Tezos.get_entrypoint_opt(
    "%receive_item",
     receiver)
     : option(contract(consumable_item_type))) of
    Some(contr) -> contr
    | None -> (failwith("Core/no-receive-contract") : contract(consumable_item_type))
  end;

(* Helper function to create internal account *)
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

(* Helper function to consumable ticket *)
function create_ticket (
  const id              : nat;
  const t_name          : string;
  const value           : nat;
  const t_amount        : nat)
                        : consumable_item_type is
  block{
    const token_data : consumable_type =
      record [
        id    = id;
        name  = t_name;
        value = value;
      ];
  } with Tezos.create_ticket (token_data, t_amount)

(* Helper function to create an initial sign up bonus*)
function create_reg_bonus (
  const _unit           : unit)
                        : consumable_item_type is
  block {

    // const start_weapon : consumable_item_type =
    //   create_ticket(2n, "Noob weapon ticket", 1n, 1n);

    const start_points : consumable_item_type =
      create_ticket(3n, "Noob stat point", 1n, 1n);

  } with start_points;

(* Helper function to clear arena lobby *)
function clear_lobby (
  const key             : lvl_type;
  var s                 : lobby_type)
                        : lobby_type   is
  block {
    remove key from map s
  } with s

(* Entrypoint to register internal account *)
function registration (
  const reg_ticket      : consumable_item_type;
  var s                 : storage_type)
                        : return is
  block {
    const t_info = read_ticket(reg_ticket);

    if t_info.ticketer = Tezos.self_address then skip
    else failwith("Core/unknown-ticketer");

    (* Validate ticket type *)
    if t_info.id = 0n then skip
    else failwith("Core/not-reg-ticket");

    (* Create internal account and send bonus *)
    s.accounts[Tezos.sender] := create_account(Tezos.sender, s);
    const bonus : consumable_item_type = create_reg_bonus(unit);
    const contr : contract(consumable_item_type)  = get_receiver_contract(Tezos.sender);
    const op = Tezos.transaction(bonus, 0mutez, contr);

} with (list[op], s)

(* Entrypoint to buy consumable item *)
function buy_item (
  const item_id         : item_id_type;
  const s               : storage_type)
                        : return is
  block {
  const arena_pass : consumable_item_type =
      create_ticket(item_id, "Arena pass", 1n, 1n);

  const contr = get_receiver_contract(Tezos.sender);
  const op = Tezos.transaction(arena_pass, 0mutez, contr);

} with (list[op], s)


(* Arena registration entry point *)
function go_pvp_arena (
  const params          : arena_params_type;
  var   s               : storage_type)
                        : storage_type is
  case params of
    record[arena_pass; hero_stats] -> block {
      const t_info = read_ticket(arena_pass);

      var account := get_account(Tezos.sender, s);
      if t_info.ticketer = Tezos.self_address then skip
      else failwith("Core/unknown-ticketer");

      if t_info.id = 1n then skip
      else failwith("Core/not-pvp-ticket");

      if t_info.value = hero_stats.lvl then skip
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
                total_pot   = acc.bet + t_info.value;
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
              account.current_duel := abs(arena.duel_id - 1n);
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
              account_2.current_duel := abs(arena.duel_id - 1n);

              accounts[account.addr]   := account;
              accounts[account_2.addr] := account;

            }
          | None     ->
            arena.lobby[hero_stats.lvl] := record[
                                            addr    = account.addr;
                                            bet     = t_info.value;
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

(* An entry point that accepts the parameters of a duel,
   and conducts a duel if both players are ready *)
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
    | None       -> failwith("Core/oops1")
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

      result := ((nil : list (operation)), s)
    } else {
      var account_1 := get_account(duel.hero_1, s);
      var account_2 := account;

      account_1.status := Free;
      account_2.status := Free;
      s.accounts[account_1.addr] := account_1;
      s.accounts[account_2.addr] := account_2;


      var round := case duel.rounds[duel.next_round] of
        Some(d) -> d
        | None  -> (failwith("Core/oops2") : (round_type))
      end;

      round.actions[account_2.addr] := params;

      var h1_action : p_action :=
      case round.actions[duel.hero_1] of
        Some(d) -> d
      | None  -> failwith("Core/oops3")
      end;

      // var hero_2_action : p_action :=
      // case round.actions[duel.hero_2] of
      //   Some(d) -> d
      // | None  -> failwith("Core/oops4")
      // end;
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
      duel.next_round := duel.next_round + 1n;
      arena.duels[account.current_duel] := duel;
      s.arena := arena;

      const money : consumable_item_type =
        create_ticket(4n, "Money", 1n, duel.total_pot);
      const exp : consumable_item_type =
        create_ticket(5n, "exp", 1n, 5n);

      const winner :address = case duel.winner of
        Some(w) -> w
        | None -> failwith("Core/oops5")
      end;
      const contr : contract(consumable_item_type)  = get_receiver_contract(winner);
      const op_1 = Tezos.transaction(money, 0mutez, contr);
      const op_2 = Tezos.transaction(exp, 0mutez, contr);
      result := (list[op_1; op_2], s);
    }
  } with result

(* Send ticket-invite *)
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
          create_ticket(0n, "Reg ticket", 1n, 1n);

    const contr = get_receiver_contract(receiver);

    const op = Tezos.transaction(invite, 0mutez, contr);

  } with (list[op], s)