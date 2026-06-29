From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Mon, 29 Jun 2026 10:23:42 -0700
Subject: [PATCH net-next v6 12/15] onsemi: s2500: Add driver support for
 TS2500 MAC-PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-s2500-mac-phy-support-v6-12-18ce79500371@onsemi.com>
References: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
In-Reply-To: <20260629-s2500-mac-phy-support-v6-0-18ce79500371@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782753817; l=49502;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=0D1IRZvRSofSEL/jq/vxtZjTpOyZ2eKv5m3gHwy7+JA=;
 b=ozlBnbmf8wCBW/7VULzSmdHOVbE2OVUWFmO8B72KomiqVzZWZuOs96yJRWSYaAAcnqlcQBlxA
 Gxk+fGMvKqDDdncBgwLA5nJXlQsUMAxbl9anDTxYgoAtt18Z5oSAhul
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for onsemi's S2500, 802.3 cg compliant Ethernet
transceiver with integrated MAC-PHY. Works with
Open Alliance TC6 framework.

adjtime callback is implemented using adjfine. If time
delta is too big, bigger than 1 second, using adjtime
would take long to reduce the delta. In those cases,
settime callback is used to reduce the delta. Once delta
becomes less than a second, it uses adjfine to reduce
the drift further.

Driver has ethtool support for printing some device
registers, traffic stats, rmon stats and hardware
timestamp realated settings and traffic counters.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v6
  - Changes to ensure line length stay within 80 columns
changes in v5
  - integrated the onsemi's selftest support to onsemi's driver
    as a single patch as number of patches exceeded the limit
  - Fixed the formatting issue in Kconfig file
  - Fixed commenting issue
changes in v4
  - MAC/PHY Loopback implemented by onsemi replaced by Linux
    standard net_selftest APIs
  - onsemi defined MMS values are replaced by OA TC definitions.
  - removed only model information as it has practical use
  - replaced all read/write APIs that use non-zero MMS to
    use the new APIs that takes mms as one of its parameters.
  - some bit manipulations are changed to use FIELD_GET macro
changes in v3
  - split rmon stats and interface states separately.
  - moved get_ts_info to OA TC6 framework as this isn't vendor
    specific
  - removed few static inline code
  - moved ptp register code OA TC6 framework
changes in v2
  - Removed the support for onsemi's NCN26010 which is legacy
    MAC-PHY to keep only onsemi's S2500 MAC-PHY
  - Renamed all the functions to start with S2500
changes in v1
  - Added onsemi MAC-PHYs NCN26010 and S2500 support
---
 MAINTAINERS                                       |   7 +
 drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h      |   2 +-
 drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c       |   3 +-
 drivers/net/ethernet/onsemi/Kconfig               |  21 +
 drivers/net/ethernet/onsemi/Makefile              |   7 +
 drivers/net/ethernet/onsemi/s2500/Kconfig         |  21 +
 drivers/net/ethernet/onsemi/s2500/Makefile        |   7 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c | 353 ++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h  | 225 ++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c    | 655 ++++++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c     | 250 +++++++++
 11 files changed, 1548 insertions(+), 3 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 85b6dbc09d59..00d1b919842a 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20194,6 +20194,13 @@ S:	Supported
 W:	http://www.onsemi.com
 F:	drivers/net/phy/ncn*
 
+ONSEMI S2500 10BASE-T1S MACPHY ETHERNET DRIVER
+M:	Selva Rajagopal <selvamani.rajagopal@onsemi.com>
+L:	netdev@vger.kernel.org
+S:	Supported
+F:	Documentation/devicetree/bindings/net/onnn,s2500.yaml
+F:	drivers/net/ethernet/onsemi/s2500/s2500_*
+
 OP-TEE DRIVER
 M:	Jens Wiklander <jens.wiklander@linaro.org>
 L:	op-tee@lists.trustedfirmware.org (moderated for non-subscribers)
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
index e8ec379dd60d..c894c9d22182 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_std_def.h
@@ -66,7 +66,7 @@
 #define OA_TC6_PHY_STD_REG_ADDR_MASK		0x1F
 
 /* Tx timestamp capture register A (high) */
-#define OA_TC6_REG_TTSCA_HIGH			(0x1010)
+#define OA_TC6_REG_TTSCA_HIGH			(0x10)
 
 /* Control command header */
 #define OA_TC6_CTRL_HEADER_DATA_NOT_CTRL	BIT(31)
diff --git a/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
index 272701a4081d..a2b1a1b5690e 100644
--- a/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
+++ b/drivers/net/ethernet/oa_tc6/oa_tc6_tstamp.c
@@ -137,7 +137,7 @@ EXPORT_SYMBOL_GPL(oa_tc6_hwtstamp_set);
 /**
  * oa_tc6_get_ts_stats - Provides timestamping stats
  * @tc6: oa_tc6 struct.
- * @ts_stats: ethtool data structure to fill in
+ * @stats: ethtool data structure to fill in
  */
 void oa_tc6_get_ts_stats(struct oa_tc6 *tc6,
 			 struct ethtool_ts_stats *stats)
@@ -179,7 +179,6 @@ int oa_tc6_tstamp_ioctl(struct oa_tc6 *tc6, struct ifreq *rq, int cmd)
  * oa_tc6_get_ts_info - Provides timestamp info for ethtool
  * @tc6: oa_tc6 struct.
  * @info: ethtool timestamping info structure
- * @ts_stats: ethtool data structure to fill in
  */
 int oa_tc6_get_ts_info(struct oa_tc6 *tc6,
 		       struct kernel_ethtool_ts_info *info)
diff --git a/drivers/net/ethernet/onsemi/Kconfig b/drivers/net/ethernet/onsemi/Kconfig
new file mode 100644
index 000000000000..8d72194151ea
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/Kconfig
@@ -0,0 +1,21 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# onsemi network device configuration
+#
+
+config NET_VENDOR_ONSEMI
+	bool "onsemi network devices"
+	help
+	  If you have a network card belonging to this class, say Y.
+
+	  Note that the answer to this question doesn't directly affect the
+	  kernel: saying N will just cause the configurator to skip all
+	  the questions about onsemi ethernet devices. If you say Y, you
+	  will be asked for your specific card in the following questions.
+
+if NET_VENDOR_ONSEMI
+
+source "drivers/net/ethernet/onsemi/s2500/Kconfig"
+
+endif # NET_VENDOR_ONSEMI
+
diff --git a/drivers/net/ethernet/onsemi/Makefile b/drivers/net/ethernet/onsemi/Makefile
new file mode 100644
index 000000000000..f3d4eb154313
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/Makefile
@@ -0,0 +1,7 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Makefile for the onsemi network device drivers.
+#
+
+obj-$(CONFIG_S2500_MACPHY) += s2500/
+
diff --git a/drivers/net/ethernet/onsemi/s2500/Kconfig b/drivers/net/ethernet/onsemi/s2500/Kconfig
new file mode 100644
index 000000000000..f2e8d5d1429d
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/Kconfig
@@ -0,0 +1,21 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# onsemi S2500 Driver Support
+#
+
+if NET_VENDOR_ONSEMI
+
+config S2500_MACPHY
+	tristate "S2500 support"
+	depends on SPI
+	select NCN26000_PHY
+	select OA_TC6
+	help
+	  Support for the onsemi TS2500 MACPHY Ethernet chip.
+	  It works under the framework that conform to OPEN Alliance
+	  10BASE-T1x Serial Interface specification.
+
+	  To compile this driver as a module, choose M here. The module will be
+	  called s2500.
+
+endif # NET_VENDOR_ONSEMI
diff --git a/drivers/net/ethernet/onsemi/s2500/Makefile b/drivers/net/ethernet/onsemi/s2500/Makefile
new file mode 100644
index 000000000000..61ec705cdf9f
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/Makefile
@@ -0,0 +1,7 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Makefile for the onsemi network device drivers.
+#
+obj-$(CONFIG_S2500_MACPHY) := s2500.o
+s2500-objs := s2500_main.o s2500_ethtool.o s2500_ptp.o
+
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
new file mode 100644
index 000000000000..7760cec57849
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
@@ -0,0 +1,353 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#include <linux/ethtool.h>
+#include <linux/phy.h>
+
+#include "s2500_hw_def.h"
+
+#define S2500_NUM_REGS			38
+#define S2500_REGDUMP_LEN		(sizeof(u32) * (S2500_NUM_REGS * 2))
+
+#define S2500_NUM_MAC_STATS		21
+#define S2500_NUM_RMON_STATS		12
+
+struct s2500_reg_map {
+	u16 reg;
+	u16 mms;
+};
+
+static const struct s2500_reg_map s2500_reg_map[S2500_NUM_REGS] = {
+	{ S2500_REG_VS_ONIPVER,      OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_TWEAKS1,      OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_PLCAEXT,      OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_PMATUNE0,     OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_PMATUNE1,     OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_T1SWUPTUNE,   OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_HDD,          OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_DCQ_TOID,     OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_DCQ_SQI,      OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_DCQ_SQI_PLUS, OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_HDD_TUNE1,    OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_HDD_TUNE2,    OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_HDD_TUNE3,    OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_WS_STATUS_0,  OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_WS_CTRL_0,    OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_WS_STATUS_1,  OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_WS_CTRL_1,    OA_TC6_PHY_C45_VS_PLCA_MMS4 },
+	{ S2500_REG_VS_MIIMIRQE,     OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_MIIMIRQS,     OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_DIOCFG0,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CHIPID,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_TWEAKS2,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_MACID0,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_MACID1,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_NVM_HEALTH,   OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_PTP_SEC,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_PTPNSEC,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_PTP_SETSEC,   OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_SETNSEC,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_PTP_ADJ,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CMPCTL,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CMPSEC,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CMPNSEC,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CMPPER,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CAPCTL,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CAPSEC,       OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_CAPNSEC,      OA_TC6_PHY_C45_VS_MMS12 },
+	{ S2500_REG_VS_BCNCNT,       OA_TC6_PHY_C45_VS_MMS12 },
+};
+
+enum s2500_stat_idx {
+	S2500_MSTOCTECTSTX_IDX = 0,
+	S2500_MSTFRAMESTXOK_IDX,
+	S2500_MSTBCASTTXOK_IDX,
+	S2500_MSTMCASTTXOK_IDX,
+	S2500_MSTFRAMESTX64_IDX,
+	S2500_MSTFRAMESTX65_IDX,
+	S2500_MSTFRAMESTX128_IDX,
+	S2500_MSTFRAMESTX256_IDX,
+	S2500_MSTFRAMESTX512_IDX,
+	S2500_MSTFRAMESTX1024_IDX,
+	S2500_MSTTXUNDEFLOW_IDX,
+	S2500_MSTSINGLECOL_IDX,
+	S2500_MSTMULTICOL_IDX,
+	S2500_MSTEXCESSCOL_IDX,
+	S2500_MSTDEFERREDTX_IDX,
+	S2500_MSTCRSERR_IDX,
+	S2500_MSTOCTECTSRX_IDX,
+	S2500_MSTFRAMESRXOK_IDX,
+	S2500_MSTBCASTRXOK_IDX,
+	S2500_MSTMCASTRXOK_IDX,
+	S2500_MSTFRAMESRX64_IDX,
+	S2500_MSTFRAMESRX65_IDX,
+	S2500_MSTFRAMESRX128_IDX,
+	S2500_MSTFRAMESRX256_IDX,
+	S2500_MSTFRAMESRX512_IDX,
+	S2500_MSTFRAMESRX1024_IDX,
+	S2500_MSTRUNTSERR_IDX,
+	S2500_MSTRXTOOLONG_IDX,
+	S2500_MSTFCSERRS_IDX,
+	S2500_MSTSYMBOLERRS_IDX,
+	S2500_MSTALIGNERRS_IDX,
+	S2500_MSTRXOVERFLOW_IDX,
+	S2500_MSTRXDROPPED_IDX,
+};
+
+static const char s2500_mac_stat_strings[][ETH_GSTRING_LEN] = {
+	"tx_bytes",
+	"tx_frames",
+	"tx_broadcast_frames",
+	"tx_multicast_frames",
+	"tx_underflow_errors",
+	"tx_single_collisions",
+	"tx_multiple_collisions",
+	"tx_excessive_collisions",
+	"tx_deferred_frames",
+	"tx_carrier_sense_errors",
+	"rx_bytes",
+	"rx_frames",
+	"rx_broadcast_frames",
+	"rx_multicast_frames",
+	"rx_runts",
+	"rx_oversize_frames",
+	"rx_crc_errors",
+	"rx_symbol_errors",
+	"rx_alignment_errors",
+	"rx_busy_drops",
+	"rx_mismatch_drops",
+};
+
+static const u8 s2500_mac_stat_map[S2500_NUM_MAC_STATS] = {
+	S2500_MSTOCTECTSTX_IDX,
+	S2500_MSTFRAMESTXOK_IDX,
+	S2500_MSTBCASTTXOK_IDX,
+	S2500_MSTMCASTTXOK_IDX,
+	S2500_MSTTXUNDEFLOW_IDX,
+	S2500_MSTSINGLECOL_IDX,
+	S2500_MSTMULTICOL_IDX,
+	S2500_MSTEXCESSCOL_IDX,
+	S2500_MSTDEFERREDTX_IDX,
+	S2500_MSTCRSERR_IDX,
+	S2500_MSTOCTECTSRX_IDX,
+	S2500_MSTFRAMESRXOK_IDX,
+	S2500_MSTBCASTRXOK_IDX,
+	S2500_MSTMCASTRXOK_IDX,
+	S2500_MSTRUNTSERR_IDX,
+	S2500_MSTRXTOOLONG_IDX,
+	S2500_MSTFCSERRS_IDX,
+	S2500_MSTSYMBOLERRS_IDX,
+	S2500_MSTALIGNERRS_IDX,
+	S2500_MSTRXOVERFLOW_IDX,
+	S2500_MSTRXDROPPED_IDX,
+};
+
+static const u8 s2500_rmon_stat_map[S2500_NUM_RMON_STATS] = {
+	S2500_MSTFRAMESTX64_IDX,
+	S2500_MSTFRAMESTX65_IDX,
+	S2500_MSTFRAMESTX128_IDX,
+	S2500_MSTFRAMESTX256_IDX,
+	S2500_MSTFRAMESTX512_IDX,
+	S2500_MSTFRAMESTX1024_IDX,
+	S2500_MSTFRAMESRX64_IDX,
+	S2500_MSTFRAMESRX65_IDX,
+	S2500_MSTFRAMESRX128_IDX,
+	S2500_MSTFRAMESRX256_IDX,
+	S2500_MSTFRAMESRX512_IDX,
+	S2500_MSTFRAMESRX1024_IDX,
+};
+
+static const struct ethtool_rmon_hist_range s2500_rmon_hist_ranges[] = {
+	{ 64, 64 },
+	{ 65, 127 },
+	{ 128, 255 },
+	{ 256, 511 },
+	{ 512, 1023 },
+	{ 1024, 2000 },
+	{ },
+};
+
+#define S2500_MAC_STATS_LEN ARRAY_SIZE(s2500_mac_stat_strings)
+static_assert(S2500_MAC_STATS_LEN == S2500_NUM_MAC_STATS);
+static_assert(ARRAY_SIZE(s2500_mac_stat_map) == S2500_NUM_MAC_STATS);
+static_assert(ARRAY_SIZE(s2500_rmon_stat_map) == S2500_NUM_RMON_STATS);
+
+#define STAT_REG_OFFSET(x) ((S2500_REG_MAC_ST##x) - \
+			   S2500_REG_MAC_FIRST_STAT)
+
+static void s2500_update_stats(struct s2500_info *priv)
+{
+	u64 *data = priv->stats_data;
+	u32 *regs, *rptr;
+	int ret;
+
+	regs = kmalloc_array(S2500_NUM_STAT_REGS, sizeof(u32), GFP_KERNEL);
+	if (!regs)
+		return;
+
+	ret = oa_tc6_read_registers_mms(priv->tc6, S2500_REG_MAC_STOCTECTSTXL,
+					OA_TC6_PHY_C45_MAC_MMS1, regs,
+					S2500_NUM_STAT_REGS);
+	if (ret)
+		goto out;
+
+	rptr = regs;
+
+	/* TX bytes is a 64-bit register that spans over two 32-bit regs
+	 * note: HW does auto-freeze when reading LSB and un-freeze on MSB
+	 */
+	*(data++) += ((u64)*rptr) | (((u64)*(rptr + 1)) << 32);
+
+	/* run until the next 64-bit register */
+	for (rptr += 2; (rptr - regs) < STAT_REG_OFFSET(OCTECTSRXL); ++rptr)
+		*(data++) += *rptr;
+
+	/* RX bytes is a 64-bit register that spans over two 32-bit regs
+	 * note: HW does auto-freeze when reading LSB and un-freeze on MSB
+	 */
+	*(data++) += ((u64)*rptr) | (((u64)*(rptr + 1)) << 32);
+
+	for (rptr += 2; (rptr - regs) < S2500_NUM_STAT_REGS; ++rptr)
+		*(data++) += *rptr;
+out:
+	kfree(regs);
+}
+
+static void s2500_get_drvinfo(struct net_device *ndev,
+			      struct ethtool_drvinfo *info)
+{
+	strscpy(info->driver, DRV_NAME, sizeof(info->driver));
+	strscpy(info->bus_info, dev_name(&ndev->dev),
+		sizeof(info->bus_info));
+}
+
+static int s2500_get_sset_count(struct net_device *ndev, int sset)
+{
+	switch (sset) {
+	case ETH_SS_STATS:
+		return S2500_MAC_STATS_LEN;
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static void s2500_get_strings(struct net_device *ndev, u32 stringset,
+			      u8 *buf)
+{
+	switch (stringset) {
+	case ETH_SS_STATS:
+		memcpy(buf, s2500_mac_stat_strings,
+		       S2500_MAC_STATS_LEN * ETH_GSTRING_LEN);
+		break;
+	}
+}
+
+static void s2500_get_ethtool_stats(struct net_device *ndev,
+				    struct ethtool_stats *stats, u64 *data)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	int i;
+
+	s2500_update_stats(priv);
+	for (i = 0; i < S2500_NUM_MAC_STATS; i++)
+		data[i] = priv->stats_data[s2500_mac_stat_map[i]];
+}
+
+static void s2500_rmon_stats(struct net_device *ndev,
+			     struct ethtool_rmon_stats *rmon_stats,
+			     const struct ethtool_rmon_hist_range **ranges)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u8 offset;
+	int i;
+
+	s2500_update_stats(priv);
+
+	memset(rmon_stats, 0, sizeof(*rmon_stats));
+	rmon_stats->src = ETHTOOL_MAC_STATS_SRC_AGGREGATE;
+	rmon_stats->undersize_pkts = priv->stats_data[S2500_MSTRUNTSERR_IDX];
+	rmon_stats->oversize_pkts = priv->stats_data[S2500_MSTRXTOOLONG_IDX];
+	rmon_stats->fragments = priv->stats_data[S2500_MSTFCSERRS_IDX];
+	rmon_stats->jabbers = priv->stats_data[S2500_MSTALIGNERRS_IDX];
+
+	for (i = 0; i < 6; i++) {
+		offset = s2500_rmon_stat_map[i];
+		rmon_stats->hist_tx[i] = priv->stats_data[offset];
+	}
+
+	for (i = 0; i < 6; i++) {
+		offset = s2500_rmon_stat_map[i + 6];
+		rmon_stats->hist[i] = priv->stats_data[offset];
+	}
+
+	*ranges = s2500_rmon_hist_ranges;
+}
+
+static int s2500_get_ts_info(struct net_device *ndev,
+			     struct kernel_ethtool_ts_info *ts_info)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	return oa_tc6_get_ts_info(priv->tc6, ts_info);
+}
+
+static int s2500_get_regs_len(struct net_device *dev)
+{
+	return S2500_REGDUMP_LEN;
+}
+
+static void s2500_get_regs(struct net_device *ndev,
+			   struct ethtool_regs *regs, void *p)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u32 *pbuff = (u32 *)p;
+	u16 reg, mms;
+	int ret = 0;
+	u32 val;
+	int i;
+
+	regs->version = 0;
+	memset(p, 0, S2500_REGDUMP_LEN);
+
+	if (!netif_running(ndev))
+		return;
+
+	for (i = 0; i < S2500_NUM_REGS; i++) {
+		val = 0;
+		reg = s2500_reg_map[i].reg;
+		mms = s2500_reg_map[i].mms;
+		ret = oa_tc6_read_register_mms(priv->tc6, reg, mms,
+					       &val);
+		if (ret)
+			continue;
+		*pbuff++ = cpu_to_be32(((u32)mms << 16) | reg);
+		*pbuff++ = cpu_to_be32(val);
+	}
+}
+
+static void s2500_get_ts_stats(struct net_device *ndev,
+			       struct ethtool_ts_stats *ts_stats)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	oa_tc6_get_ts_stats(priv->tc6, ts_stats);
+}
+
+const struct ethtool_ops s2500_ethtool_ops = {
+	.get_drvinfo        = s2500_get_drvinfo,
+	.get_link           = ethtool_op_get_link,
+	.get_link_ksettings = phy_ethtool_get_link_ksettings,
+	.set_link_ksettings = phy_ethtool_set_link_ksettings,
+	.get_ts_stats       = s2500_get_ts_stats,
+	.get_sset_count     = s2500_get_sset_count,
+	.get_strings        = s2500_get_strings,
+	.get_ethtool_stats  = s2500_get_ethtool_stats,
+	.get_rmon_stats     = s2500_rmon_stats,
+	.get_ts_info        = s2500_get_ts_info,
+	.get_regs_len       = s2500_get_regs_len,
+	.get_regs           = s2500_get_regs,
+};
+
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
new file mode 100644
index 000000000000..2cd0aa1593b6
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
@@ -0,0 +1,225 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#ifndef S2500_HW_DEF_H
+#define S2500_HW_DEF_H
+
+#include <linux/hrtimer.h>
+#include <linux/irq.h>
+#include <linux/irqdomain.h>
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/phylink.h>
+#include <linux/spi/spi.h>
+#include <linux/oa_tc6.h>
+#include <linux/net_tstamp.h>
+#include <linux/ptp_clock_kernel.h>
+#include <linux/delay.h>
+#include <linux/mutex.h>
+#include <linux/ktime.h>
+#include <linux/errno.h>
+
+#define DRV_NAME			"s2500"
+
+#define S2500_N_MCAST_FILTERS		3
+
+/* SPI OID and model register */
+#define S2500_REG_SPI_PHYID		0x1
+
+#define S2500_SPI_PHYID_OUI_SHIFT	10
+#define S2500_SPI_PHYID_OUI_MASK	GENMASK(31, S2500_SPI_PHYID_OUI_SHIFT)
+#define S2500_SPI_PHYID_OUI_MASK0	GENMASK(21, 16)
+#define S2500_SPI_PHYID_OUI_MASK1	GENMASK(15, 8)
+#define S2500_SPI_PHYID_OUI_MASK2	GENMASK(7, 0)
+/* SPI configuration register #0 */
+#define S2500_REG_SPI_CFG0		0x4
+
+#define S2500_SPI_CFG0_SYNC_BIT		BIT(15)
+#define S2500_SPI_CFG0_TXCTHRESH_SHIFT	10
+#define S2500_SPI_CFG0_RXCTE_BIT	BIT(8)
+#define S2500_SPI_CFG0_FTSS_64_BIT	BIT(6)
+#define S2500_SPI_CFG0_CPS_SHIFT	0
+
+#define S2500_TXCTHRESH_8		0x2
+
+#define S2500_CPS_64			0x6
+
+/* SPI status register #0 */
+#define S2500_REG_SPI_ST0		0x8
+
+#define S2500_SPI_ST0_CDPE_BIT		BIT(12)
+#define S2500_SPI_ST0_TXFCSE_BIT	BIT(11)
+#define S2500_SPI_ST0_TTSCAC_BIT	BIT(10)
+#define S2500_SPI_ST0_TTSCAB_BIT	BIT(9)
+#define S2500_SPI_ST0_TTSCAA_BIT	BIT(8)
+#define S2500_SPI_ST0_RESETC_BIT	BIT(6)
+#define S2500_SPI_ST0_HDRE_BIT		BIT(5)
+#define S2500_SPI_ST0_LOFE_BIT		BIT(4)
+#define S2500_SPI_ST0_RXBOE_BIT		BIT(3)
+#define S2500_SPI_ST0_TXBUE_BIT		BIT(2)
+#define S2500_SPI_ST0_TXBOE_BIT		BIT(1)
+#define S2500_SPI_ST0_TXPE_BIT		BIT(0)
+
+/* SPI IRQ enable register #0 (use the S2500_SPI_ST0_*_BIT constants) */
+#define S2500_REG_SPI_IRQM0		0xc
+
+/* SPI buffer status register */
+#define S2500_REG_SPI_BUFST		0xb
+
+#define S2500_REG_MAC_CTRL		0x0
+
+#define S2500_MAC_CTRL_MCSF_BIT		BIT(18)
+#define S2500_MAC_CTRL_ADRF_BIT		BIT(16)
+#define S2500_MAC_CTRL_FCSA_BIT		BIT(8)
+#define S2500_MAC_CTRL_TXEN_BIT		BIT(1)
+#define S2500_MAC_CTRL_RXEN_BIT		BIT(0)
+
+/* MAC address filter registers */
+#define S2500_REG_MAC_ADDRFILTL(n)	(16 + 2 * (n))
+#define S2500_REG_MAC_ADDRFILTH(n)	(17 + 2 * (n))
+#define S2500_REG_MAC_ADDRMASKL(n)	(32 + 2 * (n))
+#define S2500_REG_MAC_ADDRMASKH(n)	(33 + 2 * (n))
+
+#define S2500_MAC_ADDRFILT_EN_BIT	BIT(31)
+
+/* MAC statistic registers */
+#define S2500_REG_MAC_STOCTECTSTXL	48
+#define S2500_REG_MAC_STOCTECTSTXH	49
+#define S2500_REG_MAC_STFRAMESTXOK	50
+#define S2500_REG_MAC_STBCASTTXOK	51
+#define S2500_REG_MAC_STMCASTTXOK	52
+#define S2500_REG_MAC_STFRAMESTX64	53
+#define S2500_REG_MAC_STFRAMESTX65	54
+#define S2500_REG_MAC_STFRAMESTX128	55
+#define S2500_REG_MAC_STFRAMESTX256	56
+#define S2500_REG_MAC_STFRAMESTX512	57
+#define S2500_REG_MAC_STFRAMESTX1024	58
+#define S2500_REG_MAC_STTXUNDEFLOW	59
+#define S2500_REG_MAC_STSINGLECOL	60
+#define S2500_REG_MAC_STMULTICOL	61
+#define S2500_REG_MAC_STEXCESSCOL	62
+#define S2500_REG_MAC_STDEFERREDTX	63
+#define S2500_REG_MAC_STCRSERR		64
+#define S2500_REG_MAC_STOCTECTSRXL	65
+#define S2500_REG_MAC_STOCTECTSRXH	66
+#define S2500_REG_MAC_STFRAMESRXOK	67
+#define S2500_REG_MAC_STBCASTRXOK	68
+#define S2500_REG_MAC_STMCASTRXOK	69
+#define S2500_REG_MAC_STFRAMESRX64	70
+#define S2500_REG_MAC_STFRAMESRX65	71
+#define S2500_REG_MAC_STFRAMESRX128	72
+#define S2500_REG_MAC_STFRAMESRX256	73
+#define S2500_REG_MAC_STFRAMESRX512	74
+#define S2500_REG_MAC_STFRAMESRX1024	75
+#define S2500_REG_MAC_STRUNTSERR	76
+#define S2500_REG_MAC_STRXTOOLONG	77
+#define S2500_REG_MAC_STFCSERRS		78
+#define S2500_REG_MAC_STSYMBOLERRS	79
+#define S2500_REG_MAC_STALIGNERRS	80
+#define S2500_REG_MAC_STRXOVERFLOW	81
+#define S2500_REG_MAC_STRXDROPPED	82
+
+/* First/last statistic register for sequential access */
+#define S2500_REG_MAC_FIRST_STAT	S2500_REG_MAC_STOCTECTSTXL
+#define S2500_REG_MAC_LAST_STAT		S2500_REG_MAC_STRXDROPPED
+
+#define S2500_NUM_STAT_REGS \
+	(S2500_REG_MAC_LAST_STAT - S2500_REG_MAC_FIRST_STAT + 1)
+#define S2500_NUM_STAT_VARS		(S2500_NUM_STAT_REGS - 2)
+
+/* Vendor specific MMS4 registers */
+#define S2500_REG_VS_ONIPVER		0x8000
+#define S2500_REG_VS_TWEAKS1		0x8001
+#define S2500_REG_VS_PLCAEXT		0x8002
+#define S2500_REG_VS_PMATUNE0		0x8003
+#define S2500_REG_VS_PMATUNE1		0x8004
+#define S2500_REG_VS_T1SWUPTUNE		0x8007
+#define S2500_REG_VS_HDD		0xCC01
+#define S2500_REG_VS_DCQ_TOID		0xCC02
+#define S2500_REG_VS_DCQ_SQI		0xCC03
+#define S2500_REG_VS_DCQ_SQI_PLUS	0xCC04
+#define S2500_REG_VS_HDD_TUNE1		0xCD00
+#define S2500_REG_VS_HDD_TUNE2		0xCD01
+#define S2500_REG_VS_HDD_TUNE3		0xCD02
+#define S2500_REG_VS_WS_STATUS_0	0xD000
+#define S2500_REG_VS_WS_CTRL_0		0xD001
+#define S2500_REG_VS_WS_STATUS_1	0xD100
+#define S2500_REG_VS_WS_CTRL_1		0xD101
+
+/* Vendor specific MMS12 registers */
+#define S2500_REG_VS_MIIMIRQE		0x10
+
+/* MIIM IRQ status register */
+#define S2500_REG_VS_MIIMIRQS		0x11
+#define MIIM_IRQ_STATUS_RSTS_SHIFT	15
+#define MIIM_IRQ_STATUS_RSTS		BIT(MIIM_IRQ_STATUS_RSTS_SHIFT)
+
+#define S2500_REG_VS_DIOCFG0		0x12
+
+#define S2500_REG_VS_CHIPID		0x1000
+#define S2500_REG_VS_TWEAKS2		0x1001
+
+/* Permanent MAC address register */
+#define S2500_REG_VS_MACID0		0x1002
+#define S2500_VS_MACID0_BYTE4_MASK	GENMASK(15, 8)
+#define S2500_VS_MACID0_BYTE5_MASK	GENMASK(7, 0)
+
+#define S2500_REG_VS_MACID1		0x1003
+#define S2500_VS_MACID1_BYTE3_MASK	GENMASK(7, 0)
+#define S2500_REG_VS_NVM_HEALTH		0x1005
+
+/* PTP registers */
+#define S2500_REG_VS_PTP_SEC		0x1010
+#define S2500_REG_VS_PTP_SETSEC		0x1012
+#define S2500_REG_VS_PTP_ADJ		0x1014
+#define S2500_REG_VS_PTPNSEC		0x1011
+#define S2500_REG_VS_SETNSEC		0x1013
+#define S2500_REG_VS_CMPCTL		0x1015
+#define S2500_REG_VS_CMPSEC		0x1016
+#define S2500_REG_VS_CMPNSEC		0x1017
+#define S2500_REG_VS_CMPPER		0x1018
+#define S2500_REG_VS_CAPCTL		0x1019
+#define S2500_REG_VS_CAPSEC		0x101A
+#define S2500_REG_VS_CAPNSEC		0x101B
+#define S2500_REG_VS_BCNCNT		0x101C
+
+/* prototypes / forward declarations */
+extern const struct ethtool_ops s2500_ethtool_ops;
+
+struct s2500_info;
+
+struct s2500_info {
+	struct device *dev;
+	struct net_device *ndev;
+
+	/* To have atomic set_rx_mode operation */
+	spinlock_t lock;
+
+	/* To have atomic operation when time is adjusted */
+	struct mutex ptp_adj_lock;
+	struct task_struct *thread;
+
+	/* global state variables */
+	bool event_pending;
+	unsigned int ndev_flags;
+	bool rx_flags_upd;
+
+	signed long poll_jiff;
+
+	struct spi_device *spi;
+
+	/* statistic counters variables */
+	u64 stats_data[S2500_NUM_STAT_VARS];
+
+	/* PTP related variables */
+	struct ptp_clock_info ptp_clock_info;
+	void *tc6;
+};
+
+int s2500_ptp_register(struct s2500_info *priv);
+
+#endif /* S2500_HW_DEF_H */
+
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_main.c b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
new file mode 100644
index 000000000000..687c98b69cc0
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
@@ -0,0 +1,655 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#include <linux/etherdevice.h>
+#include <linux/if_ether.h>
+#include <linux/irqchip.h>
+#include <linux/module.h>
+#include <linux/platform_device.h>
+#include <linux/bitrev.h>
+#include <linux/phy.h>
+
+#include "s2500_hw_def.h"
+
+/* S2500 functions & definitions */
+
+#define S2500_STATUS0_MASK	(S2500_SPI_ST0_CDPE_BIT | \
+				S2500_SPI_ST0_TXFCSE_BIT | \
+				S2500_SPI_ST0_TTSCAC_BIT | \
+				S2500_SPI_ST0_TTSCAB_BIT | \
+				S2500_SPI_ST0_TTSCAA_BIT | \
+				S2500_SPI_ST0_RESETC_BIT | \
+				S2500_SPI_ST0_HDRE_BIT | \
+				S2500_SPI_ST0_LOFE_BIT | \
+				S2500_SPI_ST0_RXBOE_BIT | \
+				S2500_SPI_ST0_TXBUE_BIT | \
+				S2500_SPI_ST0_TXBOE_BIT | \
+				S2500_SPI_ST0_TXPE_BIT)
+
+/* Initializes the net device MAC address by reading the UID stored
+ * into the device internal non-volatile memory.
+ */
+static int s2500_read_mac_from_nvmem(struct s2500_info *priv)
+{
+	u16 mms = OA_TC6_PHY_C45_VS_MMS12;
+	u8 addr[ETH_ALEN];
+	u32 mac1 = 0;
+	u32 mac0 = 0;
+	u32 val;
+	int ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, S2500_REG_VS_MACID1,
+				       mms, &mac1);
+	if (ret)
+		return ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, S2500_REG_VS_MACID0,
+				       mms, &mac0);
+	if (ret)
+		return ret;
+
+	/* Pre-production parts may have 0 */
+	if (mac0 == 0 && mac1 == 0)
+		return -ENXIO;
+
+	ret = oa_tc6_read_register(priv->tc6, S2500_REG_SPI_PHYID,
+				   &val);
+	if (ret)
+		return ret;
+
+	val = (val & S2500_SPI_PHYID_OUI_MASK) >>
+	       S2500_SPI_PHYID_OUI_SHIFT;
+
+	/* Mapping for bits from PHY ID register to OUI as give below.
+	 * - PHY-ID[10:17] provides OUI[16:23]
+	 * - PHY-ID[18:25] provides OUI[8:15]
+	 * - PHY-ID[26:31] provides OUI[2:7]
+	 *
+	 * Hardware presents OUI such a way that this requires not just
+	 * byte level swap, bit level swap is needed as well.
+	 */
+	addr[0] = bitrev8(FIELD_GET(S2500_SPI_PHYID_OUI_MASK0, val));
+	addr[1] = bitrev8(FIELD_GET(S2500_SPI_PHYID_OUI_MASK1, val));
+	addr[2] = bitrev8(FIELD_GET(S2500_SPI_PHYID_OUI_MASK2, val));
+
+	addr[3] = FIELD_GET(S2500_VS_MACID1_BYTE3_MASK, mac1);
+	addr[4] = FIELD_GET(S2500_VS_MACID0_BYTE4_MASK, mac0);
+	addr[5] = FIELD_GET(S2500_VS_MACID0_BYTE5_MASK, mac0);
+
+	__dev_addr_set(priv->ndev, addr, ETH_ALEN);
+	priv->ndev->addr_assign_type = NET_ADDR_PERM;
+	return ret;
+}
+
+/* Writes MAC address to macphy registers */
+static int s2500_set_mac_filter(struct net_device *ndev, const u8 *mac)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u16 mms = OA_TC6_PHY_C45_MAC_MMS1;
+	u32 val;
+	int ret;
+
+	/* Set unicast address filter */
+	ret = oa_tc6_write_register_mms(priv->tc6,
+					S2500_REG_MAC_ADDRMASKL(0),
+					mms, 0xffffffff);
+	if (ret)
+		return ret;
+
+	ret = oa_tc6_write_register_mms(priv->tc6,
+					S2500_REG_MAC_ADDRMASKH(0),
+					mms, 0xffff);
+	if (ret)
+		return ret;
+
+	val = get_unaligned_be32(&mac[2]);
+
+	ret = oa_tc6_write_register_mms(priv->tc6,
+					S2500_REG_MAC_ADDRFILTL(0),
+					mms, val);
+	if (ret)
+		return ret;
+
+	val = S2500_MAC_ADDRFILT_EN_BIT | get_unaligned_be16(mac);
+
+	return oa_tc6_write_register_mms(priv->tc6,
+					 S2500_REG_MAC_ADDRFILTH(0),
+					 mms, val);
+}
+
+static int s2500_mac_ctrl_modify_bits(struct s2500_info *priv,
+				      u32 in_bits, bool clr)
+{
+	u16 mms = OA_TC6_PHY_C45_MAC_MMS1;
+	u32 reg = S2500_REG_MAC_CTRL;
+	u32 rval = 0;
+	u32 wval = 0;
+	int ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, reg, mms, &rval);
+	if (ret)
+		return ret;
+
+	if (clr)
+		wval = rval & ~in_bits;
+	else
+		wval = rval | in_bits;
+	if (rval != wval)
+		ret = oa_tc6_write_register_mms(priv->tc6, reg,
+						mms, wval);
+	return ret;
+}
+
+static int s2500_init(struct s2500_info *priv)
+{
+	u32 val;
+	int ret;
+
+	/* Configure the SPI protocol + 64 bit timestamp */
+	val = S2500_SPI_CFG0_SYNC_BIT | S2500_SPI_CFG0_RXCTE_BIT |
+	      (S2500_TXCTHRESH_8 << S2500_SPI_CFG0_TXCTHRESH_SHIFT) |
+	      (S2500_CPS_64 << S2500_SPI_CFG0_CPS_SHIFT) |
+	      S2500_SPI_CFG0_FTSS_64_BIT;
+
+	ret = oa_tc6_write_register(priv->tc6, S2500_REG_SPI_CFG0, val);
+	if (ret)
+		return ret;
+
+	val = (u32)~(S2500_SPI_ST0_RESETC_BIT |
+		     S2500_SPI_ST0_HDRE_BIT | S2500_SPI_ST0_LOFE_BIT |
+		     S2500_SPI_ST0_RXBOE_BIT | S2500_SPI_ST0_TXBOE_BIT |
+		     S2500_SPI_ST0_TXPE_BIT);
+
+	ret = oa_tc6_write_register(priv->tc6, S2500_REG_SPI_IRQM0, val);
+	if (ret)
+		return ret;
+
+	/* Read the initial value of TX credits */
+	ret = oa_tc6_read_register(priv->tc6, S2500_REG_SPI_BUFST, &val);
+	if (ret)
+		return ret;
+
+	/* Program the source MAC address into the device */
+	ret = s2500_set_mac_filter(priv->ndev, priv->ndev->dev_addr);
+
+	val = S2500_MAC_CTRL_ADRF_BIT | S2500_MAC_CTRL_FCSA_BIT;
+
+	return s2500_mac_ctrl_modify_bits(priv, val, false);
+}
+
+static void s2500_shutdown(struct s2500_info *priv)
+{
+	u32 val = S2500_MAC_CTRL_TXEN_BIT | S2500_MAC_CTRL_RXEN_BIT;
+	struct net_device *ndev = priv->ndev;
+
+	netif_stop_queue(ndev);
+	phy_stop(ndev->phydev);
+
+	s2500_mac_ctrl_modify_bits(priv, val, true);
+}
+
+static int s2500_set_promiscuous_mode(struct s2500_info *priv,
+				      unsigned int rx_flags)
+{
+	u32 val = S2500_MAC_CTRL_ADRF_BIT;
+	bool clr = false;
+
+	if (rx_flags & IFF_PROMISC)
+		clr = true;
+	return s2500_mac_ctrl_modify_bits(priv, val, clr);
+}
+
+static int s2500_set_multicast_mode(struct s2500_info *priv,
+				    unsigned int rx_flags)
+{
+	u16 mms = OA_TC6_PHY_C45_MAC_MMS1;
+	int i, ret = 0;
+	u16 addr;
+	u32 val;
+
+	if ((rx_flags & IFF_ALLMULTI) ||
+	    (netdev_mc_count(priv->ndev) > S2500_N_MCAST_FILTERS)) {
+		/* Disable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF_BIT,
+						 true);
+		if (ret)
+			return ret;
+
+		/* Accept all multicasts */
+		addr = S2500_REG_MAC_ADDRMASKL(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, addr,
+						mms, 0);
+		if (ret)
+			return ret;
+
+		addr = S2500_REG_MAC_ADDRMASKH(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, addr,
+						mms, 0x100);
+		if (ret)
+			return ret;
+
+		addr = S2500_REG_MAC_ADDRFILTL(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, addr,
+						mms, 0);
+		if (ret)
+			return ret;
+
+		val = S2500_MAC_ADDRFILT_EN_BIT | 0x00000100;
+		addr = S2500_REG_MAC_ADDRFILTH(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, addr,
+						mms, val);
+	} else if (netdev_mc_count(priv->ndev) == 0) {
+		/* Enable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF_BIT,
+						 false);
+		if (ret)
+			return ret;
+
+		/* Disable filters */
+		for (i = 1; i <= S2500_N_MCAST_FILTERS; i++) {
+			addr = S2500_REG_MAC_ADDRFILTH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms, 0);
+			if (ret)
+				return ret;
+		}
+	} else {
+		struct netdev_hw_addr *ha;
+		u32 addrh, addrl;
+
+		/* Disable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF_BIT,
+						 true);
+		if (ret)
+			return ret;
+
+		/* Disable filters */
+		for (i = 1; i <= S2500_N_MCAST_FILTERS; i++) {
+			addr = S2500_REG_MAC_ADDRFILTH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms, 0);
+			if (ret)
+				return ret;
+		}
+
+		i = 1;
+		netdev_for_each_mc_addr(ha, priv->ndev) {
+			if (i > S2500_N_MCAST_FILTERS)
+				break;
+
+			addrh = S2500_MAC_ADDRFILT_EN_BIT |
+				 get_unaligned_be16(ha->addr);
+			addrl = get_unaligned_be32(&ha->addr[2]);
+
+			addr = S2500_REG_MAC_ADDRFILTH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms,
+							addrh);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRFILTL(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms,
+							addrl);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRMASKL(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms,
+							0xffffffff);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRMASKH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							addr, mms,
+							0xffff);
+			if (ret)
+				return ret;
+			i++;
+		}
+	}
+	return ret;
+}
+
+/* Deferred function for applying RX mode flags in non-atomic context */
+static int s2500_rx_mode_update(struct s2500_info *priv)
+{
+	unsigned int rx_flags;
+	unsigned long flags;
+	int ret;
+
+	spin_lock_irqsave(&priv->lock, flags);
+
+	rx_flags = priv->ndev_flags;
+	priv->rx_flags_upd = false;
+
+	spin_unlock_irqrestore(&priv->lock, flags);
+
+	ret = s2500_set_promiscuous_mode(priv, rx_flags);
+	if (ret)
+		goto out;
+
+	ret = s2500_set_multicast_mode(priv, rx_flags);
+out:
+	return ret;
+}
+
+static void s2500_set_rx_mode(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	unsigned long flags;
+
+	spin_lock_irqsave(&priv->lock, flags);
+
+	priv->rx_flags_upd = true;
+	priv->ndev_flags = ndev->flags;
+
+	spin_unlock_irqrestore(&priv->lock, flags);
+
+	if (priv->thread)
+		wake_up_process(priv->thread);
+}
+
+static int s2500_set_mac_address(struct net_device *ndev, void *p)
+{
+	struct sockaddr *addr = p;
+
+	if (!is_valid_ether_addr(addr->sa_data))
+		return -EADDRNOTAVAIL;
+
+	eth_hw_addr_set(ndev, addr->sa_data);
+	return s2500_set_mac_filter(ndev, addr->sa_data);
+}
+
+static netdev_tx_t s2500_start_xmit(struct sk_buff *skb,
+				    struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	return oa_tc6_start_xmit(priv->tc6, skb);
+}
+
+static int s2500_ioctl(struct net_device *ndev, struct ifreq *rq,
+		       int cmd)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	return oa_tc6_ioctl(priv->tc6, rq, cmd);
+}
+
+static void s2500_process_events(struct s2500_info *priv)
+{
+	u32 val;
+	int ret;
+
+	if (!priv->event_pending)
+		return;
+
+	priv->event_pending = false;
+
+	ret = oa_tc6_read_register(priv->tc6, S2500_REG_SPI_ST0, &val);
+	if (ret) {
+		dev_err(&priv->spi->dev, "Error reading ST0 register");
+		return;
+	}
+}
+
+static int s2500_thread_fun(void *data)
+{
+	struct s2500_info *priv = data;
+	bool update_rx_mode = false;
+	unsigned long flags;
+	signed long tout;
+	int ret = 0;
+
+	tout = priv->poll_jiff;
+
+	do {
+		if (update_rx_mode) {
+			ret = s2500_rx_mode_update(priv);
+			if (unlikely(ret)) {
+				dev_err(&priv->spi->dev,
+					"Failed to set new RX mode");
+				break;
+			}
+		}
+
+		if (tout == 0) {
+			tout = priv->poll_jiff;
+
+			/* Force checking the status register */
+			priv->event_pending = true;
+		}
+
+		s2500_process_events(priv);
+
+		spin_lock_irqsave(&priv->lock, flags);
+		__set_current_state(TASK_INTERRUPTIBLE);
+
+		update_rx_mode = priv->rx_flags_upd;
+		ret = update_rx_mode;
+
+		spin_unlock_irqrestore(&priv->lock, flags);
+
+		if (!ret)
+			tout = schedule_timeout(tout);
+		else
+			set_current_state(TASK_RUNNING);
+	} while (!kthread_should_stop());
+	return 0;
+}
+
+static int s2500_open(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	int ret = 0;
+	u32 val;
+
+	dev_dbg(&ndev->dev, "%s", "s2500_open");
+	phy_start(priv->ndev->phydev);
+
+	priv->thread = kthread_run(s2500_thread_fun, priv,
+				   DRV_NAME "/%s:%d",
+				   dev_name(&priv->spi->dev),
+				   spi_get_chipselect(priv->spi, 0));
+
+	if (IS_ERR(priv->thread)) {
+		ret = PTR_ERR(priv->thread);
+	} else {
+		val = S2500_MAC_CTRL_TXEN_BIT | S2500_MAC_CTRL_RXEN_BIT;
+		ret = s2500_mac_ctrl_modify_bits(priv, val, false);
+
+		netif_start_queue(priv->ndev);
+	}
+	return ret;
+}
+
+static int s2500_stop(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	dev_dbg(&ndev->dev, "%s", "s2500_stop");
+
+	s2500_shutdown(priv);
+
+	kthread_stop(priv->thread);
+	priv->thread = NULL;
+
+	return 0;
+}
+
+static int s2500_hwtstamp_get(struct net_device *ndev,
+			      struct kernel_hwtstamp_config *k_cfg)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	oa_tc6_hwtstamp_get(priv->tc6, k_cfg);
+	return 0;
+}
+
+static int s2500_hwtstamp_set(struct net_device *ndev,
+			      struct kernel_hwtstamp_config *cfg,
+			      struct netlink_ext_ack *extack)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	return oa_tc6_hwtstamp_set(priv->tc6, cfg);
+}
+
+static const struct net_device_ops s2500_netdev_ops = {
+	.ndo_open            = s2500_open,
+	.ndo_stop            = s2500_stop,
+	.ndo_start_xmit      = s2500_start_xmit,
+	.ndo_set_mac_address = s2500_set_mac_address,
+	.ndo_set_rx_mode     = s2500_set_rx_mode,
+	.ndo_eth_ioctl       = s2500_ioctl,
+	.ndo_hwtstamp_get    = s2500_hwtstamp_get,
+	.ndo_hwtstamp_set    = s2500_hwtstamp_set,
+};
+
+static int s2500_probe(struct spi_device *spi)
+{
+	struct device *dev = &spi->dev;
+	struct net_device *ndev;
+	struct s2500_info *priv;
+	u32 val;
+	int ret;
+
+	if (spi->irq < 0)
+		return -ENODEV;
+
+	ndev = devm_alloc_etherdev(dev, sizeof(struct s2500_info));
+	if (!ndev)
+		return -ENOMEM;
+
+	priv = netdev_priv(ndev);
+	priv->ndev = ndev;
+	priv->spi = spi;
+	priv->dev = dev;
+
+	SET_NETDEV_DEV(ndev, dev);
+
+	spin_lock_init(&priv->lock);
+	mutex_init(&priv->ptp_adj_lock);
+	ndev->irq = spi->irq;
+
+	spi->dev.platform_data = priv;
+	spi_set_drvdata(spi, priv);
+
+	ndev->netdev_ops = &s2500_netdev_ops;
+	ndev->ethtool_ops = &s2500_ethtool_ops;
+	ndev->if_port = IF_PORT_10BASET;
+	ndev->priv_flags |= IFF_UNICAST_FLT;
+	ndev->hw_features = NETIF_F_RXALL;
+
+	priv->poll_jiff = HZ * 5; /* Poll interval */
+
+	priv->tc6 = oa_tc6_init(spi, ndev);
+	if (!priv->tc6) {
+		dev_err(&spi->dev, "OA TC6 init failed");
+		return -ENODEV;
+	}
+	oa_tc6_set_vend1_mms(priv->tc6, OA_TC6_PHY_C45_VS_MMS12);
+
+	/* Clear RSTS, if set */
+	oa_tc6_read_register_mms(priv->tc6, S2500_REG_VS_MIIMIRQS,
+				 OA_TC6_PHY_C45_VS_MMS12, &val);
+	val &= MIIM_IRQ_STATUS_RSTS;
+	if (val != 0)
+		oa_tc6_write_register_mms(priv->tc6,
+					  S2500_REG_VS_MIIMIRQS,
+					  OA_TC6_PHY_C45_VS_MMS12,
+					  MIIM_IRQ_STATUS_RSTS);
+
+	/* Acknowledge all IRQ status bits */
+	ret = oa_tc6_read_register(priv->tc6, S2500_REG_SPI_ST0, &val);
+	if (!ret) {
+		u32 mask = S2500_STATUS0_MASK;
+
+		val &= mask;
+		oa_tc6_write_register(priv->tc6, S2500_REG_SPI_ST0, val);
+	}
+
+	ret = device_get_ethdev_address(priv->dev, ndev);
+	if (ret)
+		ret = s2500_read_mac_from_nvmem(priv);
+
+	if (ret) {
+		eth_hw_addr_random(ndev);
+		dev_warn(&spi->dev, "Using random MAC address %pM",
+			 ndev->dev_addr);
+	}
+
+	ret = s2500_init(priv);
+	if (unlikely(ret)) {
+		dev_err(&spi->dev, "failed to s2500_init the device");
+		goto err_reg_read;
+	}
+
+	/* Configure PTP if the model supports it */
+	ret = s2500_ptp_register(priv);
+	if (unlikely(ret))
+		goto err_reg_read;
+
+	ret = register_netdev(ndev);
+	if (ret) {
+		dev_err(&spi->dev, "failed to register netdev\n");
+		ret = -ENODEV;
+
+		goto err_reg_read;
+	}
+	return 0;
+
+err_reg_read:
+	dev_err(&spi->dev, "could not initialize macphy");
+	return ret;
+}
+
+static void s2500_remove(struct spi_device *spi)
+{
+	struct s2500_info *priv = spi->dev.platform_data;
+
+	dev_dbg(&priv->ndev->dev, "%s", "s2500_remove");
+
+	oa_tc6_ptp_unregister(priv->tc6);
+	unregister_netdev(priv->ndev);
+	oa_tc6_exit(priv->tc6);
+}
+
+static const struct of_device_id s2500_of_match[] = {
+	{ .compatible = "onnn,s2500" },
+	{}
+};
+
+static const struct spi_device_id s2500_ids[] = {
+	{ "s2500" },
+	{}
+};
+
+MODULE_DEVICE_TABLE(spi, s2500_ids);
+
+static struct spi_driver s2500_driver = {
+	.driver = {
+		.name	= DRV_NAME,
+		.of_match_table = s2500_of_match,
+	},
+	.probe		= s2500_probe,
+	.remove		= s2500_remove,
+	.id_table	= s2500_ids,
+};
+
+module_spi_driver(s2500_driver);
+
+MODULE_AUTHOR("Piergiorgio Beruto <pier.beruto@onsemi.com>");
+MODULE_AUTHOR("Selva Rajagopal <selvamani.rajagopal@onsemi.com>");
+MODULE_DESCRIPTION("onsemi MACPHY ethernet driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
new file mode 100644
index 000000000000..7da660cb5b19
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
@@ -0,0 +1,250 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#include "s2500_hw_def.h"
+
+static int s2500_ptp_get_time64(struct ptp_clock_info *ptp,
+				struct timespec64 *ts,
+				struct ptp_system_timestamp *ptp_sts)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	u32 data[2];
+	int ret;
+
+	ptp_read_system_prets(ptp_sts);
+	ret = oa_tc6_read_registers_mms(priv->tc6,
+					S2500_REG_VS_PTP_SEC,
+					OA_TC6_PHY_C45_VS_MMS12,
+					&data[0], 2);
+	ptp_read_system_postts(ptp_sts);
+
+	if (!ret) {
+		ts->tv_sec = data[0];
+		ts->tv_nsec = data[1];
+	}
+
+	return ret;
+}
+
+static int s2500_ptp_set_time64(struct ptp_clock_info *ptp,
+				const struct timespec64 *ts)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	u32 data[2];
+
+	if (ts->tv_sec >= (1ULL << 32))
+		return -ERANGE;
+
+	data[0] = (u32)ts->tv_sec;
+	/* bit 31 = execute set command */
+	data[1] = ts->tv_nsec | BIT(31);
+
+	return oa_tc6_write_registers_mms(priv->tc6,
+					  S2500_REG_VS_PTP_SETSEC,
+					  OA_TC6_PHY_C45_VS_MMS12,
+					  &data[0], 2);
+}
+
+static int s2500_ptp_adjfine(struct ptp_clock_info *ptp, long scaled_ppm)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	u32 sign_bit = 0;
+	long adj;
+	u32 val;
+	u64 ppm;
+
+	if (scaled_ppm < 0) {
+		/* split sign / mod */
+		sign_bit = 1U << 31;
+		scaled_ppm = ~scaled_ppm + 1;
+	}
+
+	/*
+	 * Convert unsigned scaled_ppm to atto-seconds per clock cycles.
+	 * The scaled_ppm format is Qx.16 --> 1 lsb = 1/65536 ppm.
+	 * The clock period of the S2500 is 8ns (125 MHz), so 1 lsb of
+	 * adj register LSB is 1 atto-sec / 8ns = 0.000125 ppm.
+	 * Represented in Qx.16 format, this is 0.000125 * 2^16 = 8(.192)
+	 * To convert scaled_ppm into a register value we need to divide
+	 * it by the LSB value, hence adj = (scaled_ppm * 1000) / 8192 to
+	 * minimize the precision loss due to the integer arithmetic.
+	 * That further reduces to (scaled_ppm * 125) / 1024.
+	 */
+	ppm = (u64)scaled_ppm * 125;
+	do_div(ppm, 1024);
+	adj = (long)ppm;
+
+	/* check overflow */
+	if (adj >= (1L << 28))
+		return -ERANGE;
+
+	val = (u32)adj | sign_bit;
+	return oa_tc6_write_register_mms(priv->tc6, S2500_REG_VS_PTP_ADJ,
+					 OA_TC6_PHY_C45_VS_MMS12, val);
+}
+
+static int s2500_use_settime(struct ptp_clock_info *ptp,
+			     struct timespec64 now, s64 rem)
+{
+	struct ptp_system_timestamp sts;
+	struct timespec64 delta_ts;
+	struct timespec64 target;
+	int ret;
+
+	memset(&sts, 0, sizeof(sts));
+	ret = ptp->gettimex64(ptp, &now, &sts);
+	if (ret)
+		return ret;
+	if (rem >= 0) {
+		delta_ts = ns_to_timespec64(rem);
+		target = timespec64_add(now, delta_ts);
+	} else {
+		delta_ts = ns_to_timespec64(-rem);
+		target = timespec64_sub(now, delta_ts);
+	}
+	if (target.tv_sec < 0 ||
+	    target.tv_sec >= (1ULL << 32))
+		return -ERANGE;
+	return ptp->settime64(ptp, &target);
+}
+
+static int s2500_ptp_adjtime(struct ptp_clock_info *ptp, s64 delta)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	struct ptp_system_timestamp sts;
+	struct timespec64 target;
+	unsigned int period_ms;
+	struct timespec64 now;
+	s64 scaled_ppm, rem;
+	int max_iters = 3;
+	s64 target_ns;
+	int ret = 0;
+	s64 now_ns;
+	s64 num;
+	s64 den;
+
+	if (!ptp)
+		return -EINVAL;
+
+	/* Nothing to do */
+	if (delta == 0)
+		return 0;
+
+	if (mutex_lock_interruptible(&priv->ptp_adj_lock))
+		return -EINTR;
+
+	/* Try to slew the clock using adjfine for better accuracy.
+	 * For large adjustments fall back to setting time directly.
+	 */
+	rem = delta;
+
+	while (rem != 0 && max_iters--) {
+		s64 abs_delta = rem > 0 ? rem : -rem;
+
+		/* If the adjustment is very large, more than 1 second,
+		 * use settime to avoid very long slewing periods or
+		 * excessive frequency offsets.
+		 */
+		if (abs_delta > 1000000000LL) {
+			ret = s2500_use_settime(ptp, now, rem);
+			rem = 0;
+			break;
+		}
+
+		/* Choose a slewing period depending on magnitude */
+		if (abs_delta <= 1000000LL) /* <= 1ms */
+			period_ms = 1000; /* 1 s */
+		else if (abs_delta <= 100000000LL) /* <= 100ms */
+			period_ms = 10000; /* 10 s */
+		else
+			period_ms = 60000; /* 60 s */
+
+		/* Compute current time and fixed target for this
+		 * iteration
+		 */
+		memset(&sts, 0, sizeof(sts));
+		ret = ptp->gettimex64(ptp, &now, &sts);
+		if (ret)
+			break;
+
+		if (rem >= 0)
+			target = timespec64_add(now,
+						ns_to_timespec64(rem));
+		else
+			target = timespec64_sub(now,
+						ns_to_timespec64(-rem));
+
+		/* Compute scaled_ppm (Qx.16). scaled_ppm = ppm * 2^16
+		 * ppm = (delta_seconds / period_seconds) * 1e6
+		 * => scaled_ppm = delta_ns * 65536 / (period_ms * 1000)
+		 */
+		num = rem * 65536LL;
+		den = (s64)period_ms * 1000LL;
+
+		/* Integer division rounds toward zero; keep sign in
+		 * numerator
+		 */
+		scaled_ppm = div_s64(num, den);
+
+		/* Apply frequency adjustment */
+		ret = ptp->adjfine(ptp, (long)scaled_ppm);
+		if (ret)
+			break;
+
+		/* Sleep for the slew period (interruptible). If
+		 * interrupted, clear the adjfine and return -EINTR.
+		 */
+		if (msleep_interruptible(period_ms)) {
+			/* Clear adjfine */
+			ptp->adjfine(ptp, 0);
+			ret = -EINTR;
+			break;
+		}
+
+		/* Clear adjfine and measure remaining offset */
+		ptp->adjfine(ptp, 0);
+
+		memset(&sts, 0, sizeof(sts));
+		ret = ptp->gettimex64(ptp, &now, &sts);
+		if (ret)
+			break;
+
+		/* remaining = target - now (in ns) */
+		target_ns = timespec64_to_ns(&target);
+		now_ns = timespec64_to_ns(&now);
+		rem = target_ns - now_ns;
+
+		/* If remaining is small (< 1us), finish */
+		if (rem > -1000 && rem < 1000)
+			rem = 0;
+	}
+
+	mutex_unlock(&priv->ptp_adj_lock);
+	return ret;
+}
+
+int s2500_ptp_register(struct s2500_info *priv)
+{
+	struct ptp_clock_info *info = &priv->ptp_clock_info;
+	int ret;
+
+	info->max_adj = 100000000;
+	info->owner = THIS_MODULE;
+	info->adjfine = s2500_ptp_adjfine;
+	info->gettimex64 = s2500_ptp_get_time64;
+	info->settime64 = s2500_ptp_set_time64;
+	info->adjtime = s2500_ptp_adjtime;
+
+	ret = oa_tc6_ptp_register(priv->tc6, info);
+	if (ret)
+		dev_err(&priv->spi->dev, "PTP registration failed");
+	return ret;
+}
+

-- 
2.43.0

