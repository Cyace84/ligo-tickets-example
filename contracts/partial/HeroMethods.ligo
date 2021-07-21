(* Helper function to get reg entrypoint *)
function get_reg_contract(
  const addr            : address)
                        : contract(consumable_item_type) is
  case (Tezos.get_entrypoint_opt(
    "%registration",
    addr)
    : option(contract(consumable_item_type))) of
    Some(contr) -> contr
  | None -> (failwith("Hero/no-reg-contract") : contract(consumable_item_type))
  end;

(* Helper function to get reg pvp arena entrypoint *)
function get_reg_arena_contract(
  const addr            : address)
                        : contract(arena_params_type) is
  case (Tezos.get_entrypoint_opt(
    "%go_pvp_arena",
    addr)
    : option(contract(arena_params_type))) of
    Some(contr) -> contr
  | None -> (failwith("Hero/no-pvp-contract") : contract(arena_params_type))
  end;

(* Helper function to get buy item entrypoint *)
function get_shop_contract(
  const addr            : address)
                        : contract(item_id_type) is
  case (Tezos.get_entrypoint_opt(
    "%buy_item",
    addr)
    : option(contract(item_id_type))) of
    Some(contr) -> contr
  | None -> (failwith("Hero/no-shop-contract") : contract(item_id_type))
  end;

(* Helper function to get battle entrypoint *)
function get_pvp_contract(
  const addr            : address)
                        : contract(send_pvp_params) is
  case (Tezos.get_entrypoint_opt(
    "%receive_battle",
    addr)
    : option(contract(send_pvp_params))) of
    Some(contr) -> contr
  | None -> (failwith("Hero/no-pvp-contract") : contract(send_pvp_params))
  end;

(* Helper function to get and sort inv *)
function get_item(
  const next_slot_item   : nat;
  const item_id          : nat;
  const consumable_items : map_items_type)
                         : return_consumable_item is
    block{
      const updated_items =
        case Big_map.get_and_update(
          item_id,
          (None: option(consumable_item_type)),
          consumable_items) of
          (t, _updated_tickets) -> block {
            const ticket : consumable_item_type = case t of
              Some(ticket) -> ticket
            | None -> failwith("Hero/no-item")
            end;
            const updated_tickets =_updated_tickets;
          } with record[ticket=ticket;updated_tickets=updated_tickets]
        end;

      (* Sort inventory *)
      const result =
      case updated_items of
        record[ticket; updated_tickets] -> block {
          const sorted_items = if abs(next_slot_item - 1n) = 0n
          then updated_tickets
          else block {
            const sorted_items =
            if abs(next_slot_item - 1n) = item_id
            then updated_tickets
            else case Big_map.get_and_update(
              abs(next_slot_item - 1n),
              (None: option(consumable_item_type)),
              updated_tickets) of
              (t, updated_tickets) ->
                case Big_map.get_and_update(
                  item_id,
                  t,
                  updated_tickets
                ) of
                  (_, sorted_tickets) -> sorted_tickets
                end
            end
          } with sorted_items
        } with record[ticket=ticket;updated_tickets=sorted_items]
      end
    } with result


function activate_account(
  const item_id         : item_id_type;
  const s               : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] ->
      case inventory of
        record[
          weapons;
          consumable_items;
          inventory_size;
          next_slot_weapon;
          next_slot_item;
        ]             ->
          case get_item(next_slot_item, item_id, consumable_items) of
            record[ticket; updated_tickets] ->
              block {
                const contr : contract(consumable_item_type) =
                  get_reg_contract(game_server);
                const op = Tezos.transaction (
                  ticket,
                  0mutez,
                  contr
                );

                const updated_storage = record[
                  owner        = owner;
                  game_server  = game_server;
                  nickname     = nickname;
                  inventory    = record[
                    weapons           = weapons;
                    consumable_items  = updated_tickets;
                    inventory_size    = inventory_size;
                    next_slot_weapon  = next_slot_weapon;
                    next_slot_item    = abs(next_slot_item -1n);];
                  stats        = stats;
                  equip        = equip;
                  hp           = hp;
                  damage       = damage;
                  exp          = exp;
                  lvl          = lvl;
                ];
            } with (list[op], updated_storage)
          end
      end
  end;


function equip_item(
  const _item_id        : item_id_type;
  const _s              : storage_type)
                        : storage_type is
  block {
    // if Tezos.sender = s.owner then skip
    // else failwith("not-owner");
    skip

} with _s

function unequip_item(
  const _slot_id        : slot_id_type;
  const _s              : storage_type)
                        : storage_type is
  block {
    skip
} with _s

function buy_item(
  const item_id         : item_id_type;
  const s               : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> block {
      const contr = get_shop_contract(game_server);
      const op = Tezos.transaction (
        item_id,
        0mutez,
        contr
        );
      const updated_storage = record[
        owner        = owner;
        game_server  = game_server;
        nickname     = nickname;
        inventory    = inventory;
        stats        = stats;
        equip        = equip;
        hp           = hp;
        damage       = damage;
        exp          = exp;
        lvl          = lvl;
      ];
    } with (list[op], updated_storage)
  end

function use_item(
  const _item_id        : item_id_type;
  const _s               : storage_type)
                        : storage_type is
  block {
    skip
} with _s

function receive_item (
  const new_item        : consumable_item_type;
  var s                 : storage_type)
                        : storage_type is
    case s of
      record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] ->
        case inventory of
          record[
            weapons;
            consumable_items;
            inventory_size;
            next_slot_weapon;
            next_slot_item;]
            -> block {
              // const t_info = read_ticket(new_item);
              if inventory_size >= next_slot_item
              then skip
              else failwith("Hero/full-inventory");

              const updated_items =
                case Big_map.get_and_update(
                  next_slot_item,
                  Some (new_item),
                  consumable_items) of
                  (_, updated_tickets) -> updated_tickets
                end;

            } with record[
                    owner        = owner;
                    game_server  = game_server;
                    nickname     = nickname;
                    inventory    = record[
                      weapons           = weapons;
                      consumable_items  = updated_items;
                      inventory_size    = inventory_size;
                      next_slot_weapon  = next_slot_weapon;
                      next_slot_item    = next_slot_item + 1n;];
                    stats        = stats;
                    equip        = equip;
                    hp           = hp;
                    damage       = damage;
                    exp          = exp;
                    lvl          = lvl;
                  ]
        end
    end

(* Registration pvp arena *)
function reg_arena (
  const item_id         : item_id_type;
  var s                 : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] ->
      case inventory of
        record[
          weapons;
          consumable_items;
          inventory_size;
          next_slot_weapon;
          next_slot_item;
        ]             ->
          case get_item(next_slot_item, item_id, consumable_items) of
            record[ticket; updated_tickets] ->
              block {
                const contr = get_reg_arena_contract(game_server);
                const arena_params = record[
                arena_pass = ticket;
                hero_stats = record[
                  lvl    = lvl;
                  hp     = hp;
                  damage = damage;
                  str    = stats.str;
                  con    = stats.con;
                  dex    = stats.dex;
                  acc    = stats.acc;
                ]
                ];
                const op = Tezos.transaction (
                  arena_params,
                  0mutez,
                  contr
                );
                const updated_storage = record[
                  owner        = owner;
                  game_server  = game_server;
                  nickname     = nickname;
                  inventory    = record[
                    weapons           = weapons;
                    consumable_items  = updated_tickets;
                    inventory_size    = inventory_size;
                    next_slot_weapon  = next_slot_weapon;
                    next_slot_item    = abs(next_slot_item -1n);];
                  stats        = stats;
                  equip        = equip;
                  hp           = hp;
                  damage       = damage;
                  exp          = exp;
                  lvl          = lvl;
                ];
              } with (list[op], updated_storage)
          end
      end
  end


function go_pvp (
  const params          : send_pvp_params;
  var s                 : storage_type)
                        : return is
  case s of
    record[owner; game_server; nickname; inventory; stats; equip; hp; damage; exp; lvl ] -> block {
      const contr = get_pvp_contract(game_server);
      const op = Tezos.transaction (
        params,
        0mutez,
        contr
      );
      const updated_storage : storage_type = record[
        owner        = owner;
        game_server  = game_server;
        nickname     = nickname;
        inventory    = inventory;
        stats        = stats;
        equip        = equip;
        hp           = hp;
        damage       = damage;
        exp          = exp;
        lvl          = lvl;
      ];
    } with (list[op], updated_storage)
  end
