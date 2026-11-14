From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 14 Nov 2026 09:14:58 -0500
Subject: [PATCH net] net/smc: set the lkey of every SGE in
 smcr_tx_rdma_writes()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-disp-dd99cd41-v1-1-009e1c022346@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBAAvyJ77oIbEyH9SumhZte6PaSStaUg/
 t1ojzMws4JJUTG4NisU+arpO1egSwNpeuSnoHJlcK3ricjj4JHVZmSOMbEndL4fKcRAoWOo2Vx
 k1N+5vEGWBe5/aZ/hJWk5ZrBtO8eVIEx5AAAA
X-Change-ID: 20261114-b4-disp-dd99cd41-246f1595153d
To: Eric Dumazet <edumazet@kernel.org>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Dust Li <dust.li@linux.alibaba.com>
Cc: Simon Horman <horms@kernel.org>, Tony Lu <tonylu@linux.alibaba.com>, 
 linux-rdma@vger.kernel.org, linux-s390@vger.kernel.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794665697; l=3051;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=dkZIYkWO+afWCtaRXB6rlTNCb1w2kuhU8KVl6AzBpmo=;
 b=Fm8nUYS5YgF6A3OcDnR5fkM8Orc+GUr95QOvYntRgXnITsnFV4EDHR4MiR8VzCWTYThWu/cjf
 Zs0fz8/hNPpB+OWQnISb0UUVBidefyMvTCFi4cHl1aZbeW+xNJm+A35
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smcr_tx_rdma_writes() sets the lkey of an SGE only for a virtually
contiguous send buffer; for a physically contiguous one it leaves the
lkey the work request slot already holds. With net.smc.smcr_buf_type=2
a send buffer falls back to vzalloc() when alloc_pages() fails, so one
link carries both kinds, and a slot last used by a virtually contiguous
buffer posts the DMA address of a physically contiguous one under the
earlier buffer's MR lkey. That write fails, the link goes down and,
with no link to switch to, the link group is terminated with all of
its connections.

Set the lkey on both branches: the MR's for a virtually contiguous
buffer, local_dma_lkey otherwise.

Fixes: b8d199451c99 ("net/smc: Allow virtually contiguous sndbufs or RMBs for SMC-R")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Repro on SMC-Rv2 with soft-RoCE (rxe) over a veth pair between two
namespaces, one link, 64 KiB send buffers; smc.ko built from the
base-commit below, with and without the patch, on a v7.4-rc2 KASAN
kernel. smcr_buf_type=2 is set in init_net, where the rxe devices are.
A test-only knob in smc.ko fails alloc_pages() for the server's first
send buffer, so connection A gets a virtually contiguous send buffer
and connection B a physically contiguous one. The server sends 1 MiB on
A, then 1 MiB on B, in 16 KiB writes.

Unpatched, B's first RDMA write is posted with the lkey of A's MR
(recorded by test code added to smc.ko). None of its 16384 bytes reach
the peer, though send() returned 16384. The write and the CDC message
behind it both complete with IB_WC_WR_FLUSH_ERR. By reading rxe (not
measured), the requester rejects the write, puts the QP in the error
state and flushes the send queue. The link goes down and the link group
is terminated, so A is aborted too: its next send() fails with EPIPE.
Patched, both streams arrive intact and the link stays up. Both builds
also deliver both streams intact with smcr_buf_type=0, with
smcr_buf_type=1, and with smcr_buf_type=2 without the knob. No KASAN
splat in any run.
---
 net/smc/smc_tx.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/net/smc/smc_tx.c b/net/smc/smc_tx.c
index 0f0c6df3bf2c..2c8bcaccad83 100644
--- a/net/smc/smc_tx.c
+++ b/net/smc/smc_tx.c
@@ -393,9 +393,9 @@ static int smcr_tx_rdma_writes(struct smc_connection *conn, size_t len,
 			sge[srcchunk].addr = conn->sndbuf_desc->is_vm ?
 				(virt_addr + src_off) : (base_addr + src_off);
 			sge[srcchunk].length = src_len;
-			if (conn->sndbuf_desc->is_vm)
-				sge[srcchunk].lkey =
-					conn->sndbuf_desc->mr[link->link_idx]->lkey;
+			sge[srcchunk].lkey = conn->sndbuf_desc->is_vm ?
+				conn->sndbuf_desc->mr[link->link_idx]->lkey :
+				link->roce_pd->local_dma_lkey;
 			num_sges++;
 
 			src_off += src_len;

---
base-commit: ead6fa9a0ab194f02a2f36d634b193e9c5f9a1c6
change-id: 20261114-b4-disp-dd99cd41-246f1595153d

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

