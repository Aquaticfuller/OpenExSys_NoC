# OpenExSys_NoC
OpenExSys_NoC is a mesh-based network on chip IP.

## Getting Started

### Simulation

Currently, OpenExSys_NoC uses *vcs* for simulation.

```sh
# set environment varibales
source env/sourceme
# go to the tb folder
cd tb
# Compile the sources, with a mesh configuration
make mesh
# Run the simulation
make run
```

### Architecture

Please refer to [Architecture](./doc/noc_spec.md)

### Router Interface Signals

Please refer to [Interface](./doc/noc_intf.md).

### Tester

The NoC tester is a unit test environment for this IP. It consists of following components:

![alt noc_tester](./doc/image/noc_tester.png)

**Test Generator**, which generates test packages according to the specified test policy and sends 
them to the sender. We have implemented several commonly used synthetic traffic patterns for users 
to choose from.

| Name           | Pattern                                                                                                                                        |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Uniform Random | Generates a random destination ID from the available destinations.                                                                             |
| Diagonal       | Packets move diagonally across the network from one corner to the opposite corner.                                                             |
| Bit Complement | Computes the destination node as the complement of the source node's position in the mesh network.                                             |
| Bit Reverse    | Computes the destination node as the bit-reversed index of the source node in the mesh network.                                                |
| Bit Rotation   | Computes the destination node by rotating the source node's ID by one bit                                                                      |
| Neighbor       | Packets are sent from a node to its neighbor node in a fixed order.                                                                            |
| Shuffle        | The network is divided into several smaller subnetworks, and packets are shuffled within each subnetwork before being sent to the destination. |
| Transpose      | Packets move between nodes on the same row and column, forming a transpose-like pattern.                                                       |
| Tornado        | Packets move in a pattern that resembles a tornado, starting from one corner of the network and moving towards the opposite corner.            |

**Sender**, which then injects packages generated by test generator into the design under test (DUT) 
for processing.

**Routing Monitor**, which checkes the routing path when each middle router receives 
the package. In case of a mismatch between the expected and the actual
routing path, the routing monitor invokes the wrong routing path error. This component
helps in ensuring that the routing path of the test packages is correct, and the packets are
flowing through the correct path.

**Receiver**, which extracts the packages out of the DUT and refers to the
scoreboard for target node ID checking. The scoreboard, as the name suggests, is
responsible for keeping a score of the packets and their state at various stages of the
verification process. It performs several functions such as adding a new entry when a
sender injects a package into the DUT, removing an old entry when the receiver extracts
a package out of the DUT, and checking the entry when the receiver receives a package
from the DUT.

**Scoreboard**, which indexes the entry by source node ID and transaction ID and checks
the target node ID against the receiver's node ID. If there is a mismatch, it invokes the
wrong target error. Additionally, the scoreboard invokes an inflight package timeout
error when one of the inflight entries' wait time reaches the timeout line. It is
responsible for ensuring the correctness of the target node ID and maintaining the state
of the packages throughout the verification process.
The scoreboard entry can record the routing path when added, and the routing path
check is performed when each middle routers receive a package. In case of a mismatch,
the routing monitor invokes the wrong routing path error. This component ensures that
the routing path of the packets is maintained throughout the verification process.

