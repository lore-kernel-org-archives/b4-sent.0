From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:41 +0000
Subject: [PATCH net-next v3] net: stmmac: Limit the MTU of normal
 descriptors to one RX buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mtu-limit-v3-1-1ddcb25eba45@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32OwQ6CMBBEf8X07Bq6QFM8+R/GA5QF1tBiaCEYw
 r8LeOGix8nMvJlZeOqZvLieZtHTyJ47t4r4fBKmyV1NwOWqBUaopEQJfnCagWxuwIYBWrYcQKk
 8i1WkkkylYq2+eqp42rF34SiAoymIx9fxQ/EkEzbqlm3Yh65/7w9GuTf+j40SJCAmGeoEy1jqW
 21zbi+ms/vEiEcI/oAgRGCSSEtKCx2b6ghZluUDEkR/fhkBAAA=
X-Change-ID: 20261121-sun8i-emac-mtu-limit-66a936064965
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 LABBE Corentin <clabbe.montjoie@gmail.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Nicolai Buchwitz <nb@tipi-net.de>, 
 Russell King <rmk+kernel@armlinux.org.uk>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887460; l=3795;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=EOAQQASp3KKXbGGsfxH5IrLe6j8bWGL7hxffH/bUSt0=;
 b=xaxXmrqVQxWldqAtHuVkx+tK5cCKsDoSdhtu+lm71t4ojLkWLQCrwYGhH1I8E2z5j0g1gNsPN
 4fV63T1tSLeCmYelFJ0+WH/nyxYEC7b1CuMagCvrbi6afXoOKvSESCp
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As Russell King pointed out in [1], max_mtu for normal descriptors,
SKB_MAX_HEAD() (3712 on arm64), is too high: ndesc_get_rx_status()
drops every frame that spans more than one descriptor, and the DMA does
not always fill the 2047-byte buffer. Chen-Yu Tsai found the reason in
the STM32F4 and Arria 10 manuals: the DMA writes whole bus words,
counted from the word that holds the buffer start. Andrew Lunn noted
that such an offset aligns the IP header; stmmac_rx_offset() adds
NET_IP_ALIGN. Maxime Chevallier found the first failing untagged MTU:
2025 on H2+ (arm32, chain mode), 2029 on A20 and 2031 on meson-g12a
(ring mode). On H616 (arm64, chain mode) it is 2027.

Take the widest bus, 16 bytes, NET_IP_ALIGN, the two bytes a Type-1
checksum engine appends, two VLAN tags and the FCS. max_mtu is then
2006 on arm64 and 2004 on arm32, two less with Type-1.

Link: https://lore.kernel.org/r/E1vLJcL-0000000ExBL-0GFe@rmk-PC.armlinux.org.uk [1]
Fixes: 48febf7e6476 ("stmmac: allow mtu bigger than 1500 in case of normal desc (V4)")
Cc: Russell King <rmk+kernel@armlinux.org.uk>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi Zero2 (H616, arm64, Type-2 COE, chain mode) on
net-next: before, MTU 2027 drops every full-size RX frame; after, max
MTU 2006, lossless. Untested: arm32, Type-1 COE, ring mode, dwmac1000
JE. Ring-mode RX buffer 2 and normal TX lengths: older bugs, separate
patches.

Claude (AI) helped write this patch; I reviewed and tested it.
---
Changes in v3:
- One generic limit (Chen-Yu, Andrew, Maxime's sweep); RX is the limit
  (Nicolai); sun8i patch dropped; net-next, no Cc stable.
- Sashiko: bus width, NET_IP_ALIGN, Type-1 bytes counted; RBS1 unchanged,
  frames end inside the aligned part; JE only lets longer frames in, and
  they are dropped as before.
- Link to v2: https://patch.msgid.link/20261122-sun8i-emac-mtu-limit-v2-0-c4081e5b83cf@gmail.com

Changes in v2:
- Limit normal descriptors in the core (patch 1, Andrew Lunn, Maxime
  Chevallier), keep the lower sun8i limit as patch 2
- Link to v1: https://patch.msgid.link/20261121-sun8i-emac-mtu-limit-v1-1-22492842d318@gmail.com
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index ca4c7fb11b73..bf688ee46c84 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -1568,6 +1568,20 @@ static unsigned int stmmac_rx_offset(struct stmmac_priv *priv)
 	return NET_SKB_PAD + NET_IP_ALIGN;
 }
 
+/* A normal descriptor frame must fit one RX buffer. The DMA writes whole bus
+ * words of up to 16 bytes, from the word that holds the NET_IP_ALIGN offset.
+ * Type-1 checksum engines append two bytes.
+ */
+static int stmmac_ndesc_max_mtu(struct stmmac_priv *priv)
+{
+	int len = ALIGN_DOWN(BUF_SIZE_2KiB - 1, 16) - NET_IP_ALIGN;
+
+	if (priv->plat->rx_coe == STMMAC_RX_COE_TYPE1)
+		len -= 2;
+
+	return len - ETH_HLEN - 2 * VLAN_HLEN - ETH_FCS_LEN;
+}
+
 static int stmmac_set_bfsize(int len)
 {
 	int ret;
@@ -8315,6 +8329,8 @@ static int __stmmac_dvr_probe(struct device *device,
 		ndev->max_mtu = XGMAC_JUMBO_LEN;
 	else if (priv->plat->enh_desc || priv->synopsys_id >= DWMAC_CORE_4_00)
 		ndev->max_mtu = JUMBO_LEN;
+	else if (priv->hw->desc == &ndesc_ops)
+		ndev->max_mtu = stmmac_ndesc_max_mtu(priv);
 	else
 		ndev->max_mtu = SKB_MAX_HEAD(NET_SKB_PAD + NET_IP_ALIGN);
 

---
base-commit: f89726ffabef1b08c52e6163b7ab94b0d5f15503
change-id: 20261121-sun8i-emac-mtu-limit-66a936064965

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

