From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v6 0/3] net/smc: bound wire-controlled CDC cursors
 against the local buffers
Date: Thu, 08 Oct 2026 01:12:40 -0500
Message-Id: <20261008-b4-disp-f7cd3d96-v6-0-fba616c0920c@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L2zCZtkQp8xXiQ7laXQyFdNCaEv
 1vwOJPMbKCchRWGaoPMH1GZUwFfVxBej/RkFCoMzjhvjelwvCCJLhivgRrqPcbYup661jaWoWR
 L5ijfc3mDxCvc/1Lf48RhPWaw7z8FPJpueQAAAA==
X-Change-ID: 20261008-b4-disp-f7cd3d96-ff529d85131e
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>
Cc: Stefan Raspl <raspl@linux.ibm.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org, Wen Gu <guwen@linux.alibaba.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791439960; l=5161;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=b2D7UJOTp4Q381AzAEMvlY/m317vHpKUmpUbQgiil+4=;
 b=68DKpAK+BCbBE6JN7kTHEbxjPGknZWilTbmtkIOOy6hekDjXwa+0zMW8WNMjyR8B8rp7ZiKc/
 FfUpE1/6mdRBCQAcrODQuHj/GbaMXqrpUG5qIf+QwHnP9EaTr3OHwgL
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A peer's CDC producer/consumer cursors are copied from the wire and used,
without an upper bound against the local buffers, as (a) a raw index into the
RMB on the urgent path, (b) the receive length in smc_rx_recvmsg(), and (c) the
send length in smc_tx_sendmsg() on the SMC-D DMB-merge path. A malicious or
buggy peer can forge a cursor so each runs past the relevant buffer: on the
rx/urgent side an OOB read of adjacent kernel memory, returned to the
receiving process; on the tx side an OOB write whose length the peer
controls and whose overflowing bytes are the local sender's own outbound
data.

This series bounds each length where it is consumed. Each clamp checks the
local copy of the counter that the copy length is then taken from, so the
tasklet advancing the counter cannot get between the check and the use.

The clamp is not subsumed by validating each cursor at the input boundary. A
peer that only increments prod.wrap with count == 0 hits the differing-wrap
branch of smc_curs_diff(), which returns (len - 0) + 0 == len every CDC, so
bytes_to_rcv (and sndbuf_space on the send side) accumulates past the buffer
while every per-cursor bound sees count == 0 and accepts the message. IOW the
overflow lives in the accumulator, not the cursor. Hidayath Khan's "net/smc:
abort the connection when the peer overruns the RMB" rejects that accumulation
on the receive side at the CDC boundary; these clamps bound each consumer and
do not depend on it.

The nearby readable >= rmb_desc->len / len > sndbuf_desc->len tests only feed
stats counters (SMC_STAT_RMB_RX_FULL / SMC_STAT_RMB_TX_SIZE_SMALL) on an
earlier, separate read; they do not bound the copy.

A/B (in-kernel KASAN replaying the sink arithmetic over a real rmb_desc->len /
sndbuf_desc->len slab; kasan.fault=report kasan_multi_shot, 2026-07-05):
  - urgent index (1/3):  count = len+1        -> slab-out-of-bounds Read;  clamped -> clean
  - recv length  (2/3):  bytes_to_rcv = 5*len via wrap++/count=0 -> OOB Read; clamped -> clean
  - send length  (3/3):  sndbuf_space inflated -> slab-out-of-bounds Write; clamped -> clean
  - signed overflow:     readable = -1 -> v1 ">len" misses -> OOB; "<0 || >len" -> clean
  - concurrent TOCTOU race: a producer-side clamp is racy (OOB in a racing consumer
    kthread on another CPU); the consumer-side clamp: 0 hits in 5,000,000 reads.
  - every in-bounds / honest-peer arm: clean.
End to end over SMC-D loopback, re-run 2026-10-08 on v7.3-rc6 with this
series applied (two AF_SMC sockets, the sender forging wrap++/count=0,
rmb_desc->len 65504; the bound comes from 2/3 itself, not a modeled clamp):
bytes_to_rcv reaches 6*len in both arms. Unpatched, recv() returns 393024
and the second chunk is a 327520-byte read from ring offset 0 whose last
262016 bytes lie past the RMB; KASAN reports it from smc_rx_recvmsg as
use-after-free in _copy_to_iter (the 2026-07-11 run on 7.2-rc1 read the
same bytes and was labelled slab-use-after-free -- the label follows
whatever sits after the RMB). Patched, recv() returns 65504 and KASAN
stays quiet; an honest transfer is clean.

Changes since v5:
  - repost only: rebased on net (v7.3-rc6), no functional change. Carries Sidraya
    Jayagond's Reviewed-by on all three patches, alongside Dust Li's.
  - 2/3 commit message: the over-read is returned to the receiving process,
    not disclosed to the peer as v5 said. Commit message only.
  - end-to-end A/B re-run on v7.3-rc6 with the v6 patches themselves as the
    fixed arm (above).
  - cover: the receive-side accumulator abort is Hidayath Khan's patch, linked
    below; the v5 cover described it as a separate series of mine.
  v5: https://lore.kernel.org/all/20260723-b4-disp-0d07164f-v5-0-6a9e235dbc4e@proton.me/
  abort: https://lore.kernel.org/all/20260804141109.542202-1-hidayath@linux.ibm.com/

Changes since v4:
  - repost only: the netdev patch queue overflowed, so v5 reposted the v4
    series unchanged, carrying Dust Li's Reviewed-by on all three patches.
  v4: https://lore.kernel.org/all/20260705-b4-disp-28a1bbca-v4-0-be089b98acc6@proton.me/

Changes since v3:
  - split into this stable-bound clamp series and a separate validate/abort
    change, per Dust Li's review;
  - tightened the commit messages; noted that the nearby SMC_STAT_* tests are not
    bounds; no functional change to the three clamps.
  v3: https://lore.kernel.org/all/20260614-b4-disp-edd64be9-v3-0-551fa514257e@proton.me/

Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Bryam Vargas (3):
      net/smc: bound the wire-controlled producer cursor to the RMB
      net/smc: bound the receive length to the RMB in smc_rx_recvmsg()
      net/smc: bound the send length to the send buffer in smc_tx_sendmsg()

 net/smc/smc_cdc.h | 27 ++++++++++++++++++++++++---
 net/smc/smc_rx.c  | 12 ++++++++++++
 net/smc/smc_tx.c  | 13 +++++++++++++
 3 files changed, 49 insertions(+), 3 deletions(-)
---
base-commit: 6d25ffca055a77787c21a36b66c253f76239411b
change-id: 20261008-b4-disp-f7cd3d96-ff529d85131e

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

