From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v5 0/3] net/smc: bound wire-controlled CDC cursors
 against the local buffers
Date: Thu, 23 Jul 2026 19:23:26 -0500
Message-Id: <20260723-b4-disp-0d07164f-v5-0-6a9e235dbc4e@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBAFf4W8s5ustYD6K8RDaRddD5V00ZgQ/
 t2qx5lkZoVJUTGcmxVFXmr6yBXaXYN4C/kqpKkyHLuOe3eg0VNSm4kT9/vOTxQCe/ZtjOl0RM3
 mIpO+f8sBWRZc/tKe413i8p1h2z5DwHcmeQAAAA==
X-Change-ID: 20260723-b4-disp-0d07164f-aa04045ccd98
To: Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Wen Gu <guwen@linux.alibaba.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Eric Dumazet <edumazet@google.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-s390@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Ursula Braun <ubraun@linux.ibm.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Stefan Raspl <raspl@linux.ibm.com>, 
 Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784852606; l=3932;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=6DQ+WLyreifrh3k/itJHKkWkQG3/CNPMbYJqfqHMJKA=;
 b=f3mdcsL7aYINvstnk9jm0XxUE2gd69LYSiajf8Rvx3f46s/+UXNSXrINU4bkkDzY6mNN/07l5
 5IdrV2ZwSjOBcYpZd4Gl/9VaWS9rXTnpt4jEoj7mfANZ4IDrgQdMAeR
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A peer's CDC producer/consumer cursors are copied from the wire and used,
without an upper bound against the local buffers, as (a) a raw index into the
RMB on the urgent path, (b) the receive length in smc_rx_recvmsg(), and (c) the
send length in smc_tx_sendmsg() on the SMC-D DMB-merge path. A malicious or
buggy peer can forge a cursor so each runs past the relevant buffer: an
out-of-bounds read of adjacent kernel memory (disclosed to the peer) on the
receive/urgent side, and, on the send side, an out-of-bounds write whose
length the peer controls and whose overflowing bytes are the local sender's
own outbound data.

This series bounds each length where it is consumed. The clamp is synchronous
and race-free against the tasklet that advances the cursor, so it is the minimal
fix for stable. A separate net-next series adds the wire-boundary validation and
connection abort that Dust Li suggested; those do not replace these clamps.

The clamp is not subsumed by validating cursors at the input boundary. A peer
that only increments prod.wrap with count == 0 hits the differing-wrap branch of
smc_curs_diff(), which returns (len - 0) + 0 == len every CDC, so bytes_to_rcv
(and sndbuf_space on the send side) accumulates past the buffer while every
per-cursor bound sees count == 0 and accepts the message. The overflow lives in
the accumulator, not the cursor; only the consumer-side clamp bounds it. And
because a queued abort runs asynchronously (queue_work -> smc_conn_kill) while
smc_rx_recvmsg() reads the accumulator under lock_sock, only the synchronous
clamp closes that window. So the clamp goes to stable; the abort is net-next.

The nearby readable >= rmb_desc->len / len > sndbuf_desc->len tests only feed
statistics counters (SMC_STAT_RMB_RX_FULL / SMC_STAT_RMB_TX_SIZE_SMALL) on an
earlier, separate read; they do not bound the copy.

A/B (in-kernel KASAN replaying the sink arithmetic over a real rmb_desc->len /
sndbuf_desc->len slab; kasan.fault=report kasan_multi_shot, 2026-07-05):
  - urgent index (1/3):  count = len+1        -> slab-out-of-bounds Read;  clamped -> clean
  - recv length  (2/3):  bytes_to_rcv = 5*len via wrap++/count=0 -> OOB Read; clamped -> clean
  - send length  (3/3):  sndbuf_space inflated -> slab-out-of-bounds Write; clamped -> clean
  - signed overflow:     readable = -1 -> v1 ">len" misses -> OOB; "<0 || >len" -> clean
  - concurrent TOCTOU race: a producer-side clamp is racy (OOB in a racing consumer
    kthread on another CPU); the consumer-side clamp is race-free (0 hits / 5,000,000 reads).
  - every in-bounds / honest-peer arm: clean.

Changes since v4:
  - repost only: the netdev patch queue overflowed, so this reposts the v4
    series unchanged, carrying Dust Li's Reviewed-by on all three patches.
  v4: https://lore.kernel.org/all/20260705-b4-disp-28a1bbca-v4-0-be089b98acc6@proton.me/

Changes since v3:
  - split into this stable-bound clamp series and a separate net-next
    validate/abort series, per Dust Li's review;
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
base-commit: 4539944e515183668109bdf4d0c3d7d228383d88
change-id: 20260723-b4-disp-0d07164f-aa04045ccd98

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

