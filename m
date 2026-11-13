From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 17:13:40 +0000
Subject: [PATCH net] net: stmmac: drop the rest of the frame when
 napi_build_skb() fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-stmmac-rx-skb-fail-v1-1-fcaae89f2d2c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swtJ1Fj8FfGQxK2u2ijZKIXSf
 zfqcQZmZigXYcW+m1H4LSqP3MCuOqRLyGcmOTWGM85ba9ekdRxDojKR3iINQe4Uo/d978zG7LZ
 o4bPwINNvekDmiuNf6iteOdXvDsvyAb0bGMd7AAAA
X-Change-ID: 20261113-stmmac-rx-skb-fail-bb6688204075
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>
Cc: Lorenzo Bianconi <lorenzo@kernel.org>, netdev@vger.kernel.org, 
 linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Lorenzo Bianconi <lorenzo.bianconi@oss.qualcomm.com>, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794590019; l=2559;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=wIb/6vSfLxz3UqBxBdPnsbYyCrSq+sayPpXGXdTp9/o=;
 b=CPrFrxa72Bl0nYXh6+1shMuAOTknAtY7Kk/bwk/FpvzkYEqnDO+PX7KyvlVyN8YxhGuYk8haN
 2e5Vh4N8kLlDX6jm3HO7+1ZH6RHs7Qnt9vzjmlksuQhH587SjVPPyvK
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If napi_build_skb() fails on the first buffer of a frame that spans
several descriptors, stmmac_rx() drops that buffer but goes on with the
next descriptor of the same frame as if a new frame started there. The
rest of the frame is then passed up the stack as a frame of its own. A
frame spans several descriptors when it does not fit in the RX buffers
of one descriptor.

Mark the frame as errored instead, so that its remaining descriptors are
discarded like those of a frame with a receive error. The frame is
counted once in rx_dropped and once against the NAPI budget.

Fixes: ec222003bd94 ("net: stmmac: Prepare to add Split Header support")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found while working on the sun8i EMAC jumbo frame series, where frames
over 2032 bytes span several descriptors. Lorenzo's pending net-next
series "net: stmmac: introduce XDP rx multi-buff support" (v10) removes
this path; this is the fix for net and stable and will conflict with it.

Tested on an Orange Pi Zero2 (dwmac-sun8i, MTU 4070), backported to
v7.3.3 with the jumbo series and a test hook that fails
napi_build_skb(): of 12726 multi-descriptor frames, the 1818 failed
ones were dropped and counted in rx_dropped, no fragment reached the
stack, and all other frames arrived intact. Without the patch the 1818
fragments were delivered as frames.

Developed with Claude (Anthropic), which wrote the fix and the commit
message. I reviewed every change.
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 25894771e9e9..d05c5bb8b4b9 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -6029,7 +6029,7 @@ static int stmmac_rx(struct stmmac_priv *priv, int limit, u32 queue)
 							 buf->page);
 				buf->page = NULL;
 				rx_dropped++;
-				count++;
+				error = 1;
 				goto drain_data;
 			}
 
@@ -6065,7 +6065,7 @@ static int stmmac_rx(struct stmmac_priv *priv, int limit, u32 queue)
 		if (likely(status & rx_not_ls))
 			goto read_again;
 		if (!skb)
-			continue;
+			goto next;
 
 		/* Got entire packet into SKB. Finish it. */
 

---
base-commit: ead6fa9a0ab194f02a2f36d634b193e9c5f9a1c6
change-id: 20261113-stmmac-rx-skb-fail-bb6688204075

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

