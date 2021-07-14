type ticket_type is ticket(string)

type storage_type is big_map(nat, ticket_type )


type send_parameter_type is [@layout:comb] record [
  destination           : contract(ticket_type);
  ticket_id             : nat
]


type parameter_type is
    Mint                of string
  | Send                of send_parameter_type

type return is list (operation) * storage_type

type l is big_map(nat, ticket_type)

const ss : l = big_map[];


function mint_ticket (
    const i             : string;
    var s               : storage_type)
                        : return is
  block {

    const ticket : ticket_type = Tezos.create_ticket (i, 10n);
    const res = Big_map.get_and_update(0n, (Some (ticket)), s);
    var res : return := ((nil : list (operation)), s);
    case res of
    | (_, x) -> res := ((nil : list (operation)), x)
    end
  } with res


function send_ticket (
    const params        : send_parameter_type;
    var s               : storage_type)
                        : return is
  block {
    var res : return := ((nil : list (operation)), s);
    case Big_map.get_and_update(params.ticket_id, (None: option(ticket_type)), s) of
      (Some(ticket), x)     ->
        res := (
            list[
              Tezos.transaction(
                ticket,
                0mutez,
                params.destination
              )
            ], x)
    | None  -> (failwith("no-tickets") : ((nil : list (operation)), s))
    end;
  } with res

// function send_ticket (
//     const params        : send_parameter_type;
//     var s               : storage_type)
//                         : return is
//   case Big_map.get_and_update(params.ticket_id, (None: option(ticket_type)), s) of
//     (Some(ticket), x)     ->
//           (
//             list[
//               Tezos.transaction(
//                 ticket,
//                 0mutez,
//                 params.destination
//               )
//             ], x)
//   | None  -> (failwith("no-tickets") : ((nil : list (operation)), s))

//   end;


function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Mint (params)     -> (mint_ticket(params, s))
    | Send (params)     -> (send_ticket(params, s))
  end
