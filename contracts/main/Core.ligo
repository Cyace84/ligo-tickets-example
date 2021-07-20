#include "../partial/Items.ligo"
#include "../partial/CoreTypes.ligo"
#include "../partial/Common.ligo"
#include "../partial/CoreMethods.ligo"


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
  | Buy_item (params)           -> buy_item (params, s)
  | Go_pvp_arena (params)       -> ((nil : list (operation)), go_pvp_arena (params, s))
  | Receive_battle (params)     -> receive_battle_params(params, s)
  | Send_invite (params)        -> send_invite(params, s)
  end