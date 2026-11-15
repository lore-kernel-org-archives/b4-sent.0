From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH RFC net v4 0/8] net/iucv: serialize the HiperSockets
 receive path with the socket lock
Date: Sat, 14 Nov 2026 20:29:18 -0500
Message-Id: <20261114-b4-disp-fc0634a3-v4-0-f96c506447ce@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CQAxFr0K6tgmFYRLcmngAtsYFU4rWxUima
 EwId3eA5fs/7y1gklQMzsUCSb5q+o4Z3KkAfvbxIahDZqjKyhORw+BwUJtw5NLXrq+xJQ7UUMO
 tJ8jalGTU3568QXe9bFuUGe7HZ5/wEp63JqzrHzIaFPmAAAAA
X-Change-ID: 20261114-b4-disp-fc0634a3-91cb1515c961
To: Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Hidayath Khan <hidayath@linux.ibm.com>, Eric Dumazet <edumazet@kernel.org>
Cc: Thorsten Winkler <twinkler@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nagamani PV <nagamani@linux.ibm.com>, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794706158; l=10108;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=NNR0QywEUYNspRhbVSWl8eAEaherI5Lxm/o/sZprxBg=;
 b=CKu1SX5uOUbGMf5oe/VTsvzg+1Iz0SMTC8++X+/d99c8m878cxWf4YsXRHWaXbTHpZ8TRJ+N3
 ML0upHJH4JdAITGwV1e2RD90VMGL2dLMH7fnHEwoGR3KI+usPhAFCTS
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v4 of stage 1 of the socket-locking rework [1]. It is v3 [2] with the
two findings of the AI review of v3 fixed ([3] on 1/7, [4] on 3/7) and
the dev_hold() the netdev CI flagged replaced. Nobody else has reviewed
v3 yet, so the rest is unchanged.

  1/8  a msglimit changed while the SYN is out no longer closes the
       socket on a peer that kept to its window, nor stalls that peer
  2/8  iucv_send_ctrl() leaves sk_shutdown alone (new)
  3/8  sendmsg() fails with -EPIPE when sending is shut down while it
       waits for the window
  4/8  recvmsg() under lock_sock()
  5/8  the frame dispatch and three state changes moved into functions
       of their own, no functional change
  6/8  the HiperSockets rx path under the socket lock: a control frame
       waits for the task that owns the socket
  7/8  shutdown(SHUT_RD) against a frame in flight
  8/8  EOF, not -ENOTCONN, for a reader parked when the peer closes

1/8 to 3/8 and 8/8 are fixes in their own right. 1/8 to 3/8 each apply
to net without the rest; 3/8 is complete only on top of 2/8. 8/8 is
written on top of 6/8: its hunks are in functions that 4/8 and 5/8 add.

Alexandra, 2/8 needs your call. v3 dropped the iucv_send_ctrl() rewrite
as you asked, and 2/8 brings back one part of it: the function no longer
clears SEND_SHUTDOWN around its allocation. That clear is behind the
finding on v3 3/7 [4], behind the bit my copy of Hidayath's sk_shutdown
test loses, and behind the two items v3's notes left open under 2/7 and
7/7. The rest stays out: the allocation still asks for room in
sk_sndbuf, for every control frame. Is the SEND_SHUTDOWN part fine as a
patch of its own? If not I can fold it into 4/8; 3/8 then has the gap
the note of v3 2/7 described, up to 4/8.

RFC because one thing is missing that I can't provide. Hidayath,
Alexandra: could one of you run v4 on z/VM the way Hidayath ran v1 [5]?
I depend on those numbers: my setup was tuned against that run, and the
series moves enough code to need one again before this is a PATCH. What
I'd compare is below, with net as the baseline (the numbers from [5] in
parentheses, on net-next unless marked). Each line names the patch where
the code changes; the kernels I ran for it are under that patch:

- recvrecv (3917 backwards reads): 0 from 4/8 on
- sk_shutdown (565 of 7281 cycles): 0 from 2/8 on, as in my setup, or
  from 4/8 if that test also loses the bit the way 4/8's second item
  describes
- shut_rd (32 of 212): as net up to 5/8, 0 from 6/8 on. 6/8 leaves the
  window KCSAN reported on v1 [6], which shut_rd did not hit there and
  hits here only with a udelay() added to widen it; 7/8 closes it
- the blocked reader (-ENOTCONN in 13627 of 13627): EOF in all with 8/8
- rxclose (51 of 906): 0 with 8/8
- SO_MSGLIMIT lowered in IUCV_BOUND (1 message lost in 6297 cycles on
  v1; none on net-next, which has no budget): none lost at any step.
  The budget comes back with 6/8 and counts against the window of 1/8
- KCSAN: the 29 reports on net-next gone, the 6 between afiucv_hs_rcv()
  and iucv_send_ctrl() and the 2 between iucv_send_ctrl() and
  iucv_sock_shutdown() with 2/8, the 19 between recvmsg() and
  iucv_sock_shutdown() with 4/8, the 2 between afiucv_hs_rcv() and
  iucv_sock_shutdown() with 7/8. Up to 7/8 the receive wait still reads
  sk_shutdown with READ_ONCE() against shutdown()'s plain write, so a
  report of that pair can stay until then, and on a z/VM socket after
  it: 7/8 marks the write on the HiperSockets branch only. The hs_dev
  report of the v1 run [6] is not one of the 29; 1/2 of the two fixes
  posted for net on 28 Oct [7] is for it, and is not in this series

My setup is QEMU TCG with an emulated HiperSockets adapter and CP, so
rates and real SMP come only from the hardware, and I have no KCSAN
build of it. Where the two disagree, the hardware is the reference.

Changes in v4 (details below the --- of each patch):

- 1/8: a second SYN of the socket carries the window the first one gave
  and records nothing, and the window is recorded when the first SYN is
  handed to the device, not while its header is built (AI review [3])
- 2/8 is new, see above. With it the writer that 4/8 lets wait for send
  memory without the socket lock returns -EPIPE when shutdown(SHUT_WR)
  runs meanwhile; in v3 it could sleep through that wake-up (AI review
  [4])
- 6/8: the SYN that waits in the backlog holds its device with
  netdev_hold() and netdev_put() (netdev CI)
- 4/8 and 7/8: message only, for what 2/8 changes under them

Not in v4, and what that costs: five of my 53 default tests (the set v2
was tested with) fail on v4, as they do on net. With the three pieces
v3 dropped applied on top again (the rest of the iucv_send_ctrl()
rewrite, the window update only while connected, the credit reset), all
53 pass.

- iucv_send_ctrl() still needs room in sk_sndbuf for every control
  frame. With the send memory used up, which on HiperSockets lasts until
  TX completion, shutdown(SHUT_WR) sends no SHT and the peer never reads
  EOF (two tests), and the FIN of NETDEV_GOING_DOWN does not go out
  (one)
- recvmsg() still sends a window update after the peer's FIN, a frame
  nobody uses (one); [7] 2/2 has the test for it
- a window update that finds no room leaves its credit, and the SHT read
  next is counted past the window: WARN_ON() and -EFAULT where EOF was
  due (one). [7] 2/2 ends that by not counting the SHT

net fails three more: two that 3/8 fixes and one that 8/8 fixes.

Tested on s390x under QEMU TCG, KASAN + PROVE_LOCKING +
DEBUG_ATOMIC_SLEEP, on net main, against the emulated adapter under the
real qeth and qdio drivers and the emulated CP, as v3 was. Two vCPUs
under -icount, which runs one at a time; the race tests also with seeded
short slices, and the two-reader test of 4/8 under MTTCG. No KASAN or
lockdep splat on net, at any step of the series or on the kernels that
follow. Of 25 kernels each with one piece of the series taken out or
changed (6 for 1/8, 1 for 2/8, 3 for 3/8, 1 for 4/8, 10 for 6/8, 1 for
7/8, 3 for 8/8; the tracker build under 6/8 is not one of them), 23 fail
a test the series passes; two of the 23 need a test kernel under them,
one that drops the first SYN in the device (1/8) and one that makes two
waits overlap (2/8). The other two show only with a delay added to hold
their window open: the one without 7/8's spinlock and the one without
the receive-queue test in 8/8's wait. The numbers are below the --- of
each patch. Logs on request.

Still open, as in v3: afiucv_hs_callback_txnotify() and the z/VM
callbacks change sk_state without checking whether a task owns the
socket, and so does afiucv_netdev_event(), whose fix Nagamani is holding
for this series [8]. backlog_skb_q stays unbounded for a peer that
ignores its window. A listener with a full accept queue still leaks the
child of the SYN it refuses (measured on net and with the series,
numbers under 6/8), and so does a SYN|ACK that fails to go out (by
inspection) [9]. connect() tests sk_state before lock_sock(), so a
connected socket can still send a SYN [3]. On a z/VM socket
iucv_sock_shutdown() and recvmsg() update sk_shutdown under lock_sock()
and iucv_callback_shutdown() under bh_lock_sock(), so either side can
lose its bit, and iucv_callback_rx() tests RCV_SHUTDOWN with no lock:
7/8 takes the spinlock on the HiperSockets branch only. And
iucv_callback_connreq() answers a path request for a listener that
close() is emptying, the race 6/8 closes for a HiperSockets SYN.

Seen while working on v4, in net as well and not touched here:

- a HiperSockets recv() that owes a window update while the send memory
  is full sets IUCV_DISCONN: iucv_send_ctrl() finds no room and
  recvmsg() takes that for a dead path. It is the same failed update as
  in the last item of "Not in v4": that item is what the next read does
  with the credit, this one the state the socket is left in. Measured on
  net and with the series
- a z/VM sendmsg() that waits for send memory is not ended when the
  peer severs the path: the memory is freed only at close(). By
  inspection
- afiucv_hs_send() passes NET_XMIT_DROP through, so a send() or
  connect() whose frame the qdisc dropped returns 1. By inspection for
  the qdisc; the test kernel of 1/8 that drops the SYN shows the
  connect() half

[1] https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
[2] https://lore.kernel.org/netdev/20261110-b4-disp-2a6b4364-v3-0-35677b68e697@proton.me/
[3] https://lore.kernel.org/all/sashiko-outbox-210383@kernel.org/
[4] https://lore.kernel.org/all/sashiko-outbox-210385@kernel.org/
[5] https://lore.kernel.org/netdev/51a4a40a-f34b-4d41-b049-69aa53f4dcf5@linux.ibm.com/
[6] https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/
[7] https://lore.kernel.org/netdev/20261028-b4-disp-dd3e4ebb-v2-0-3747658d59bd@proton.me/
[8] https://lore.kernel.org/netdev/1d9d3cc1-24fb-40e0-a4c7-6fbfbcf4dc37@linux.ibm.com/
[9] https://lore.kernel.org/netdev/5f88daf4-cd8e-4464-b132-ac45be205121@linux.ibm.com/

---
Bryam Vargas (8):
      net/iucv: keep the window given to the peer in a field of its own
      net/iucv: do not clear SEND_SHUTDOWN to send a control frame
      net/iucv: fail sendmsg() with EPIPE once sending is shut down
      net/iucv: run recvmsg() under the socket lock
      net/iucv: factor out the HiperSockets frame dispatch and state changes
      net/iucv: serialize HiperSockets receive with the socket lock
      net/iucv: set RCV_SHUTDOWN under the socket spinlock
      net/iucv: return EOF to a reader parked when the peer closes

 include/net/iucv/af_iucv.h |   8 +
 net/iucv/af_iucv.c         | 687 +++++++++++++++++++++++++++++++++++++--------
 2 files changed, 579 insertions(+), 116 deletions(-)
---
base-commit: 8373c4e8863ac5f5120d200527aca9880330f343
change-id: 20261114-b4-disp-fc0634a3-91cb1515c961

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

