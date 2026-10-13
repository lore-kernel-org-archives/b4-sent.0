From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v7 0/4] net/smc: bound wire-controlled CDC cursors
 against the local buffers
Date: Tue, 13 Oct 2026 15:12:47 -0500
Message-Id: <20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMyw6CMBBFf4XctZP0Afj4FeOCtoOOi0o6aEwI/
 27B5bm55yxQLsKKS7Og8EdUXrnC8dAgPoZ8Z5JUGc643hrrKbSURCcafdvZcx/JDSl1p+BNvaB
 qU+FRvnvyiswzbv9R3+HJcd5iWNcfYaqtonkAAAA=
X-Change-ID: 20261013-b4-disp-f345196c-2add58b30202
To: "D. Wythe" <alibuda@linux.alibaba.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Eric Dumazet <edumazet@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>
Cc: netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-kernel@vger.kernel.org, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, linux-rdma@vger.kernel.org, 
 Stefan Raspl <raspl@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wen Gu <guwen@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791922368; l=6268;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=0Mq9mAy9c5Rr5BSJvIj8O8dUcb75ZTTaUNYy2n4r8Xw=;
 b=lyy8YMqdJxzssb89ZmmD0Vz3+1s/vCTeIun4unm3woGR/+IPGgfYPo1p/Vk1Z3pu9ezSWvShU
 +nMQx/aXXQIAAqy3sI6uZ38GiWea0Tc6Uz7dXmiNd7ykY92N/BrthvS
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A peer's CDC cursors come off the wire and are used, with no bound
against the local buffers, as a raw index into the RMB on the urgent
path (1/4), as the rx length (2/4), as the tx write space (3/4), and as
the cursor advance at SMC-R link failover (4/4). Any peer that completes
the SMC handshake controls them. With a forged cursor each use runs past
its buffer: an OOB read of kernel memory returned to the reader, send()
data written past the send buffer, or, at failover, an RDMA write whose
source and destination lie past the send buffer and the peer's RMB. Two
of these also happen with a conforming peer: a MSG_PEEK|MSG_WAITALL
reader racing another recv() (2/4), and late completions on the old
link after a failover (3/4).

With a second link in the group, the peer can force the failover: a
DELETE LINK request, or failing one of our RDMA writes, takes the link
down and switches the connections. Late completions need only ACKs on
the old link that arrive after the switch, from a degrading link or a
peer that delays them.

Bounding each cursor on arrival is not enough. A peer that only bumps
prod.wrap with count 0 hits the differing-wrap branch of
smc_curs_diff(), which returns the full buffer length on every CDC, so
bytes_to_rcv grows past the RMB while every cursor looks in range. IOW
the overflow is in the accumulator, not the cursor. 1/4 can clamp on
arrival because the urgent path indexes with the count itself; 2/4-4/4
bound the value where it is used. Hidayath Khan's "net/smc: abort the
connection when the peer overruns the RMB" [1] (net-next) drops the
connection at CDC receive; this series does not depend on it.

Tested on v7.3-rc6 with KASAN, over SMC-D loopback and over SMC-R on
rxe with two links, one end patched to forge its CDC cursors:
  - unpatched: recv(), MSG_PEEK|MSG_WAITALL, SO_RCVLOWAT and splice()
    read past the RMB, as does recv() once bytes_to_rcv wraps
    negative; the urgent byte comes from past the RMB; send() writes
    past the send buffer; after a failover with a forged consumer
    cursor the next RDMA write takes its source past the send buffer
    (rxe refuses that WR).
  - conforming peers, unpatched: the peek race reads past the RMB; a
    completion held back past the failover (a test hook makes the
    timing deterministic) leaves sndbuf_space at 3x the buffer, and
    send() writes past the send buffer.
  - v6 still reads past the RMB on a peek longer than two ring lengths
    and on repeated undrained splices.
  - v7: each case above stays inside its buffer, with no KASAN report,
    and no KMSAN report on the loopback runs.
  - dropping any one patch, or any one part of 2/4, makes a test fail
    again.
  - conforming traffic is unchanged: streams compared byte for byte,
    peek then recv, SO_RCVLOWAT, splice drained and undrained, urgent
    data inline and out-of-band, deferred accept, SIOCINQ and poll,
    nonblocking reads, close with unread data, failover mid-stream, a
    reader waiting while the link group is torn down.
Logs on request.

Changes in v7:
  - 2/4 (was v6 2/3): per Sashiko's reviews of v6 [2][3][5], MSG_PEEK
    and splice() offsets could start the copy outside the RMB, a local
    peek race [3] could leave the available length negative, and wrap
    bumps grow bytes_to_rcv (the accumulator case above). The bound
    moves into smc_rx_data_available(), counts peeked and spliced
    bytes, maps a negative length to 0, not a full ring, and covers
    the wait predicates too. The RMB length is cached in conn->rmb_len
    for the unlocked wait, and splice_pending now drops before the
    consumer cursor moves. New Fixes:, Reported-by: and Closes: tags;
    R-b dropped.
  - 4/4 is new: the failover cursor advance, which 3/4 does not cover.
  - 3/4: code unchanged. [4] noted that DMB merge runs only on the
    loopback device, so its peer is the local kernel; the message now
    leads with the over-credit after a failover, which needs no forged
    cursor, and says it bounds the copy. New Fixes:, R-b kept.
  - 1/4: code unchanged, comment and message reworded. R-b kept.
  - [6] (rmb_desc NULL before smc_buf_create()) is pre-existing; my
    fix for it, [7], is marked changes requested in patchwork and
    touches the same lines of __smc_buf_create() as 2/4.
  v6: https://lore.kernel.org/all/20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me/

Changes in v6: repost on net; 2/3 message corrected (the over-read goes
to the reader, not the peer); Sidraya Jayagond's R-b.
  v5: https://lore.kernel.org/all/20260723-b4-disp-0d07164f-v5-0-6a9e235dbc4e@proton.me/

Changes in v5: repost of v4.
  v4: https://lore.kernel.org/all/20260705-b4-disp-28a1bbca-v4-0-be089b98acc6@proton.me/

Changes in v4: split off the validate/abort change, per Dust Li.
  v3: https://lore.kernel.org/all/20260614-b4-disp-edd64be9-v3-0-551fa514257e@proton.me/

[1] https://lore.kernel.org/all/20260804141109.542202-1-hidayath@linux.ibm.com/
[2] https://lore.kernel.org/all/sashiko-outbox-164918@kernel.org/
[3] https://lore.kernel.org/all/179152807838.434549.2207466107170796457@kernel.org/
[4] https://lore.kernel.org/all/179152807992.434549.3295281690534839972@kernel.org/
[5] https://lore.kernel.org/all/179152807674.434549.14168488606722848951@kernel.org/
[6] https://lore.kernel.org/all/sashiko-outbox-164917@kernel.org/
[7] https://lore.kernel.org/all/20260728-b4-disp-52ee4e7d-v4-1-0dda94b0f397@proton.me/

---
Bryam Vargas (4):
      net/smc: bound the wire-controlled producer cursor to the RMB
      net/smc: bound the receive length to the RMB
      net/smc: bound the send length to the send buffer in smc_tx_sendmsg()
      net/smc: bound the link failover cursor advance to the send buffer

 net/smc/smc.h      |  3 +++
 net/smc/smc_cdc.h  | 17 ++++++++++++++---
 net/smc/smc_core.c | 15 +++++++++++----
 net/smc/smc_rx.c   |  7 ++++++-
 net/smc/smc_rx.h   | 11 ++++++++++-
 net/smc/smc_tx.c   |  8 ++++++++
 6 files changed, 52 insertions(+), 9 deletions(-)
---
base-commit: af32da41b0327b9c6a37856ba82b6760d6c8d10e
change-id: 20261013-b4-disp-f345196c-2add58b30202

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

