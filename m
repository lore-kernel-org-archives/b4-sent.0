From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 06:02:01 +0000
Subject: [PATCH 5.10.y v2] net: mvpp2: limit XDP frame size to the RX
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-mvpp2-f3c6-v2-1-808d54f66dd7@certik.com>
X-B4-Tracking: v=1; b=H4sIAFjLB2sC/0WNwQ7CIBBEf6XZs9RCU5L6K8bDAovFKDRsbTRN/
 13Qg8d5mXmzAVMOxHBqNsi0Bg4plqAODdgJ45VEcCWD6pSWUmnxWOdZCd9bLUZvxsEhWuwdlMG
 cyYfXV3aGoZVd+4bLj/PT3Mgu1VSbBpmEyRjtVBFTdEtKd1H58f8A+/4ByUznpaEAAAA=
X-Change-ID: 20261126-mvpp2-f3c6-9fb95daaca3d
To: stable@vger.kernel.org
Cc: Til Kaiser <mail@tk154.de>, Paolo Abeni <pabeni@redhat.com>, 
 netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795672920; l=2926;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=nEG54vSD1l9G1xJGLgOmyZlKk1HndBSHrnab9cKFiPU=;
 b=5yBYtOfxgP4dHfX5ShB6vHrc56oa5xb49E7w39wPP+JZMRqSc227JdKMK3GVTeVrIuX2aMoMY
 67EBESzxCRiC0GAkfZhMvxZaOYeS3fZdZqel1w6Z0VS2zCFqfL+1oe5
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Til Kaiser <mail@tk154.de>

commit f3c6aa078927e6fe8121c9c591ddee8716c5305a upstream.

mvpp2 has short and long BM pools, and short pool buffers can be smaller
than PAGE_SIZE. The XDP path nevertheless initializes every xdp_buff with
PAGE_SIZE as frame size.

XDP helpers use frame_sz to validate tail growth and to derive the hard
end of the data area. Advertising PAGE_SIZE for short buffers can let
bpf_xdp_adjust_tail() grow a packet past the real allocation, corrupting
memory or later tripping skb tailroom checks.

Initialize the XDP buffer with bm_pool->frag_size so XDP tailroom matches
the actual buffer backing the packet.

Fixes: 07dd0a7aae7f ("mvpp2: add basic XDP support")
Signed-off-by: Til Kaiser <mail@tk154.de>
Link: https://patch.msgid.link/20260607134943.21996-3-mail@tk154.de
Signed-off-by: Paolo Abeni <pabeni@redhat.com>
[ adapted to 5.10: no xdp_init_buff() here, set xdp.frame_sz directly ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

Changes in v2
v2: resent through a whitespace-safe path; v1 <CAFaZ9erzjfA3ogfym5X53zX6fW1kMTHcOnu7rMdkCeq=H64Qbg@mail.gmail.com> was damaged by my mail client and does not apply.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

5.10.y is the one stable branch still missing this. 5.15.y and newer
already took it. 5.10 has no xdp_init_buff() and mvpp2_rx() fills in
the xdp_buff by hand, so the change lands on the xdp.frame_sz
assignment instead. Same value, same spot.

Tested on v5.10.275:
- x86_64 allmodconfig (CONFIG_MVPP2=m) W=1 build of mvpp2_main.o,
  base vs patched, no new warnings
- x86_64 defconfig with CONFIG_MVPP2=y builds and boots under QEMU/KVM
- I don't have mvpp2 hardware, so the XDP short pool path itself is
  untested here. No existing selftest reaches it.

The other two fixes from the same upstream series, 5e8e2a9624df ("net:
mvpp2: refill RX buffers before XDP or skb use") and 77a6b90ce56b
("net: mvpp2: build skb from XDP-adjusted data on XDP_PASS"), aren't in
5.10.y either. This one doesn't depend on them, so it's on its own here.

diff --git a/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c b/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
index cb0e319bc2f1..3e60d40b3f6f 100644
--- a/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
+++ b/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
@@ -3617,7 +3617,7 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 			xdp.data_hard_start = data;
 			xdp.data = data + MVPP2_MH_SIZE + MVPP2_SKB_HEADROOM;
 			xdp.data_end = xdp.data + rx_bytes;
-			xdp.frame_sz = PAGE_SIZE;
+			xdp.frame_sz = bm_pool->frag_size;
 
 			if (bm_pool->pkt_size == MVPP2_BM_SHORT_PKT_SIZE)
 				xdp.rxq = &rxq->xdp_rxq_short;

