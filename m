From: Ciprian Regus <ciprian.regus@analog.com>
Date: Thu, 04 Jun 2026 19:32:50 +0300
Subject: [PATCH net-next v3 05/13] net: ethernet: oa_tc6: Export standard
 defined registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260604-adin1140-driver-v3-5-5debdb3173c4@analog.com>
References: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
In-Reply-To: <20260604-adin1140-driver-v3-0-5debdb3173c4@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780590775; l=5192;
 i=ciprian.regus@analog.com; s=20260330; h=from:subject:message-id;
 bh=SnykMoUwLndx3IdbcHLqPP0Y55/QSx2yLP1+rPkpPh8=;
 b=g+yTEdg1tc0U6Eedi+q/eHi5iB8W8/YUlWiBuoJTnR6lnnyjct/JH58SLj1ExawKpLnlLrIZL
 Dr7n62QOZQwDVL+EVtBpy8V+B0lZDLLxyZMtCDGd2T0MnlJ1XuojmhD
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
v3 changelog:
 - Only move the register definitions, without adding the OA_TC6_ prefix
v2 changelog:
 - New patch
---
 drivers/net/ethernet/oa_tc6.c | 48 -------------------------------------------
 include/linux/oa_tc6.h        | 48 +++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 48 insertions(+), 48 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6.c b/drivers/net/ethernet/oa_tc6.c
index b37e398e30e3..97df38207827 100644
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
@@ -79,15 +40,6 @@
 #define OA_TC6_DATA_FOOTER_END_BYTE_OFFSET	GENMASK(13, 8)
 #define OA_TC6_DATA_FOOTER_TX_CREDITS		GENMASK(5, 1)
 
-/* PHY – Clause 45 registers memory map selector (MMS) as per table 6 in the
- * OPEN Alliance specification.
- */
-#define OA_TC6_PHY_C45_PCS_MMS2			2	/* MMD 3 */
-#define OA_TC6_PHY_C45_PMA_PMD_MMS3		3	/* MMD 1 */
-#define OA_TC6_PHY_C45_VS_PLCA_MMS4		4	/* MMD 31 */
-#define OA_TC6_PHY_C45_AUTO_NEG_MMS5		5	/* MMD 7 */
-#define OA_TC6_PHY_C45_POWER_UNIT_MMS6		6	/* MMD 13 */
-
 #define OA_TC6_CTRL_PROT_REPLY_SIZE		4
 #define OA_TC6_CTRL_HEADER_SIZE			4
 #define OA_TC6_CTRL_REG_VALUE_SIZE		4
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 2660eefa3504..bbc42758a313 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -10,6 +10,54 @@
 #include <linux/etherdevice.h>
 #include <linux/spi/spi.h>
 
+/* OPEN Alliance TC6 registers */
+/* Standard Capabilities Register */
+#define OA_TC6_REG_STDCAP			0x0002
+#define STDCAP_DIRECT_PHY_REG_ACCESS		BIT(8)
+
+/* Reset Control and Status Register */
+#define OA_TC6_REG_RESET			0x0003
+#define RESET_SWRESET				BIT(0)	/* Software Reset */
+
+/* Configuration Register #0 */
+#define OA_TC6_REG_CONFIG0			0x0004
+#define CONFIG0_SYNC				BIT(15)
+#define CONFIG0_ZARFE_ENABLE			BIT(12)
+#define CONFIG0_PROTE				BIT(5)
+
+/* Status Register #0 */
+#define OA_TC6_REG_STATUS0			0x0008
+#define STATUS0_RESETC				BIT(6)	/* Reset Complete */
+#define STATUS0_HEADER_ERROR			BIT(5)
+#define STATUS0_LOSS_OF_FRAME_ERROR		BIT(4)
+#define STATUS0_RX_BUFFER_OVERFLOW_ERROR	BIT(3)
+#define STATUS0_TX_PROTOCOL_ERROR		BIT(0)
+
+/* Buffer Status Register */
+#define OA_TC6_REG_BUFFER_STATUS		0x000B
+#define BUFFER_STATUS_TX_CREDITS_AVAILABLE	GENMASK(15, 8)
+#define BUFFER_STATUS_RX_CHUNKS_AVAILABLE	GENMASK(7, 0)
+
+/* Interrupt Mask Register #0 */
+#define OA_TC6_REG_INT_MASK0			0x000C
+#define INT_MASK0_HEADER_ERR_MASK		BIT(5)
+#define INT_MASK0_LOSS_OF_FRAME_ERR_MASK	BIT(4)
+#define INT_MASK0_RX_BUFFER_OVERFLOW_ERR_MASK	BIT(3)
+#define INT_MASK0_TX_PROTOCOL_ERR_MASK		BIT(0)
+
+/* PHY Clause 22 registers base address and mask */
+#define OA_TC6_PHY_STD_REG_ADDR_BASE		0xFF00
+#define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
+
+/* PHY – Clause 45 registers memory map selector (MMS) as per table 6 in the
+ * OPEN Alliance specification.
+ */
+#define OA_TC6_PHY_C45_PCS_MMS2			2	/* MMD 3 */
+#define OA_TC6_PHY_C45_PMA_PMD_MMS3		3	/* MMD 1 */
+#define OA_TC6_PHY_C45_VS_PLCA_MMS4		4	/* MMD 31 */
+#define OA_TC6_PHY_C45_AUTO_NEG_MMS5		5	/* MMD 7 */
+#define OA_TC6_PHY_C45_POWER_UNIT_MMS6		6	/* MMD 13 */
+
 struct oa_tc6;
 
 enum oa_tc6_quirk_flag {

-- 
2.43.0

