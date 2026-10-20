From: alex todadze <todadzealexi19@proton.me>
Date: Tue, 20 Oct 2026 22:42:24 +0000
Subject: [PATCH net v2] net: stmmac: fix rx checksum offload with extended
 descriptors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-stmmac-rx-csum-v2-1-330c8d0951ea@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBBEf8Xs2TW0xYqe/A/DoZZFatKWdAvBE
 P5dwLPHmbx5MwNTcsRwO8yQaHTsYliDPB7Adia8CF2zZpCF1KIQGjl7byymCS0PHrXSRqm2Ol/
 IwDrqE7Vu2oUPCJSh/pU8PN9k86basM5xjumz345ih/89jAIFXiutSkm2LJr23qeYYzh5gnpZl
 i9mn7rYwwAAAA==
X-Change-ID: 20261016-stmmac-rx-csum-636a33f857ea
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 alex todadze <todadzealexi19@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792536143; l=7765;
 i=todadzealexi19@proton.me; s=20261016; h=from:subject:message-id;
 bh=005DGWjRmMY4f+bx+12CFajZHePOk6TxnwqxfHB7YTw=;
 b=UAChc2hEaFVH4vYixoIkNKudow0Ni+zTub9K9cQRAmKFfG6/y/4OsHQZjWws60MA+6uDguXcg
 V2nKMNfQ9cOCYFQfnHDhh9hs9C6rwDp6NWBw3ZsqPt5iFX8NbnfLgZG
X-Developer-Key: i=todadzealexi19@proton.me; a=ed25519;
 pk=j+Ld51xwndyrS6RE9s1B4vZjwvTeSSbcKp/mOdWy9PE=
X-Endpoint-Received: by B4 Relay for todadzealexi19@proton.me/20261016 with auth_id=1216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With extended descriptors, bit 0 of RDES0 is the Extended Status
Available flag. enh_desc_get_rx_status() still reads it as the payload
checksum error bit of the checksum offload table, so every IP frame that
has extended status is reported as csum_none and its checksum is
verified again in software.

When extended status is available, take the result from RDES4 instead.
A TCP, UDP or ICMP payload with no IP header error, no payload error and
no checksum bypass is a good frame. Everything else keeps the status
from RDES0. Since RDES4 now decides the checksum status, read it after
the own bit with dma_rmb(). While at it, fix the IP payload type mask,
which covered bits 6:2 instead of 2:0 and had no users.

Tested on a Siflower SF19A2890 (GMAC 3.70) with the board as the iperf3
endpoint. TCP receive goes from 326 to 378 Mbit/s with one stream and
from 259 to 329 Mbit/s with four, and CPU use while receiving 200 Mbit/s
drops from 26.6% to 21.5%. In stmmac_rx(), frames with a bad TCP, UDP or
ICMP checksum, over IPv4 and IPv6 and including fragmented UDP, are
still passed up as CHECKSUM_NONE and dropped by the stack.

Fixes: c24602ef8664 ("stmmac: support extend descriptors")
Signed-off-by: alex todadze <todadzealexi19@proton.me>
---
Changes in v2:
- Drop the RDES0 bit 7 check. With advanced timestamping, bit 7 is
  Timestamp Available, and ERDES4_IP_HDR_ERR already reports IP header
  errors.
- Read the extended status after the own bit with dma_rmb().
- Say in the commit message that the bad checksum result applies to
  stmmac_rx(). stmmac_rx_zc() ignoring csum_none predates this patch,
  and I will send a separate fix for it.
- Wrap the lines over 80 columns.
- Not changed: bit 0 still reaches enh_desc_coe_rdes0(), so 802.3
  frames with Extended Status Available set can be discarded. That
  predates this patch and depends on when the GMAC sets the flag, so I
  would rather test it on hardware and fix it separately.
- Link to v1: https://patch.msgid.link/20261016-stmmac-rx-csum-v1-1-986342ec40df@proton.me
---
 drivers/net/ethernet/stmicro/stmmac/descs.h       |  6 +++++-
 drivers/net/ethernet/stmicro/stmmac/enh_desc.c    | 25 +++++++++++++++++++++--
 drivers/net/ethernet/stmicro/stmmac/hwif.h        |  6 +++---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 19 ++++++++++++-----
 4 files changed, 45 insertions(+), 11 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/descs.h b/drivers/net/ethernet/stmicro/stmmac/descs.h
index 846007cc2..0af819a98 100644
--- a/drivers/net/ethernet/stmicro/stmmac/descs.h
+++ b/drivers/net/ethernet/stmicro/stmmac/descs.h
@@ -116,7 +116,7 @@
 #define	ETDES1_BUFFER2_SIZE_MASK	GENMASK(28, 16)
 
 /* Extended Receive descriptor definitions */
-#define	ERDES4_IP_PAYLOAD_TYPE_MASK	GENMASK(6, 2)
+#define	ERDES4_IP_PAYLOAD_TYPE_MASK	GENMASK(2, 0)
 #define	ERDES4_IP_HDR_ERR		BIT(3)
 #define	ERDES4_IP_PAYLOAD_ERR		BIT(4)
 #define	ERDES4_IP_CSUM_BYPASSED		BIT(5)
@@ -147,6 +147,10 @@
 #define RDES_PTP_SIGNALING		0xa
 #define RDES_PTP_PKT_RESERVED_TYPE	0xf
 
+#define RDES_EXT_PAYLOAD_UDP		0x1
+#define RDES_EXT_PAYLOAD_TCP		0x2
+#define RDES_EXT_PAYLOAD_ICMP		0x3
+
 /* Basic descriptor structure for normal and alternate descriptors */
 struct dma_desc {
 	__le32 des0;
diff --git a/drivers/net/ethernet/stmicro/stmmac/enh_desc.c b/drivers/net/ethernet/stmicro/stmmac/enh_desc.c
index 051253601..023b54b72 100644
--- a/drivers/net/ethernet/stmicro/stmmac/enh_desc.c
+++ b/drivers/net/ethernet/stmicro/stmmac/enh_desc.c
@@ -109,8 +109,25 @@ static int enh_desc_coe_rdes0(int ipc_err, int type, int payload_err)
 	return ret;
 }
 
-static void enh_desc_get_ext_status(struct stmmac_extra_stats *x,
-				    struct dma_extended_desc *p)
+static int enh_desc_ext_rx_csum(u32 rdes0, u32 rdes4, int status)
+{
+	u32 type = FIELD_GET(ERDES4_IP_PAYLOAD_TYPE_MASK, rdes4);
+
+	if (status != csum_none || !(rdes0 & RDES0_FRAME_TYPE))
+		return status;
+	if (!(rdes4 & (ERDES4_IPV4_PKT_RCVD | ERDES4_IPV6_PKT_RCVD)) ||
+	    (rdes4 & (ERDES4_IP_HDR_ERR | ERDES4_IP_PAYLOAD_ERR |
+		      ERDES4_IP_CSUM_BYPASSED)))
+		return status;
+	if (type != RDES_EXT_PAYLOAD_UDP && type != RDES_EXT_PAYLOAD_TCP &&
+	    type != RDES_EXT_PAYLOAD_ICMP)
+		return status;
+
+	return good_frame;
+}
+
+static int enh_desc_get_ext_status(struct stmmac_extra_stats *x,
+				   struct dma_extended_desc *p, int status)
 {
 	u32 rdes0 = le32_to_cpu(p->basic.des0);
 	u32 rdes4 = le32_to_cpu(p->des4);
@@ -170,7 +187,11 @@ static void enh_desc_get_ext_status(struct stmmac_extra_stats *x,
 			x->l4_filter_match++;
 		if (rdes4 & ERDES4_L3_L4_FILT_NO_MATCH_MASK)
 			x->l3_l4_filter_no_match++;
+
+		status = enh_desc_ext_rx_csum(rdes0, rdes4, status);
 	}
+
+	return status;
 }
 
 static int enh_desc_get_rx_status(struct stmmac_extra_stats *x,
diff --git a/drivers/net/ethernet/stmicro/stmmac/hwif.h b/drivers/net/ethernet/stmicro/stmmac/hwif.h
index 5e2654c91..9925b789b 100644
--- a/drivers/net/ethernet/stmicro/stmmac/hwif.h
+++ b/drivers/net/ethernet/stmicro/stmmac/hwif.h
@@ -70,8 +70,8 @@ struct stmmac_desc_ops {
 	/* Return the reception status looking at the RDES1 */
 	int (*rx_status)(struct stmmac_extra_stats *x,
 			 struct dma_desc *p);
-	void (*rx_extended_status)(struct stmmac_extra_stats *x,
-				   struct dma_extended_desc *p);
+	int (*rx_extended_status)(struct stmmac_extra_stats *x,
+				  struct dma_extended_desc *p, int status);
 	/* Set tx timestamp enable bit */
 	void (*enable_tx_timestamp) (struct dma_desc *p);
 	/* get tx timestamp status */
@@ -128,7 +128,7 @@ struct stmmac_desc_ops {
 #define stmmac_rx_status(__priv, __args...) \
 	stmmac_do_callback(__priv, desc, rx_status, __args)
 #define stmmac_rx_extended_status(__priv, __args...) \
-	stmmac_do_void_callback(__priv, desc, rx_extended_status, __args)
+	stmmac_do_callback(__priv, desc, rx_extended_status, __args)
 #define stmmac_enable_tx_timestamp(__priv, __args...) \
 	stmmac_do_void_callback(__priv, desc, enable_tx_timestamp, __args)
 #define stmmac_get_tx_timestamp_status(__priv, __args...) \
diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index b837e8e27..e733bfd80 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -5604,9 +5604,13 @@ static int stmmac_rx_zc(struct stmmac_priv *priv, int limit, u32 queue)
 		if (!buf->xdp)
 			break;
 
-		if (priv->extend_desc)
-			stmmac_rx_extended_status(priv, &priv->xstats,
-						  rx_q->dma_erx + entry);
+		if (priv->extend_desc) {
+			/* Read the extended status after the own bit */
+			dma_rmb();
+			status = stmmac_rx_extended_status(priv, &priv->xstats,
+							   &rx_q->dma_erx[entry],
+							   status);
+		}
 		if (unlikely(status == discard_frame)) {
 			xsk_buff_free(buf->xdp);
 			buf->xdp = NULL;
@@ -5787,8 +5791,13 @@ static int stmmac_rx(struct stmmac_priv *priv, int limit, u32 queue)
 
 		prefetch(np);
 
-		if (priv->extend_desc)
-			stmmac_rx_extended_status(priv, &priv->xstats, rx_q->dma_erx + entry);
+		if (priv->extend_desc) {
+			/* Read the extended status after the own bit */
+			dma_rmb();
+			status = stmmac_rx_extended_status(priv, &priv->xstats,
+							   &rx_q->dma_erx[entry],
+							   status);
+		}
 		if (unlikely(status == discard_frame)) {
 			page_pool_put_page(rx_q->page_pool, buf->page, 0, true);
 			buf->page = NULL;

---
base-commit: 191aa41548b2d2b6af534a6d5cf84a552435c74c
change-id: 20261016-stmmac-rx-csum-636a33f857ea

Best regards,
--  
alex todadze <todadzealexi19@proton.me>

