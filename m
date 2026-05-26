From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 27 May 2026 00:51:50 +0300
Subject: [PATCH net-next v2 05/10] net: ethernet: oa_tc6: Export standard
 defined registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-adin1140-driver-v2-5-37e5c8d4e0a0@analog.com>
References: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
In-Reply-To: <20260527-adin1140-driver-v2-0-37e5c8d4e0a0@analog.com>
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-doc@vger.kernel.org, devicetree@vger.kernel.org, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779832338; l=8221;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=aV+GHXseVDM4Wf9bOjXPodLR5uFqPEOvaLMDmeSDI7Q=;
 b=gKWWUfnkaFEOFzYCAtZE5IFL012ol8G3ELyBUw1cUNXt2vT3uUCPd3aSJKQHdYJlvUjQVTmFw
 qTrYHkXey+XDM+lZbPKLV2au6sKeX6grm+457rUzn/+O957tvRvAhTS
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move defines for standard Open Alliance TC6 register addresses and
subfields in the oa_tc6's header and add entries for the PHYID and
CONFIG2. As such, other ethernet drivers that rely on oa_tc6 can use
them directly.

Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>

---
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 74 +++++++++++--------------------------------
 include/linux/oa_tc6.h        | 44 +++++++++++++++++++++++++
 2 files changed, 62 insertions(+), 56 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 4a1fd9fd75ab..904bd790159d 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -11,45 +11,6 @@
 #include <linux/phy.h>
 #include <linux/oa_tc6.h>
 
-/* OPEN Alliance TC6 registers */
-/* Standard Capabilities Register */
-#define OA_TC6_REG_STDCAP			0x0002
-#define STDCAP_DIRECT_PHY_REG_ACCESS		BIT(8)
-
-/* Reset Control and Status Register */
-#define OA_TC6_REG_RESET			0x0003
-#define RESET_SWRESET				BIT(0)	/* Software Reset */
-
-/* Configuration Register #0 */
-#define OA_TC6_REG_CONFIG0			0x0004
-#define CONFIG0_SYNC				BIT(15)
-#define CONFIG0_ZARFE_ENABLE			BIT(12)
-#define CONFIG0_PROTE				BIT(5)
-
-/* Status Register #0 */
-#define OA_TC6_REG_STATUS0			0x0008
-#define STATUS0_RESETC				BIT(6)	/* Reset Complete */
-#define STATUS0_HEADER_ERROR			BIT(5)
-#define STATUS0_LOSS_OF_FRAME_ERROR		BIT(4)
-#define STATUS0_RX_BUFFER_OVERFLOW_ERROR	BIT(3)
-#define STATUS0_TX_PROTOCOL_ERROR		BIT(0)
-
-/* Buffer Status Register */
-#define OA_TC6_REG_BUFFER_STATUS		0x000B
-#define BUFFER_STATUS_TX_CREDITS_AVAILABLE	GENMASK(15, 8)
-#define BUFFER_STATUS_RX_CHUNKS_AVAILABLE	GENMASK(7, 0)
-
-/* Interrupt Mask Register #0 */
-#define OA_TC6_REG_INT_MASK0			0x000C
-#define INT_MASK0_HEADER_ERR_MASK		BIT(5)
-#define INT_MASK0_LOSS_OF_FRAME_ERR_MASK	BIT(4)
-#define INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
-#define INT_MASK0_TX_PROTOCOL_ERR_MASK		BIT(0)
-
-/* PHY Clause 22 registers base address and mask */
-#define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00
-#define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
-
 /* Control command header */
 #define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
 #define OA_TC6_CTRL_HEADER_WRITE_NOT_READ	BIT(29)
@@ -445,7 +406,7 @@ static int oa_tc6_check_phy_reg_direct_access_capability(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	if (!(regval & STDCAP_DIRECT_PHY_REG_ACCESS))
+	if (!(regval & OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS))
 		return -ENODEV;
 
 	return 0;
@@ -646,7 +607,7 @@ static int oa_tc6_read_status0(struct oa_tc6 *tc6)
 
 static int oa_tc6_sw_reset_macphy(struct oa_tc6 *tc6)
 {
-	u32 regval = RESET_SWRESET;
+	u32 regval = OA_TC6_RESET_SWRESET;
 	int ret;
 
 	ret = oa_tc6_write_register(tc6, OA_TC6_REG_RESET, regval);
@@ -655,7 +616,7 @@ static int oa_tc6_sw_reset_macphy(struct oa_tc6 *tc6)
 
 	/* Poll for soft reset complete for every 1ms until 1s timeout */
 	ret = readx_poll_timeout(oa_tc6_read_status0, tc6, regval,
-				 regval & STATUS0_RESETC,
+				 regval & OA_TC6_STATUS0_RESETC,
 				 STATUS0_RESETC_POLL_DELAY,
 				 STATUS0_RESETC_POLL_TIMEOUT);
 	if (ret)
@@ -674,10 +635,10 @@ static int oa_tc6_unmask_macphy_error_interrupts(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	regval &= ~(INT_MASK0_TX_PROTOCOL_ERR_MASK |
-		    INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK |
-		    INT_MASK0_LOSS_OF_FRAME_ERR_MASK |
-		    INT_MASK0_HEADER_ERR_MASK);
+	regval &= ~(OA_TC6_INT_MASK0_TX_PROTOCOL_ERR_MASK |
+		    OA_TC6_INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK |
+		    OA_TC6_INT_MASK0_LOSS_OF_FRAME_ERR_MASK |
+		    OA_TC6_INT_MASK0_HEADER_ERR_MASK);
 
 	return oa_tc6_write_register(tc6, OA_TC6_REG_INT_MASK0, regval);
 }
@@ -692,7 +653,7 @@ static int oa_tc6_enable_data_transfer(struct oa_tc6 *tc6)
 		return ret;
 
 	/* Enable configuration synchronization for data transfer */
-	value |= CONFIG0_SYNC;
+	value |= OA_TC6_CONFIG0_SYNC;
 
 	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, value);
 }
@@ -735,25 +696,25 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
 		return ret;
 	}
 
-	if (FIELD_GET(STATUS0_RX_BUFFER_OVERFLOW_ERROR, value)) {
+	if (FIELD_GET(OA_TC6_STATUS0_RX_BUFFER_OVERFLOW_ERROR, value)) {
 		tc6->rx_buf_overflow = true;
 		oa_tc6_cleanup_ongoing_rx_skb(tc6);
 		net_err_ratelimited("%s: Receive buffer overflow error\n",
 				    tc6->netdev->name);
 		return -EAGAIN;
 	}
-	if (FIELD_GET(STATUS0_TX_PROTOCOL_ERROR, value)) {
+	if (FIELD_GET(OA_TC6_STATUS0_TX_PROTOCOL_ERROR, value)) {
 		netdev_err(tc6->netdev, "Transmit protocol error\n");
 		return -ENODEV;
 	}
 	/* TODO: Currently loss of frame and header errors are treated as
 	 * non-recoverable errors. They will be handled in the next version.
 	 */
-	if (FIELD_GET(STATUS0_LOSS_OF_FRAME_ERROR, value)) {
+	if (FIELD_GET(OA_TC6_STATUS0_LOSS_OF_FRAME_ERROR, value)) {
 		netdev_err(tc6->netdev, "Loss of frame error\n");
 		return -ENODEV;
 	}
-	if (FIELD_GET(STATUS0_HEADER_ERROR, value)) {
+	if (FIELD_GET(OA_TC6_STATUS0_HEADER_ERROR, value)) {
 		netdev_err(tc6->netdev, "Header error\n");
 		return -ENODEV;
 	}
@@ -1189,9 +1150,10 @@ static int oa_tc6_update_buffer_status_from_register(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	tc6->tx_credits = FIELD_GET(BUFFER_STATUS_TX_CREDITS_AVAILABLE, value);
-	tc6->rx_chunks_available = FIELD_GET(BUFFER_STATUS_RX_CHUNKS_AVAILABLE,
-					     value);
+	tc6->tx_credits = FIELD_GET(OA_TC6_BUFFER_STATUS_TX_CREDITS_AVAILABLE,
+				    value);
+	tc6->rx_chunks_available =
+		FIELD_GET(OA_TC6_BUFFER_STATUS_RX_CHUNKS_AVAILABLE, value);
 
 	return 0;
 }
@@ -1231,7 +1193,7 @@ int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6)
 		return ret;
 
 	/* Set Zero-Align Receive Frame Enable */
-	regval |= CONFIG0_ZARFE_ENABLE;
+	regval |= OA_TC6_CONFIG0_ZARFE_ENABLE;
 
 	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, regval);
 }
@@ -1279,7 +1241,7 @@ static int oa_tc6_check_ctrl_protection(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	tc6->prot_ctrl = FIELD_GET(CONFIG0_PROTE, regval);
+	tc6->prot_ctrl = FIELD_GET(OA_TC6_CONFIG0_PROTE, regval);
 
 	return 0;
 }
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 95e041d7d77b..ad6f17218603 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -10,6 +10,50 @@
 #include <linux/etherdevice.h>
 #include <linux/spi/spi.h>
 
+/* OPEN Alliance TC6 registers */
+
+#define OA_TC6_REG_PHYID			0x0001
+
+/* Standard Capabilities Register */
+#define OA_TC6_REG_STDCAP			0x0002
+#define OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS	BIT(8)
+
+/* Reset Control and Status Register */
+#define OA_TC6_REG_RESET			0x0003
+#define OA_TC6_RESET_SWRESET			BIT(0)	/* Software Reset */
+
+/* Configuration Register #0 */
+#define OA_TC6_REG_CONFIG0			0x0004
+#define OA_TC6_CONFIG0_SYNC			BIT(15)
+#define OA_TC6_CONFIG0_ZARFE_ENABLE		BIT(12)
+#define OA_TC6_CONFIG0_PROTE			BIT(5)
+
+#define OA_TC6_REG_CONFIG2			0x0006
+
+/* Status Register #0 */
+#define OA_TC6_REG_STATUS0			0x0008
+#define OA_TC6_STATUS0_RESETC			BIT(6)	/* Reset Complete */
+#define OA_TC6_STATUS0_HEADER_ERROR		BIT(5)
+#define OA_TC6_STATUS0_LOSS_OF_FRAME_ERROR	BIT(4)
+#define OA_TC6_STATUS0_RX_BUFFER_OVERFLOW_ERROR	BIT(3)
+#define OA_TC6_STATUS0_TX_PROTOCOL_ERROR	BIT(0)
+
+/* Buffer Status Register */
+#define OA_TC6_REG_BUFFER_STATUS			0x000B
+#define OA_TC6_BUFFER_STATUS_TX_CREDITS_AVAILABLE	GENMASK(15, 8)
+#define OA_TC6_BUFFER_STATUS_RX_CHUNKS_AVAILABLE	GENMASK(7, 0)
+
+/* Interrupt Mask Register #0 */
+#define OA_TC6_REG_INT_MASK0				0x000C
+#define OA_TC6_INT_MASK0_HEADER_ERR_MASK		BIT(5)
+#define OA_TC6_INT_MASK0_LOSS_OF_FRAME_ERR_MASK		BIT(4)
+#define OA_TC6_INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
+#define OA_TC6_INT_MASK0_TX_PROTOCOL_ERR_MASK		BIT(0)
+
+/* PHY Clause 22 registers base address and mask */
+#define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00
+#define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
+
 struct oa_tc6;
 
 enum oa_tc6_quirk_flag {

-- 
2.43.0

