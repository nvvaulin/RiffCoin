pragma solidity ^0.4.0;

contract ReefCoin{
    struct Order{
        bool done;
        bool locked_money;
        bool created;
        bool seller_confurm;
        bool arbitr_confurm;
        address customer;
        address seller;
        address arbitrator;
        
        uint price;
        uint arbitr_price;
        uint arbitr_status;///0-not confirm ; 1 -- confirm ; 
        uint arbitr_fine;
        uint time_confirm;
        uint time_arbitr;
        uint time_cashback;
    }
    
    mapping(address => uint256) wallet;
    mapping(uint256 => Order) orders;
    
    function create_order(address customer,uint256 order_id,Order order){
        if(msg.sender != customer || order.customer != msg.sender){
            return ;
        }
        if(orders[order_id].created){
            return ;
        }
        order.seller_confurm  = false;
        order.arbitr_confurm  = false;
        order.locked_money = false;
        order.done = false;
        order.created = true;
        orders[order_id] = order;
    }
    
    function seller_confurm(address seller,uint256 order_id){
        if(!orders[order_id].created){
            return ;
        }
        Order order = orders[order_id];
        if(msg.sender != seller || order.seller != msg.sender || order.done){
            return ;
        }
        orders[order_id].seller_confurm = true;
        lock_money(order_id);
    }
    
    function lock_money(uint256 order_id) constant returns (bool){
        Order order = orders[order_id];
        if(wallet[order.customer] >= order.price+order.arbitr_price && wallet[order.seller] >= order.arbitr_price && wallet[order.arbitrator] >= order.arbitr_fine && order.created && !order.locked_money && order.seller_confurm && order.arbitr_confurm && !order.done){
            wallet[order.customer] -= order.price+order.arbitr_price;
            wallet[order.seller] -= order.arbitr_price;
            wallet[order.arbitrator] -= order.arbitr_fine;
            orders[order_id].locked_money = true;
            return true;
        }else{
            return false;
        }
        return false;
    }
    
    function arbitr_confurm(address arbitrator,uint256 order_id){
        if(!orders[order_id].created){
            return ;
        }
        Order order = orders[order_id];
        if(msg.sender != arbitrator || order.arbitrator != msg.sender || order.done){
            return ;
        }
        orders[order_id].arbitr_confurm = true;
        if(order.seller_confurm){
            lock_money(order_id);
        }
    }
    
    function done(address customer,uint256 order_id){
        if(!orders[order_id].created){
            return ;
        }
        Order order = orders[order_id];
        if(msg.sender != customer || order.done){
            return ;
        }
        wallet[order.seller] += order.price+order.arbitr_price;
        wallet[order.customer] += order.arbitr_price;
        wallet[order.arbitrator] += order.arbitr_fine;
        orders[order_id].done = true;
    }
    
    function arbitr_solution(address arbitrator,uint256 order_id,uint money_to_seller){
        if(!orders[order_id].created || order.done){
            return ;
        }
        Order order = orders[order_id];
        if(msg.sender != arbitrator || order.arbitrator != msg.sender || order.done || money_to_seller > order.price || order.time_arbitr < now){
            return ;
        }
        uint money_to_a_from_c = (((money_to_seller*100)/order.price)*order.arbitr_price)/100;
        uint money_to_a_from_s = order.arbitr_price-money_to_a_from_c;
        
        wallet[order.seller] +=  order.price+money_to_seller-money_to_a_from_s;
        wallet[order.customer] += order.price-money_to_seller-money_to_a_from_c;
        wallet[order.arbitrator] += order.arbitr_fine;
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
