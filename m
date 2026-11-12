From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 12 Nov 2026 07:59:38 -0500
Subject: [PATCH net v9 4/6] net/smc: keep the source of an RDMA write
 inside the send buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-b4-disp-0287c16e-v9-4-e5e8fa688177@proton.me>
References: <20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me>
In-Reply-To: <20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me>
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Dust Li <dust.li@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, "David S. Miller" <davem@davemloft.net>, 
 Jakub Kicinski <kuba@kernel.org>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Ursula Braun <ubraun@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-s390@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Simon Horman <horms@kernel.org>, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794488375; l=4376;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=wu4Gw2/kDnZg8fMolb4by/QKqmZMOKGLAo8H2UVvtJ8=;
 b=12Br+F4Dc3L/KJCyeP6+Y8/f2CQZ0oZSym+OSUZST2fkSimiZd3tidIjGHm+yAxGpVUK4dPp9
 cFUt3hF31TwCSoiQs9GeS1e0wiQovradmUnd/DaQlCLiMnE/I2lPL1o
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smcr_tx_rdma_writes() sizes the first source SGE of the second
destination chunk from the send cursor as it was before the first
chunk, so that SGE runs past the send buffer when the buffer ends
inside the second chunk. A physically contiguous send buffer goes out
under the local DMA lkey, which does not bound the SGE; on rxe the peer
is sent the memory that follows the buffer. A conforming peer gets there
when a completion handled inside smc_switch_cursor() leaves tx_curs_sent
behind local_tx_ctrl.prod. Otherwise it takes a peer_rmbe_space forged
larger than the RMBE and a send buffer larger than the RMBE.

Size the SGE from the running offset, as smcd_tx_rdma_writes() does. A
conforming write sends the same bytes.

Fixes: e6727f39004b ("smc: send data (through RDMA)")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://netdev-ai.bots.linux.dev/sashiko/#/patchset/20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68%40proton.me?part=4
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
New in v9. Sashiko's review of v7's 4/4 [1] pointed this bug out
("could this send adjacent kernel memory to the peer?"); the review,
and my reply to it, took it for unreachable by a conforming peer. The
first case below reaches it.

rxe, two links (v7.4-rc2 plus d7900fa51642, KASAN), send buffer and
peer RMBE 64K, physically contiguous, conforming peer. Every connection
carries one byte first; the counts include it. "With the patch" is the
whole series.
  - 60000 bytes sent and read, then 600 and 400 more, read too;
    failover, with the completion of the 600 handed to
    smc_cdc_tx_handler() between the first two cursor copies of
    smc_switch_cursor() (test hook) and the resend held; then
    send(9400). The switch leaves tx_curs_sent at 60400 and prod at
    61000, so the next write is the 600 bytes between them again plus
    the 9400, 4536 + 5464. Unpatched and v8 size the second chunk's
    first source SGE as 5136 bytes from offset 64936, 4536 past the send
    buffer. The peer reads the first 9400 bytes of that write; from byte
    5136 on (4536 + 600) they come from outside the send buffer. KASAN
    splat in rxe_mr_copy() on the unpatched run, where a freed slab
    object follows the buffer; none on v8's. With the patch no SGE ends
    past the buffer and the peer reads what is in it. It gets 600 bytes
    twice either way (see 6/6).
  - no failover, 60000 bytes sent and read, one send(20000): the write
    is 5536 + 14464 bytes and the send buffer ends with the first chunk.
    Unpatched builds 3 source SGEs, the patch 2; the peer reads the same
    20000 bytes.

With 5/6 and 6/6 applied and this change reverted, the first case and
the fourth case under 5/6 fail. Nothing else does: with the two cursors
in step, one RMBE per call already keeps the source inside (the second
case under 5/6).

A model of smcr_tx_rdma_writes() with the old and the new sizing, over
send buffers and RMBEs of 2 to 16 bytes: the new sizing gives 1344 of
12928 conforming writes a different SGE list, never a longer one, and
every write the same bytes.

Not tested on a real HCA, nor with a vmalloc'ed send buffer, where the
SGE goes out under the buffer's own MR.

[1] https://lore.kernel.org/all/179209532452.434549.6588379141939967966@kernel.org/
---
 net/smc/smc_tx.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/net/smc/smc_tx.c b/net/smc/smc_tx.c
index 3913ef103b35..d37c74754461 100644
--- a/net/smc/smc_tx.c
+++ b/net/smc/smc_tx.c
@@ -379,7 +379,6 @@ static int smcr_tx_rdma_writes(struct smc_connection *conn, size_t len,
 		sg_dma_address(conn->sndbuf_desc->sgt[link->link_idx].sgl);
 	u64 virt_addr = (uintptr_t)conn->sndbuf_desc->cpu_addr;
 	int src_len_sum = src_len, dst_len_sum = dst_len;
-	int sent_count = src_off;
 	int srcchunk, dstchunk;
 	int num_sges;
 	int rc;
@@ -425,8 +424,7 @@ static int smcr_tx_rdma_writes(struct smc_connection *conn, size_t len,
 		dst_off = 0; /* modulo offset in RMBE ring buffer */
 		dst_len = len - dst_len; /* remainder */
 		dst_len_sum += dst_len;
-		src_len = min_t(int, dst_len, conn->sndbuf_desc->len -
-				sent_count);
+		src_len = min_t(int, dst_len, conn->sndbuf_desc->len - src_off);
 		src_len_sum = src_len;
 	}
 	return 0;

-- 
2.56.0

