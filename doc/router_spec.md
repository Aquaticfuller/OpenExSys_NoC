# Router Spec
# 1 Routing Algorithm
Use XY routing, the routing result is calculated one hop ahead, which is look-ahead routing

## 1.1 XY Routing
Flits firstly go through X axis, then go though Y axis:
```
  1st phase: Assign next address
  2nd phase: Define new Next-port
```
## 1.2 Look-ahead Routing

# 2 Input Port
## 2.1 Input VC

1. Use Fixed VC Assignment with Dynamic VC Allocation (FVADA) [paper](https://sites.pitt.edu/~juy9/papers/Yi-HPCA10.pdf) vc allocation mechanism. The input VCs are associated with the flits' output port.
2. XY routing, so some of the output port are not used in some input ports.

* VC in each input port:

| input port | input port id | vc id | assigned output port | output port id |
| ---------- | ------------- | ----- | -------------------- | -------------- |
| N          | 0             | 0     | S                    | 1              |
|            |               | 1     | L                    | 4              |
| S          | 1             | 0     | N                    | 0              |
|            |               | 1     | L                    | 4              |
| E          | 2             | 0     | N                    | 0              |
|            |               | 1     | S                    | 1              |
|            |               | 2     | W                    | 3              |
|            |               | 3     | L                    | 4              |
| W          | 3             | 0     | N                    | 0              |
|            |               | 1     | S                    | 1              |
|            |               | 2     | E                    | 2              |
|            |               | 3     | L                    | 4              |
| L          | 4             | 0     | N                    | 0              |
|            |               | 1     | S                    | 1              |
|            |               | 2     | E                    | 2              |
|            |               | 3     | W                    | 3              |


# 3 Switch Allocation

Use two-stage input-port-first allocation.

## 3.1 Local allocation
Use round robin arbition. As XY routing, the local arbiters' input port number are not the same.

## 3.2 Global allocation

Use round robin arbition. As XY routing, the global arbiters' input port number are not the same.

* input output port mapping for each SA global arbiter:

| output port | global SA arbiter connected input ports | global SA arbiter connected input ports id | next hop input port |
| ----------- | --------------------------------------- | ------------------------------------------ | ------------------- |
| N           | S                                       | 1                                          | S                   |
|             | E                                       | 2                                          |                     |
|             | W                                       | 3                                          |                     |
|             | L                                       | 4                                          |                     |
| S           | N                                       | 0                                          | N                   |
|             | E                                       | 2                                          |                     |
|             | W                                       | 3                                          |                     |
|             | L                                       | 4                                          |                     |
| E           | W                                       | 3                                          | W                   |
|             | L                                       | 4                                          |                     |
| W           | E                                       | 2                                          | E                   |
|             | L                                       | 4                                          |                     |
| L           | N                                       | 0                                          | -                   |
|             | S                                       | 1                                          |                     |
|             | E                                       | 2                                          |                     |
|             | W                                       | 3                                          |                     |



# 4 QoS

## 4.1 Common QoS
  No special vc, all vc head flits ranked by QoS value.
  * no extra real-time vc; 
  * no bypass arbiter for real-time vc; 
  * all vc involve QoS value compare.

## 4.2 Common QoS + extra real-time vc QoS
  Add special vc for highest priority flits, all vc head flits ranked by QoS value.
  * have extra real-time vc; 
  * no bypass arbiter for real-time vc; 
  * the real-time vc always win the local sa, and the local sa rr point should not be updated
  * the real-time vc join global sa as common QoS, as it has highest QoS value, it can beat flits with other QoS value;
  * all vc involve QoS value compare.

## 4.3 extra real-time vc QoS + bypass switch allocation + no common QoS
  Add special vc for highest priority flits, other vc head flits have no QoS support.
  * have extra real-time vc; 
  * have bypass arbiter for real-time vc; 
  * non-highest-priority vc have no QoS support.
  * the real-time vc bypass local sa, and override common rr arbiter's result;
  * the real-time vc from all possible inport use a separate rr arbiter at per global sa, and override common rr arbiter's result;

  It can have the same real-time support as 4.2, but may have better timing.
