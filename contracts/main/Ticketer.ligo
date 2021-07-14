type ticket_type is ticket(string)

// type storage_type is big_map(nat, ticket_type )

type storage_type       is [@layout:comb] record [
  tickets                : big_map(nat, ticket_type );
  ticket_id              : nat
]

type send_parameter_type is [@layout:comb] record [
  destination           : contract(ticket_type);
  ticket_id             : nat
]


type parameter_type is
    Mint                of string
  | Receive             of ticket_type
//  | Send                of send_parameter_type
type return is list (operation) * storage_type

type l is big_map(nat, ticket_type)

const ss : l = big_map[];


function mint_ticket (
    const i             : string;
    var s               : storage_type)
                        : return is
  block {
    var e :l := big_map[];
    const ticket : ticket_type = Tezos.create_ticket (i, 10n);
    const updated_map = case Big_map.get_and_update(0n, (Some (ticket)), e) of
    | (_, x) -> x
    end;
    s.tickets := updated_map;

  } with ((nil : list (operation)), s);


// function send_ticket (
//   const params          : send_parameter_type;
//   var s                 : storage_type)
//                         : return is
//   block {
//     var result : return := ((nil : list (operation)), s);
//     case Big_map.get_and_update(
//       params.ticket_id,
//       (None: option(ticket_type)), s.tickets) of
//     | (t, updated_map) -> {
//         const ticket : ticket_type = case t of
//                 Some(ticket) -> ticket
//               | None -> failwith("No tickets")
//               end;
//         result := (
//           list[
//             Tezos.transaction(
//               ticket,
//               0mutez,
//               params.destination
//             )
//           ], s);
//     }
//     end
//   } with result

function rec (
  const params          : ticket_type;
  var s                 : storage_type)
                        : storage_type is
block {
  const v : string =
    case (Tezos.read_ticket (params)) of
    | (content,ticket) -> (
      case content of
      | (addr,x) -> (
        case x of
        | (payload,amt) -> (
          payload
        ) end
      ) end
  ) end;
  failwith("sds")
} with s

// const v : int =
//   case (Tezos.read_ticket (my_ticket1)) of
//   | (content,ticket) -> (
//     case content of
//     | (addr,x) -> (
//       case x of
//       | (payload,amt) -> (
//         payload
//       ) end
//     ) end
//   ) end

function main(
  const action          : parameter_type;
  const s               : storage_type)
                        : return is
  case action of
      Mint (params)     -> (mint_ticket(params, s))
    | Receive (params)  -> ((nil : list(operation)), rec(params, s))
  end
  //     
//     | Send (params)     -> (send_ticket(params, s))