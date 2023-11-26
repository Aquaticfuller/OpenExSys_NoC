for chi, the least significant bit represents:

| field | width                 | bits in flit                                                   | comments                                                                        |
| ----- | --------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| QoS   | 4                     | [0:3]                                                          | ascending values of QoS indicate higher priority levels, not used, place holder |
| TgtID | NodeID_Width, 7 to 11 | [4:4+NodeID_Width-1]                                           | node ID of the component to which the message is targeted                       |
| SrcID | NodeID_Width, 7 to 11 | [4+NodeID_Width:4+NodeID_Width+NodeID_Width-1]                 | node ID of the component from which the message is sent                         |
| TxnID | 12                    | [4+NodeID_Width+NodeID_Width:4+NodeID_Width+NodeID_Width+12-1] | transaction identifier of the message                                           |