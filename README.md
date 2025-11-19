# FIFO

First simulation:

```
wfull=0
rempty=1
[0] FIFO is empty. Start of simulation
WRITE: addr=0 data=0
WRITE: addr=1 data=1
WRITE: addr=2 data=2
WRITE: addr=3 data=3
WRITE: addr=4 data=4
rempty=0
WRITE: addr=5 data=5
WRITE: addr=6 data=6
WRITE: addr=7 data=7
WRITE: addr=8 data=8
WRITE: addr=9 data=9
WRITE: addr=10 data=a
WRITE: addr=11 data=b
WRITE: addr=12 data=c
WRITE: addr=13 data=d
WRITE: addr=14 data=e
WRITE: addr=15 data=f
wfull=1
[175000] FIFO is full
READ:  addr=1 data=1
READ:  addr=2 data=2
wfull=0
READ:  addr=3 data=3
READ:  addr=4 data=4
READ:  addr=5 data=5
READ:  addr=6 data=6
READ:  addr=7 data=7
READ:  addr=8 data=8
READ:  addr=9 data=9
READ:  addr=10 data=a
READ:  addr=11 data=b
READ:  addr=12 data=c
READ:  addr=13 data=d
READ:  addr=14 data=e
READ:  addr=15 data=f
rempty=1

[413000] FIFO is empty again. Test complete
READ:  addr=0 data=0
```

