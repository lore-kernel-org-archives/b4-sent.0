From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 09 Oct 2026 10:12:24 -0700
Subject: [PATCH net-next v9 04/11] net: ethernet: oa_tc6: Move constant
 definitions to header file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261009-s2500-mac-phy-support-v9-4-dcefe1d0bf0d@onsemi.com>
References: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
In-Reply-To: <20261009-s2500-mac-phy-support-v9-0-dcefe1d0bf0d@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791565943; l=9228;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=E5XFpwvxxG9SD14oTLtZFnIlhsAzC9ADiaJeiWC+qPU=;
 b=vQ9kuQtqxKSaS1kgzOjs4171ADMBqengjlmJzLswCOo5ClYL6aEBGlApWVPRW2GFo9UKZtAwq
 CDrLW7eQd2pCzG9017ds3n2Vs2HDm68dd2yjiXKVy9a446CyzU2ggp7
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To help other source files within the module share the
constant definitions, some of the definitions from oa_tc6.c
are moved to a header file. This header file is still
private to OA TC6 framework.

oa_tc6 structure is also moved to this header file as it is
needed for other source files that are part of OA TC6
framework.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v9
  - Added Reviewed tag
changes in v8:
  - Merged with latest base version's changes
  - Added Reviewed tag
changes in v7
  - No change
changes in v6
  - No change
changes in v5
  - No change
changes in v4
  - Added MMS values 1 and 12, which are used now
changes in v3
  - Moved constant definitions from the source to newly created
    header file for other sources in the directory to share.
  - Standard specific defines are moved to Linux common header file
  - First patch
---
 drivers/net/ethernet/oa_tc6/oa_tc6.c         | 104 +---------------------
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h | 125 +++++++++++++++++++++++++++
 2 files changed, 126 insertions(+), 103 deletions(-)

diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6.c b/drivers/net/ethernet/oa_tc6/oa_tc6.c
index 364027c39fa4..f8e9309a72f1 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6.c
@@ -14,109 +14,7 @@
 #include <linux/phy.h>
 #include <linux/oa_tc6.h>
 
-/* Control command header */
-#define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
-#define OA_TC6_CTRL_HEADER_WRITE_NOT_READ	BIT(29)
-#define OA_TC6_CTRL_HEADER_MEM_MAP_SELECTOR	GENMASK(27, 24)
-#define OA_TC6_CTRL_HEADER_ADDR			GENMASK(23, 8)
-#define OA_TC6_CTRL_HEADER_LENGTH		GENMASK(7, 1)
-#define OA_TC6_CTRL_HEADER_PARITY		BIT(0)
-
-/* Data header */
-#define OA_TC6_DATA_HEADER_DATA_NOT_CTRL	BIT(31)
-#define OA_TC6_DATA_HEADER_DATA_VALID		BIT(21)
-#define OA_TC6_DATA_HEADER_START_VALID		BIT(20)
-#define OA_TC6_DATA_HEADER_START_WORD_OFFSET	GENMASK(19, 16)
-#define OA_TC6_DATA_HEADER_END_VALID		BIT(14)
-#define OA_TC6_DATA_HEADER_END_BYTE_OFFSET	GENMASK(13, 8)
-#define OA_TC6_DATA_HEADER_PARITY		BIT(0)
-
-/* Data footer */
-#define OA_TC6_DATA_FOOTER_EXTENDED_STS		BIT(31)
-#define OA_TC6_DATA_FOOTER_RXD_HEADER_BAD	BIT(30)
-#define OA_TC6_DATA_FOOTER_CONFIG_SYNC		BIT(29)
-#define OA_TC6_DATA_FOOTER_RX_CHUNKS		GENMASK(28, 24)
-#define OA_TC6_DATA_FOOTER_DATA_VALID		BIT(21)
-#define OA_TC6_DATA_FOOTER_START_VALID		BIT(20)
-#define OA_TC6_DATA_FOOTER_START_WORD_OFFSET	GENMASK(19, 16)
-#define OA_TC6_DATA_FOOTER_END_VALID		BIT(14)
-#define OA_TC6_DATA_FOOTER_END_BYTE_OFFSET	GENMASK(13, 8)
-#define OA_TC6_DATA_FOOTER_TX_CREDITS		GENMASK(5, 1)
-
-#define OA_TC6_CTRL_PROT_REPLY_SIZE		4
-#define OA_TC6_CTRL_HEADER_SIZE			4
-#define OA_TC6_CTRL_REG_VALUE_SIZE		4
-#define OA_TC6_CTRL_IGNORED_SIZE		4
-#define OA_TC6_CTRL_MAX_REGISTERS		128
-#define OA_TC6_CTRL_SPI_BUF_SIZE	(OA_TC6_CTRL_HEADER_SIZE +\
-					(OA_TC6_CTRL_MAX_REGISTERS *\
-					(OA_TC6_CTRL_REG_VALUE_SIZE +\
-					OA_TC6_CTRL_PROT_REPLY_SIZE)) +\
-					OA_TC6_CTRL_IGNORED_SIZE)
-
-#define OA_TC6_CHUNK_PAYLOAD_SIZE		64
-#define OA_TC6_DATA_HEADER_SIZE			4
-#define OA_TC6_CHUNK_SIZE			(OA_TC6_DATA_HEADER_SIZE +\
-						OA_TC6_CHUNK_PAYLOAD_SIZE)
-#define OA_TC6_MAX_TX_CHUNKS			48
-#define OA_TC6_SPI_DATA_BUF_SIZE		(OA_TC6_MAX_TX_CHUNKS *\
-						OA_TC6_CHUNK_SIZE)
-#define STATUS0_RESETC_POLL_DELAY		1000
-#define STATUS0_RESETC_POLL_TIMEOUT		1000000
-
-#define OA_TC6_REG_MMS_MASK		GENMASK(19, 16)
-
-/* Internal structure for MAC-PHY drivers */
-struct oa_tc6 {
-	struct net_device *netdev;
-	struct phy_device *phydev;
-	struct mii_bus *mdiobus;
-	struct spi_device *spi;
-	struct mutex spi_ctrl_lock; /* Protects spi control transfer */
-	spinlock_t tx_skb_lock; /* Protects tx skb handling */
-	void *spi_ctrl_tx_buf;
-	void *spi_ctrl_rx_buf;
-	void *spi_data_tx_buf;
-	void *spi_data_rx_buf;
-	struct sk_buff *ongoing_tx_skb;
-	struct sk_buff *waiting_tx_skb;
-	struct sk_buff *rx_skb;
-	u16 tx_skb_offset;
-	u16 spi_data_tx_buf_offset;
-	u16 tx_credits;
-	u8 rx_chunks_available;
-	bool wait_until_start_valid;
-	bool int_flag;
-	bool disable_traffic;
-	bool prot_ctrl;
-	enum oa_tc6_quirk_flag quirk_flags;
-	struct gpio_desc *reset_gpio;
-};
-
-enum oa_tc6_header_type {
-	OA_TC6_CTRL_HEADER,
-	OA_TC6_DATA_HEADER,
-};
-
-enum oa_tc6_register_op {
-	OA_TC6_CTRL_REG_READ = 0,
-	OA_TC6_CTRL_REG_WRITE = 1,
-};
-
-enum oa_tc6_data_valid_info {
-	OA_TC6_DATA_INVALID,
-	OA_TC6_DATA_VALID,
-};
-
-enum oa_tc6_data_start_valid_info {
-	OA_TC6_DATA_START_INVALID,
-	OA_TC6_DATA_START_VALID,
-};
-
-enum oa_tc6_data_end_valid_info {
-	OA_TC6_DATA_END_INVALID,
-	OA_TC6_DATA_END_VALID,
-};
+#include "oa_tc6_std_def.h"
 
 static int oa_tc6_spi_transfer(struct oa_tc6 *tc6,
 			       enum oa_tc6_header_type header_type, u16 length)
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
new file mode 100644
index 000000000000..403a9c22b5f1
--- /dev/null
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -0,0 +1,125 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+/*
+ * Register and driver related definitions to support
+ * OPEN Alliance 10BASE‑T1x MAC‑PHY Serial Interface framework.
+ *
+ * Author: Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+ */
+
+#ifndef OA_TC6_STD_DEF_H
+#define OA_TC6_STD_DEF_H
+
+#include <linux/ptp_clock_kernel.h>
+#include <linux/net_tstamp.h>
+#include <linux/netdevice.h>
+#include <linux/spi/spi.h>
+#include <linux/skbuff.h>
+#include <linux/sched.h>
+#include <linux/wait.h>
+#include <linux/phy.h>
+
+/* Control command header */
+#define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
+#define OA_TC6_CTRL_HEADER_WRITE_NOT_READ	BIT(29)
+#define OA_TC6_CTRL_HEADER_MEM_MAP_SELECTOR	GENMASK(27, 24)
+#define OA_TC6_CTRL_HEADER_ADDR			GENMASK(23, 8)
+#define OA_TC6_CTRL_HEADER_LENGTH		GENMASK(7, 1)
+#define OA_TC6_CTRL_HEADER_PARITY		BIT(0)
+
+/* Data header */
+#define OA_TC6_DATA_HEADER_DATA_NOT_CTRL	BIT(31)
+#define OA_TC6_DATA_HEADER_DATA_VALID		BIT(21)
+#define OA_TC6_DATA_HEADER_START_VALID		BIT(20)
+#define OA_TC6_DATA_HEADER_START_WORD_OFFSET	GENMASK(19, 16)
+#define OA_TC6_DATA_HEADER_END_VALID		BIT(14)
+#define OA_TC6_DATA_HEADER_END_BYTE_OFFSET	GENMASK(13, 8)
+#define OA_TC6_DATA_HEADER_PARITY		BIT(0)
+
+/* Data footer */
+#define OA_TC6_DATA_FOOTER_EXTENDED_STS		BIT(31)
+#define OA_TC6_DATA_FOOTER_RXD_HEADER_BAD	BIT(30)
+#define OA_TC6_DATA_FOOTER_CONFIG_SYNC		BIT(29)
+#define OA_TC6_DATA_FOOTER_RX_CHUNKS		GENMASK(28, 24)
+#define OA_TC6_DATA_FOOTER_DATA_VALID		BIT(21)
+#define OA_TC6_DATA_FOOTER_START_VALID		BIT(20)
+#define OA_TC6_DATA_FOOTER_START_WORD_OFFSET	GENMASK(19, 16)
+#define OA_TC6_DATA_FOOTER_END_VALID		BIT(14)
+#define OA_TC6_DATA_FOOTER_END_BYTE_OFFSET	GENMASK(13, 8)
+#define OA_TC6_DATA_FOOTER_TX_CREDITS		GENMASK(5, 1)
+
+#define OA_TC6_CTRL_PROT_REPLY_SIZE		4
+#define OA_TC6_CTRL_HEADER_SIZE			4
+#define OA_TC6_CTRL_REG_VALUE_SIZE		4
+#define OA_TC6_CTRL_IGNORED_SIZE		4
+#define OA_TC6_CTRL_MAX_REGISTERS		128
+#define OA_TC6_CTRL_SPI_BUF_SIZE	(OA_TC6_CTRL_HEADER_SIZE +\
+					(OA_TC6_CTRL_MAX_REGISTERS *\
+					(OA_TC6_CTRL_REG_VALUE_SIZE +\
+					OA_TC6_CTRL_PROT_REPLY_SIZE)) +\
+					OA_TC6_CTRL_IGNORED_SIZE)
+
+#define OA_TC6_CHUNK_PAYLOAD_SIZE		64
+#define OA_TC6_DATA_HEADER_SIZE			4
+#define OA_TC6_CHUNK_SIZE			(OA_TC6_DATA_HEADER_SIZE +\
+						OA_TC6_CHUNK_PAYLOAD_SIZE)
+#define OA_TC6_MAX_TX_CHUNKS			48
+#define OA_TC6_SPI_DATA_BUF_SIZE		(OA_TC6_MAX_TX_CHUNKS *\
+						OA_TC6_CHUNK_SIZE)
+#define STATUS0_RESETC_POLL_DELAY		1000
+#define STATUS0_RESETC_POLL_TIMEOUT		1000000
+
+#define OA_TC6_REG_MMS_MASK		GENMASK(19, 16)
+
+/* Internal structure for MAC-PHY drivers */
+struct oa_tc6 {
+	struct net_device *netdev;
+	struct phy_device *phydev;
+	struct mii_bus *mdiobus;
+	struct spi_device *spi;
+	struct mutex spi_ctrl_lock; /* Protects spi control transfer */
+	spinlock_t tx_skb_lock; /* Protects tx skb handling */
+	void *spi_ctrl_tx_buf;
+	void *spi_ctrl_rx_buf;
+	void *spi_data_tx_buf;
+	void *spi_data_rx_buf;
+	struct sk_buff *ongoing_tx_skb;
+	struct sk_buff *waiting_tx_skb;
+	struct sk_buff *rx_skb;
+	u16 tx_skb_offset;
+	u16 spi_data_tx_buf_offset;
+	u16 tx_credits;
+	u8 rx_chunks_available;
+	bool wait_until_start_valid;
+	bool int_flag;
+	bool disable_traffic;
+	bool prot_ctrl;
+	enum oa_tc6_quirk_flag quirk_flags;
+	struct gpio_desc *reset_gpio;
+};
+
+enum oa_tc6_header_type {
+	OA_TC6_CTRL_HEADER,
+	OA_TC6_DATA_HEADER,
+};
+
+enum oa_tc6_register_op {
+	OA_TC6_CTRL_REG_READ = 0,
+	OA_TC6_CTRL_REG_WRITE = 1,
+};
+
+enum oa_tc6_data_valid_info {
+	OA_TC6_DATA_INVALID,
+	OA_TC6_DATA_VALID,
+};
+
+enum oa_tc6_data_start_valid_info {
+	OA_TC6_DATA_START_INVALID,
+	OA_TC6_DATA_START_VALID,
+};
+
+enum oa_tc6_data_end_valid_info {
+	OA_TC6_DATA_END_INVALID,
+	OA_TC6_DATA_END_VALID,
+};
+#endif /* OA_TC6_STD_DEF_H */
+

-- 
2.43.0

