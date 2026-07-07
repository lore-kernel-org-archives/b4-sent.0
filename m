From: Ciprian Regus <ciprian.regus@analog.com>
Date: Wed, 08 Jul 2026 01:33:34 +0300
Subject: [PATCH net-next v5 06/13] net: ethernet: oa_tc6: Add the OA_TC6_
 prefix to standard registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-adin1140-driver-v5-6-4aca7b51a58b@analog.com>
References: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
In-Reply-To: <20260708-adin1140-driver-v5-0-4aca7b51a58b@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783463678; l=7884;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=X1Pr9mbgtt79K7FJuyY5w9AhwmbfMYW5X5hTwU7z19c=;
 b=jDHWsa1slDcFQDxA8z4CikfUIv8uDsuLjV+Za7UtzdvpX5/Eyt2C5ycuPyv/80XoX079FcKUP
 B9FWfgwPbDgAk4S2SZ/5fEz0l6m4fJhlirrOIUI6XVMwBOXS+k6Zk4n
X-Developer-Key: i=ciprian.regus@analog.com; a=ed25519;
 pk=8WoNhI0kQcQUl8YqJO5ZevROYk9HP8lOIeIgIYgjfbc=
X-Endpoint-Received: by B4 Relay for ciprian.regus@analog.com/20260330 with auth_id=703
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The OA TC6 standard registers are currently exported in a header file.
Add the OA_TC6_ prefix to the register address and subfield mask macros
to avoid future naming conflicts.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Ciprian Regus <ciprian.regus@analog.com>
---
v5 changelog:
 - Included OA_TC6_INT_MASK0_ALL_INTERRUPTS in the renaming. The change
   was trivial, so I kept the Reviewed-by tag.
v4 changelog:
 - no change
v3 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 37 +++++++++++++++++++------------------
 include/linux/oa_tc6.h        | 40 ++++++++++++++++++++--------------------
 2 files changed, 39 insertions(+), 38 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index 076895720655..3c19233fb38f 100644
--- a/drivers/net/ethernet/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6.c
@@ -396,7 +396,7 @@ static int oa_tc6_check_phy_reg_direct_access_capability(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	if (!(regval & STDCAP_DIRECT_PHY_REG_ACCESS))
+	if (!(regval & OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS))
 		return -ENODEV;
 
 	return 0;
@@ -597,7 +597,7 @@ static int oa_tc6_read_status0(struct oa_tc6 *tc6)
 
 static int oa_tc6_sw_reset_macphy(struct oa_tc6 *tc6)
 {
-	u32 regval = RESET_SWRESET;
+	u32 regval = OA_TC6_RESET_SWRESET;
 	int ret;
 
 	ret = oa_tc6_write_register(tc6, OA_TC6_REG_RESET, regval);
@@ -606,7 +606,7 @@ static int oa_tc6_sw_reset_macphy(struct oa_tc6 *tc6)
 
 	/* Poll for soft reset complete for every 1ms until 1s timeout */
 	ret = readx_poll_timeout(oa_tc6_read_status0, tc6, regval,
-				 regval & STATUS0_RESETC,
+				 regval & OA_TC6_STATUS0_RESETC,
 				 STATUS0_RESETC_POLL_DELAY,
 				 STATUS0_RESETC_POLL_TIMEOUT);
 	if (ret)
@@ -625,10 +625,10 @@ static int oa_tc6_unmask_macphy_error_interrupts(struct oa_tc6 *tc6)
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
@@ -643,7 +643,7 @@ static int oa_tc6_enable_data_transfer(struct oa_tc6 *tc6)
 		return ret;
 
 	/* Enable configuration synchronization for data transfer */
-	value |= CONFIG0_SYNC;
+	value |= OA_TC6_CONFIG0_SYNC;
 
 	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, value);
 }
@@ -688,7 +688,7 @@ static void oa_tc6_free_pending_skbs(struct oa_tc6 *tc6)
  */
 static void oa_tc6_disable_traffic(struct oa_tc6 *tc6)
 {
-	u32 regval = INT_MASK0_ALL_INTERRUPTS;
+	u32 regval = OA_TC6_INT_MASK0_ALL_INTERRUPTS;
 
 	tc6->disable_traffic = true;
 	oa_tc6_free_pending_skbs(tc6);
@@ -718,25 +718,25 @@ static int oa_tc6_process_extended_status(struct oa_tc6 *tc6)
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
@@ -1183,9 +1183,10 @@ static int oa_tc6_update_buffer_status_from_register(struct oa_tc6 *tc6)
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
@@ -1229,7 +1230,7 @@ int oa_tc6_zero_align_receive_frame_enable(struct oa_tc6 *tc6)
 		return ret;
 
 	/* Set Zero-Align Receive Frame Enable */
-	regval |= CONFIG0_ZARFE_ENABLE;
+	regval |= OA_TC6_CONFIG0_ZARFE_ENABLE;
 
 	return oa_tc6_write_register(tc6, OA_TC6_REG_CONFIG0, regval);
 }
@@ -1277,7 +1278,7 @@ static int oa_tc6_check_ctrl_protection(struct oa_tc6 *tc6)
 	if (ret)
 		return ret;
 
-	tc6->prot_ctrl = FIELD_GET(CONFIG0_PROTE, regval);
+	tc6->prot_ctrl = FIELD_GET(OA_TC6_CONFIG0_PROTE, regval);
 
 	return 0;
 }
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index d99e0f79af84..84b3e5176a53 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -13,39 +13,39 @@
 /* OPEN Alliance TC6 registers */
 /* Standard Capabilities Register */
 #define OA_TC6_REG_STDCAP			0x0002
-#define STDCAP_DIRECT_PHY_REG_ACCESS		BIT(8)
+#define OA_TC6_STDCAP_DIRECT_PHY_REG_ACCESS	BIT(8)
 
 /* Reset Control and Status Register */
 #define OA_TC6_REG_RESET			0x0003
-#define RESET_SWRESET				BIT(0)	/* Software Reset */
+#define OA_TC6_RESET_SWRESET			BIT(0)	/* Software Reset */
 
 /* Configuration Register #0 */
 #define OA_TC6_REG_CONFIG0			0x0004
-#define CONFIG0_SYNC				BIT(15)
-#define CONFIG0_ZARFE_ENABLE			BIT(12)
-#define CONFIG0_PROTE				BIT(5)
+#define OA_TC6_CONFIG0_SYNC			BIT(15)
+#define OA_TC6_CONFIG0_ZARFE_ENABLE		BIT(12)
+#define OA_TC6_CONFIG0_PROTE			BIT(5)
 
 /* Status Register #0 */
 #define OA_TC6_REG_STATUS0			0x0008
-#define STATUS0_RESETC				BIT(6)	/* Reset Complete */
-#define STATUS0_HEADER_ERROR			BIT(5)
-#define STATUS0_LOSS_OF_FRAME_ERROR		BIT(4)
-#define STATUS0_RX_BUFFER_OVERFLOW_ERROR	BIT(3)
-#define STATUS0_TX_PROTOCOL_ERROR		BIT(0)
+#define OA_TC6_STATUS0_RESETC			BIT(6)	/* Reset Complete */
+#define OA_TC6_STATUS0_HEADER_ERROR		BIT(5)
+#define OA_TC6_STATUS0_LOSS_OF_FRAME_ERROR	BIT(4)
+#define OA_TC6_STATUS0_RX_BUFFER_OVERFLOW_ERROR	BIT(3)
+#define OA_TC6_STATUS0_TX_PROTOCOL_ERROR	BIT(0)
 
 /* Buffer Status Register */
-#define OA_TC6_REG_BUFFER_STATUS		0x000B
-#define BUFFER_STATUS_TX_CREDITS_AVAILABLE	GENMASK(15, 8)
-#define BUFFER_STATUS_RX_CHUNKS_AVAILABLE	GENMASK(7, 0)
+#define OA_TC6_REG_BUFFER_STATUS			0x000B
+#define OA_TC6_BUFFER_STATUS_TX_CREDITS_AVAILABLE	GENMASK(15, 8)
+#define OA_TC6_BUFFER_STATUS_RX_CHUNKS_AVAILABLE	GENMASK(7, 0)
 
 /* Interrupt Mask Register #0 */
-#define OA_TC6_REG_INT_MASK0			0x000C
-#define INT_MASK0_HEADER_ERR_MASK		BIT(5)
-#define INT_MASK0_LOSS_OF_FRAME_ERR_MASK	BIT(4)
-#define INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
-#define INT_MASK0_TX_PROTOCOL_ERR_MASK		BIT(0)
-#define INT_MASK0_ALL_INTERRUPTS                (GENMASK(5, 0) | \
-						 GENMASK(12, 7))
+#define OA_TC6_REG_INT_MASK0				0x000C
+#define OA_TC6_INT_MASK0_HEADER_ERR_MASK		BIT(5)
+#define OA_TC6_INT_MASK0_LOSS_OF_FRAME_ERR_MASK		BIT(4)
+#define OA_TC6_INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
+#define OA_TC6_INT_MASK0_TX_PROTOCOL_ERR_MASK		BIT(0)
+#define OA_TC6_INT_MASK0_ALL_INTERRUPTS                 (GENMASK(5, 0) | \
+							 GENMASK(12, 7))
 
 /* PHY Clause 22 registers base address and mask */
 #define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00

-- 
2.43.0

