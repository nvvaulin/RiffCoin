pragma solidity ^0.4.0;

contract Order {
    enum State { WAITING_FOR_SELLER_APPROVAL, WAITING_FOR_ARBITER_APPROVAL, IN_PROGRESS, DISPUTED, SUCCESS, FAILURE }

    State public state;

    struct Info {
	    address buyer;
	    address seller;
	    address arbiter;

	    uint price;
	    /*
	    uint arbitr_price;
	    uint arbitr_fine;
	    uint time_confirm;
	    uint time_arbitr;
	    uint time_cashback;
	    */

	    string info;
    }

    Info public info;

    modifier onlyBy(address[] accounts) {
	    bool in_accounts = false;
	    for (uint i = 0; i < accounts.length; i++) {
		    if (accounts[i] == msg.sender) {
			    in_accounts = true;
			    break;
		    }
	    }
	    require(in_accounts);
	    _;
    }

    modifier condition(bool _condition) {
	    require(_condition);
	    _;
    }

    modifier inState(State _state) {
	    require(state == _state);
    }

    function sellerApprove(bool decision)
    	onlyBy([info.seller]),
	inState(State.WAITING_FOR_SELLER_APPROVAL) {
		if (decision) {
			state = State.IN_PROGRESS;
		} else {
			state = State.FAILURE;
		}
	}

    function arbiterApprove(bool decision)
    	onlyBy([info.arbiter]),
	inState(State.WAITING_FOR_SELLER_APPROVAL) {
		if (decision) {
			state = State.IN_PROGRESS;
		} else {
			state = State.FAILURE;
		}
	}

    function buyerConfirm() 
	    onlyBy([info.buyer]),
	    inState(State.IN_PROGRESS) {
		    state = State.SUCCESS;
		    // TODO
    }

    function sellerRefund()
	    onlyBy([info.seller]),
	    inState(State.IN_PROGRESS) {
	    state = State.FAILURE;
    }

    function dispute()
	    onlyBy([info.seller, info.buyer]),
	    inState(State.IN_PROGRESS) {
		    state = State.DISPUTED;
		    //TODO
    }

    function resolve_dispute(bool buyer_wins)
    onlyBy([info.arbiter]),
    inState(State.DISPUTED) {
	    // TODO
    }
}

contract ReefCoin {
	mapping(address => uint[]) buyHistory;
	mapping(address => uint[]) sellHistory;
	mapping(address => uint[]) arbiterHistory;

	mapping(address => uint256) balanceOf;

	Order[] orders;

	function createOrder(address seller, address arbiter, uint price, string info) {
		Order memory current_order;
		current_order.state = Order.State.CREATED;
		current_order.buyer = msg.sender;
		current_order.seller = seller;
		current_order.arbiter = arbiter;
		current_order.price = price;
		current_order.info = info;
		orders.push(current_order);
	}

	function seller_confirm(address seller, uint256 order_id) {
		if(!orders[order_id].created){
			return ;
		}
		Order order = orders[order_id];
		if(msg.sender != seller || order.seller != msg.sender || order.done || order.time_confirm <= now){
			return ;
		}
		orders[order_id].seller_confirm = true;
		lock_money(order_id);
	}

	function lock_money(uint256 order_id) constant returns (bool){
		Order order = orders[order_id];
		if(wallet[order.customer] >= order.price+order.arbitr_price && wallet[order.seller] >= order.arbitr_price && wallet[order.arbiter] >= order.arbitr_fine && order.created && !order.locked_money && order.seller_confirm && order.arbitr_confirm && !order.done){
			wallet[order.customer] -= order.price+order.arbitr_price;
			wallet[order.seller] -= order.arbitr_price;
			wallet[order.arbiter] -= order.arbitr_fine;
			orders[order_id].locked_money = true;
			return true;
		}else{
			return false;
		}
		return false;
	}

	function arbitr_confirm(address arbiter,uint256 order_id){
		if(!orders[order_id].created){
			return ;
		}
		Order order = orders[order_id];
		if(msg.sender != arbiter || order.arbiter != msg.sender || order.done){
			return ;
		}
		orders[order_id].arbitr_confirm = true;
		if(order.seller_confirm){
			lock_money(order_id);
		}
	}

	function done(address customer,uint256 order_id){
		if(!orders[order_id].created){
			return ;
		}
		Order order = orders[order_id];
		if (msg.sender != customer || order.done){
			return ;
		}
		wallet[order.seller] += order.price+order.arbitr_price;
		wallet[order.customer] += order.arbitr_price;
		wallet[order.arbiter] += order.arbitr_fine;
		orders[order_id].done = true;
	}

	function arbitr_solution(address arbiter,uint256 order_id,uint money_to_seller){
		if(!orders[order_id].created || order.done){
			return ;
		}
		Order order = orders[order_id];
		if(msg.sender != arbiter || order.arbiter != msg.sender || order.done || money_to_seller > order.price || order.time_arbitr < now){
			return ;
		}
		uint money_to_a_from_c = (((money_to_seller*100)/order.price)*order.arbitr_price)/100;
		uint money_to_a_from_s = order.arbitr_price-money_to_a_from_c;

		wallet[order.seller] +=  order.price+money_to_seller-money_to_a_from_s;
		wallet[order.customer] += order.price-money_to_seller-money_to_a_from_c;
		wallet[order.arbiter] += order.arbitr_fine;
		orders[order_id].done = true;
	}

	function cashback(address sender,uint256 order_id){
		if(!orders[order_id].created){
			return ;
		}
		Order order = orders[order_id];
		if(msg.sender != sender || (order.seller != msg.sender && order.customer != msg.sender ) || order.done){
			return ;
		}
		wallet[order.seller] += order.price+order.arbitr_price+order.arbitr_fine;
		wallet[order.customer] += order.arbitr_price;
		orders[order_id].done = true;

	}

}
