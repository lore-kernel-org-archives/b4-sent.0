From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 14 Nov 2026 17:51:11 +0800
Subject: [PATCH net] net: macb: limit jumbo frames to the RX buffer size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-macb-jumbo-jml-v1-1-f501395eaf9e@iscas.ac.cn>
X-B4-Tracking: v=1; b=H4sIAA4v+GoC/x2MQQqAIBAAvxJ7bsEkivpKdEjdaiUttCKQ/p40t
 znMJIgUmCL0RYJAN0fefZaqLECvk18I2WQHKWRTZdBNWqG9nNrRug3rzohWC206IyFHR6CZn38
 4gKcTxvf9AKLgem9lAAAA
X-Change-ID: 20261111-macb-jumbo-jml-49d07c0cd9d2
To: =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Punnaiah Choudary Kalluri <punnaia@xilinx.com>, 
 Harini Katakam <harini.katakam@xilinx.com>
Cc: linux-riscv@lists.infradead.org, Han Gao <rabenda.cn@gmail.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jingkun Zheng <zhengjingkun@iscas.ac.cn>, Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794649871; l=2770;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=Ba0EhmfC/eB3reG4OHAFgVQBuZCONa6EOSwuE8i/JWE=;
 b=cZLObGEtUvp/SP5azLnWEj3cPd4p6jtuyHY1VunFYe63DcPfgFR0aZxmd+G9sG4dRoq1cwPJa
 X8PUu1Yfw47BErR31njhHCIlQ/ubs/5ETSdbgWCsByhmmFc+WvGq+fU
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GEM variants with MACB_CAPS_JUMBO accept frames up to jumbo_max_len
regardless of the MTU, but the RX buffers are sized from the MTU. A
frame longer than one RX buffer is split over several descriptors and
dropped by gem_rx() with "not whole frame pointed by descriptor".

Set JML from the RX buffer size in macb_configure_dma(), so that it
follows MTU changes and longer frames are dropped by the MAC instead.

Fixes: 98b5a0f4a228 ("net: macb: Add support for jumbo frames")
Reported-by: Jingkun Zheng <zhengjingkun@iscas.ac.cn>
Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
Seen on a SiFive FU740 with the default MTU: every jumbo frame on the
network caused two "not whole frame pointed by descriptor" errors.
---
 drivers/net/ethernet/cadence/macb_main.c | 21 +++++++++++++++++++--
 1 file changed, 19 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_main.c b/drivers/net/ethernet/cadence/macb_main.c
index 5ad0e32e2b4001c37e230a2eb7badb468b14ab57..e7c9bb24c377babc8dfd57e82ebf55a8e996873d 100644
--- a/drivers/net/ethernet/cadence/macb_main.c
+++ b/drivers/net/ethernet/cadence/macb_main.c
@@ -3240,6 +3240,18 @@ static u32 macb_dbw(struct macb *bp)
 	}
 }
 
+/* Longest frame that fits in a single RX buffer */
+static u32 gem_jumbo_max_len(struct macb *bp)
+{
+	u32 len = bp->ctx->rx_buffer_size;
+
+	/* Frame data starts NET_IP_ALIGN bytes into the buffer without RSC */
+	if (!(bp->caps & MACB_CAPS_RSC))
+		len -= NET_IP_ALIGN;
+
+	return min(len, bp->jumbo_max_len);
+}
+
 /* Configure the receive DMA engine
  * - use the correct receive buffer size
  * - set best burst length for DMA operations
@@ -3286,6 +3298,13 @@ static void macb_configure_dma(struct macb *bp)
 		netdev_dbg(bp->netdev, "Cadence configure DMA with 0x%08x\n",
 			   dmacfg);
 		gem_writel(bp, DMACFG, dmacfg);
+
+		/* Jumbo frames are always enabled, so limit their length to
+		 * what fits in one RX buffer. Longer frames would otherwise be
+		 * split across several descriptors and dropped by gem_rx().
+		 */
+		if ((bp->caps & MACB_CAPS_JUMBO) && bp->jumbo_max_len)
+			gem_writel(bp, JML, gem_jumbo_max_len(bp));
 	}
 }
 
@@ -3422,8 +3441,6 @@ static void macb_init_hw(struct macb *bp)
 		config |= MACB_BIT(NBC);	/* No BroadCast */
 	config |= macb_dbw(bp);
 	macb_writel(bp, NCFGR, config);
-	if ((bp->caps & MACB_CAPS_JUMBO) && bp->jumbo_max_len)
-		gem_writel(bp, JML, bp->jumbo_max_len);
 	bp->rx_frm_len_mask = MACB_RX_FRMLEN_MASK;
 	if (bp->caps & MACB_CAPS_JUMBO)
 		bp->rx_frm_len_mask = MACB_RX_JFRMLEN_MASK;

---
base-commit: aa40afa831ebfe45e40a23721711059f2ac584d4
change-id: 20261111-macb-jumbo-jml-49d07c0cd9d2

Best regards,
-- 
Han Gao <gaohan@iscas.ac.cn>

