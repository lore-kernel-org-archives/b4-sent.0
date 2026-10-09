From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 09 Oct 2026 10:12:28 -0700
Subject: [PATCH net-next v9 08/11] onsemi: s2500: Add driver support for
 S2500 MAC-PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-s2500-mac-phy-support-v9-8-dcefe1d0bf0d@onsemi.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791565943; l=44031;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=lEquduQBY9nSxJ0L2I9KrA+ZF8A5Ws3oe7NkJZj2HXY=;
 b=Bpi8ESV1FDoqwqXMLTgsBh1M9yVdBfwGIjSNFDYPRiKhlczbuYAybpLFDSFfG59ILsVyJz3uY
 aTFZZyiLFvgD7RbDaK4Gvxp0QznOEs31YnTft6SPt8C/w2s1Zi2Qwqh
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for onsemi's S2500, 802.3 cg compliant Ethernet
transceiver with integrated MAC-PHY. Works with
Open Alliance TC6 framework.

Hardware timestamp support is present in the driver.
adjtime callback is implemented using settime callback.

Driver has ethtool support for printing some device
registers, MAC stats, rmon stats and timestamp related
traffic counters.

Driver supports maximum three multicast filters. If
system has more than 3 multicast addresses to support,
all multicast traffic is allowed.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v9
  - moved net_selftest entry in ethtool_ops to the correct patch
  - Moved MAINTAINERS changes here for driver files.
  - Fix the order of variable declaration to keep reverse christmas
    tree format.
changes in v8
  - changes to use the new MMS read/write API in oa tc6 framework
  - Updated to improve adjtime/adjfine implementation
  - cleanup to remove unncessary definitions/initializations
  - Removed unnecessary ioctl callback
changes in v7
  - Moved the update to MAINTAINERS to the patch that has DTS
    as it comes first.
  - Added space between {}. Added missing MODULE_DEVICE_TABLE
  - Removed the duplicate vendor dependency check in Kconfig
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
 MAINTAINERS                                       |   1 +
 drivers/net/ethernet/Kconfig                      |   1 +
 drivers/net/ethernet/Makefile                     |   1 +
 drivers/net/ethernet/onsemi/Kconfig               |  22 +
 drivers/net/ethernet/onsemi/Makefile              |   7 +
 drivers/net/ethernet/onsemi/s2500/Kconfig         |  21 +
 drivers/net/ethernet/onsemi/s2500/Makefile        |   7 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c | 376 ++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h  | 160 +++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c    | 523 ++++++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c     | 174 +++++++
 include/linux/oa_tc6.h                            |   1 +
 12 files changed, 1294 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 1d1e0563b922..4e122a5eefa1 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -20445,6 +20445,7 @@ M:	Selva Rajagopal <selvamani.rajagopal@onsemi.com>
 L:	netdev@vger.kernel.org
 S:	Supported
 F:	Documentation/devicetree/bindings/net/onnn,s2500.yaml
+F:	drivers/net/ethernet/onsemi/s2500/*
 
 OP-TEE DRIVER
 M:	Jens Wiklander <jenswi@kernel.org>
diff --git a/drivers/net/ethernet/Kconfig b/drivers/net/ethernet/Kconfig
index 5758e0fbbca5..c160bf991345 100644
--- a/drivers/net/ethernet/Kconfig
+++ b/drivers/net/ethernet/Kconfig
@@ -137,6 +137,7 @@ source "drivers/net/ethernet/nvidia/Kconfig"
 source "drivers/net/ethernet/nxp/Kconfig"
 source "drivers/net/ethernet/oa_tc6/Kconfig"
 source "drivers/net/ethernet/oki-semi/Kconfig"
+source "drivers/net/ethernet/onsemi/Kconfig"
 
 config ETHOC
 	tristate "OpenCores 10/100 Mbps Ethernet MAC support"
diff --git a/drivers/net/ethernet/Makefile b/drivers/net/ethernet/Makefile
index e0e86c249e42..e4bad64bf95c 100644
--- a/drivers/net/ethernet/Makefile
+++ b/drivers/net/ethernet/Makefile
@@ -74,6 +74,7 @@ obj-$(CONFIG_NET_VENDOR_NVIDIA) += nvidia/
 obj-$(CONFIG_LPC_ENET) += nxp/
 obj-$(CONFIG_OA_TC6) += oa_tc6/
 obj-$(CONFIG_NET_VENDOR_OKI) += oki-semi/
+obj-$(CONFIG_NET_VENDOR_ONSEMI) += onsemi/
 obj-$(CONFIG_ETHOC) += ethoc.o
 obj-$(CONFIG_NET_VENDOR_PASEMI) += pasemi/
 obj-$(CONFIG_NET_VENDOR_QLOGIC) += qlogic/
diff --git a/drivers/net/ethernet/onsemi/Kconfig b/drivers/net/ethernet/onsemi/Kconfig
new file mode 100644
index 000000000000..484de609462a
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/Kconfig
@@ -0,0 +1,22 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# onsemi network device configuration
+#
+
+config NET_VENDOR_ONSEMI
+	bool "onsemi network devices"
+	default y
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
index 000000000000..abd967448af0
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/Kconfig
@@ -0,0 +1,21 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# onsemi S2500 Driver Support
+#
+
+config S2500_MACPHY
+	tristate "S2500 support"
+	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
+	imply NET_SELFTESTS
+	select BITREVERSE
+	select NCN26000_PHY
+	select OA_TC6
+	help
+	  Support for the onsemi S2500 MACPHY Ethernet chip.
+	  It works under the framework that conform to OPEN Alliance
+	  10BASE-T1x Serial Interface specification.
+
+	  To compile this driver as a module, choose M here. The module will be
+	  called s2500.
+
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
index 000000000000..062cab9460dc
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
@@ -0,0 +1,376 @@
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
+#define S2500_NUM_MAC_STATS		1
+#define S2500_NUM_RMON_STATS		12
+
+struct s2500_reg_map {
+	u16 reg;
+	u8 mms;
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
+	"rx_mismatch_drops",
+};
+
+static const u8 s2500_mac_stat_map[S2500_NUM_MAC_STATS] = {
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
+	u32 *regs, *rptr, addr;
+	int ret;
+
+	if (time_is_after_jiffies(priv->stats_read_at +
+				  S2500_STATS_CACHE_PERIOD))
+		return;
+
+	regs = kmalloc_array(S2500_NUM_STAT_REGS, sizeof(u32), GFP_KERNEL);
+	if (!regs)
+		return;
+
+	addr = FIELD_PREP(S2500_REG_MMS_MASK, OA_TC6_MAC_MMS1) |
+			  S2500_REG_MAC_STOCTECTSTXL;
+	ret = oa_tc6_read_registers(priv->tc6, addr, regs,
+				    S2500_NUM_STAT_REGS);
+	if (ret)
+		goto out;
+
+	priv->stats_read_at = jiffies;
+	rptr = regs;
+
+	/* TX bytes is a 64-bit value that is stored in two regs.
+	 * When lower 32 bits are read from OCTETS-L register,
+	 * upper bits are sampled and stored in OCTETS-H register.
+	 * Request to read multiple registers reads OCTETS-L first.
+	 * This way, counter value is read in an atomic manner.
+	 */
+	*(data++) += ((u64)*rptr) | (((u64)*(rptr + 1)) << 32);
+
+	/* Rest are 32-bit values until RX bytes register. */
+	for (rptr += 2; (rptr - regs) < STAT_REG_OFFSET(OCTECTSRXL); ++rptr)
+		*(data++) += *rptr;
+
+	/* RX bytes is a 64-bit value that is stored in two regs.
+	 * Like TX bytes counter, value is read atomically from
+	 * registers.
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
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	strscpy(info->driver, DRV_NAME, sizeof(info->driver));
+	strscpy(info->bus_info, dev_name(&priv->spi->dev),
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
+static void s2500_get_eth_mac_stats(struct net_device *ndev,
+				    struct ethtool_eth_mac_stats *mac_stats)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	const u64 *st;
+
+	if (mac_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv);
+	st = priv->stats_data;
+
+	mac_stats->OctetsTransmittedOK = st[S2500_MSTOCTECTSTX_IDX];
+	mac_stats->FramesTransmittedOK = st[S2500_MSTFRAMESTXOK_IDX];
+	mac_stats->BroadcastFramesXmittedOK = st[S2500_MSTBCASTTXOK_IDX];
+	mac_stats->MulticastFramesXmittedOK = st[S2500_MSTMCASTTXOK_IDX];
+	mac_stats->SingleCollisionFrames = st[S2500_MSTSINGLECOL_IDX];
+	mac_stats->MultipleCollisionFrames = st[S2500_MSTMULTICOL_IDX];
+	mac_stats->FramesAbortedDueToXSColls = st[S2500_MSTEXCESSCOL_IDX];
+	mac_stats->FramesWithDeferredXmissions = st[S2500_MSTDEFERREDTX_IDX];
+	mac_stats->CarrierSenseErrors = st[S2500_MSTCRSERR_IDX];
+	mac_stats->FramesLostDueToIntMACXmitError =
+		st[S2500_MSTTXUNDEFLOW_IDX];
+	mac_stats->OctetsReceivedOK = st[S2500_MSTOCTECTSRX_IDX];
+	mac_stats->FramesReceivedOK = st[S2500_MSTFRAMESRXOK_IDX];
+	mac_stats->BroadcastFramesReceivedOK = st[S2500_MSTBCASTRXOK_IDX];
+	mac_stats->MulticastFramesReceivedOK = st[S2500_MSTMCASTRXOK_IDX];
+	mac_stats->FrameTooLongErrors = st[S2500_MSTRXTOOLONG_IDX];
+	mac_stats->FrameCheckSequenceErrors = st[S2500_MSTFCSERRS_IDX];
+	mac_stats->AlignmentErrors = st[S2500_MSTALIGNERRS_IDX];
+	mac_stats->FramesLostDueToIntMACRcvError =
+		st[S2500_MSTRXOVERFLOW_IDX];
+}
+
+static void s2500_get_eth_phy_stats(struct net_device *ndev,
+				    struct ethtool_eth_phy_stats *phy_stats)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	if (phy_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv);
+	phy_stats->SymbolErrorDuringCarrier =
+		priv->stats_data[S2500_MSTSYMBOLERRS_IDX];
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
+	if (rmon_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv);
+
+	rmon_stats->undersize_pkts = priv->stats_data[S2500_MSTRUNTSERR_IDX];
+	rmon_stats->oversize_pkts = priv->stats_data[S2500_MSTRXTOOLONG_IDX];
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
+	__be32 *pbuff = p;
+	int ret = 0;
+	u32 val;
+	u16 reg;
+	u8 mms;
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
+		ret = oa_tc6_read_register_mms(priv->tc6, mms, reg,
+					       &val);
+
+		/* Write a pattern to indicate failure */
+		if (ret)
+			val = 0xDEADC0DE;
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
+	.get_drvinfo = s2500_get_drvinfo,
+	.get_link = ethtool_op_get_link,
+	.get_link_ksettings = phy_ethtool_get_link_ksettings,
+	.set_link_ksettings = phy_ethtool_set_link_ksettings,
+	.get_ts_stats = s2500_get_ts_stats,
+	.get_sset_count = s2500_get_sset_count,
+	.get_strings = s2500_get_strings,
+	.get_ethtool_stats = s2500_get_ethtool_stats,
+	.get_eth_mac_stats = s2500_get_eth_mac_stats,
+	.get_eth_phy_stats = s2500_get_eth_phy_stats,
+	.get_rmon_stats = s2500_rmon_stats,
+	.get_ts_info = s2500_get_ts_info,
+	.get_regs_len = s2500_get_regs_len,
+	.get_regs = s2500_get_regs,
+};
+
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
new file mode 100644
index 000000000000..0d0b335a397a
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
@@ -0,0 +1,160 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#ifndef S2500_HW_DEF_H
+#define S2500_HW_DEF_H
+
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/spi/spi.h>
+#include <linux/phylink.h>
+#include <linux/net_tstamp.h>
+#include <linux/ptp_clock_kernel.h>
+#include <linux/delay.h>
+#include <linux/mutex.h>
+#include <linux/ktime.h>
+#include <linux/errno.h>
+#include <linux/oa_tc6.h>
+
+#define DRV_NAME			"s2500"
+
+#define S2500_N_MCAST_FILTERS		3
+
+#define S2500_REG_MMS_MASK		GENMASK(19, 16)
+
+/* SPI OID and model register */
+#define S2500_REG_PHYID			0x1
+
+#define S2500_PHYID_OUI_SHIFT		10
+#define S2500_PHYID_OUI_MASK		GENMASK(31, S2500_PHYID_OUI_SHIFT)
+#define S2500_PHYID_OUI_MASK0		GENMASK(21, 16)
+#define S2500_PHYID_OUI_MASK1		GENMASK(15, 8)
+#define S2500_PHYID_OUI_MASK2		GENMASK(7, 0)
+
+#define S2500_CONFIG0_TXCTHRESH_SHIFT	10
+#define S2500_CONFIG0_RXCTE		BIT(8)
+#define S2500_CONFIG0_CPS_SHIFT		0
+#define S2500_CONFIG0_TXCTHRESH_8	0x2
+#define S2500_CONFIG0_CPS_64		0x6
+
+/* Read only bit in STATUS0 register */
+#define S2500_STATUS0_PHY_INT		BIT(7)
+
+#define S2500_REG_MAC_CTRL		0x0
+
+#define S2500_MAC_CTRL_MCSF		BIT(18)
+#define S2500_MAC_CTRL_ADRF		BIT(16)
+#define S2500_MAC_CTRL_FCSA		BIT(8)
+#define S2500_MAC_CTRL_TXEN		BIT(1)
+#define S2500_MAC_CTRL_RXEN		BIT(0)
+
+/* MAC address filter registers */
+#define S2500_REG_MAC_ADDRFILTL(n)	(16 + 2 * (n))
+#define S2500_REG_MAC_ADDRFILTH(n)	(17 + 2 * (n))
+#define S2500_REG_MAC_ADDRMASKL(n)	(32 + 2 * (n))
+#define S2500_REG_MAC_ADDRMASKH(n)	(33 + 2 * (n))
+
+#define S2500_MAC_ADDRFILT_ENABLE	BIT(31)
+
+/* MAC statistic registers */
+#define S2500_REG_MAC_STOCTECTSTXL	48
+#define S2500_REG_MAC_STOCTECTSTXH	49
+#define S2500_REG_MAC_STOCTECTSRXL	65
+#define S2500_REG_MAC_STOCTECTSRXH	66
+#define S2500_REG_MAC_STRXDROPPED	82
+
+/* First/last statistic register for sequential access */
+#define S2500_REG_MAC_FIRST_STAT	S2500_REG_MAC_STOCTECTSTXL
+#define S2500_REG_MAC_LAST_STAT		S2500_REG_MAC_STRXDROPPED
+
+#define S2500_NUM_STAT_REGS \
+	(S2500_REG_MAC_LAST_STAT - S2500_REG_MAC_FIRST_STAT + 1)
+#define S2500_NUM_STAT_VARS		(S2500_NUM_STAT_REGS - 2)
+#define S2500_STATS_CACHE_PERIOD	msecs_to_jiffies(100)
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
+
+/* Frequency adjust magnitude, 1 LSB = 0.000125 ppm = 1/8 ppb */
+#define S2500_PTP_ADJ_MAX		GENMASK(27, 0)
+#define S2500_PTP_MAX_ADJ_PPB		(S2500_PTP_ADJ_MAX / 8)
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
+struct s2500_info {
+	struct device *dev;
+	struct net_device *ndev;
+
+	/* To have atomic operation for PTP time registers */
+	struct mutex ptp_adj_lock;
+
+	struct spi_device *spi;
+
+	/* statistic counters variables */
+	u64 stats_data[S2500_NUM_STAT_VARS];
+	unsigned long stats_read_at;
+
+	/* PTP related variables */
+	struct ptp_clock_info ptp_clock_info;
+	struct oa_tc6 *tc6;
+};
+
+int s2500_ptp_register(struct s2500_info *priv);
+
+#endif /* S2500_HW_DEF_H */
+
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_main.c b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
new file mode 100644
index 000000000000..4cd0f5d10666
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
@@ -0,0 +1,523 @@
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
+/* Initializes the net device MAC address by reading the UID stored
+ * into the device internal non-volatile memory.
+ */
+static int s2500_read_mac_from_nvmem(struct s2500_info *priv)
+{
+	u8 mms = OA_TC6_PHY_C45_VS_MMS12;
+	u8 addr[ETH_ALEN];
+	u32 mac1 = 0;
+	u32 mac0 = 0;
+	u32 val;
+	int ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, mms,
+				       S2500_REG_VS_MACID1, &mac1);
+	if (ret)
+		return ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, mms,
+				       S2500_REG_VS_MACID0, &mac0);
+	if (ret)
+		return ret;
+
+	/* Pre-production parts may have 0 */
+	if (mac0 == 0 && mac1 == 0)
+		return -ENXIO;
+
+	ret = oa_tc6_read_register(priv->tc6, S2500_REG_PHYID, &val);
+	if (ret)
+		return ret;
+
+	val = (val & S2500_PHYID_OUI_MASK) >> S2500_PHYID_OUI_SHIFT;
+
+	/* Mapping for bits from PHY ID register to OUI as give below.
+	 * - PHY-ID[10:17] provides OUI[16:23]
+	 * - PHY-ID[18:25] provides OUI[8:15]
+	 * - PHY-ID[26:31] provides OUI[2:7]
+	 *
+	 * Hardware presents OUI such a way that this requires not just
+	 * byte level swap, bit level swap is needed as well.
+	 */
+	addr[0] = bitrev8(FIELD_GET(S2500_PHYID_OUI_MASK0, val));
+	addr[1] = bitrev8(FIELD_GET(S2500_PHYID_OUI_MASK1, val));
+	addr[2] = bitrev8(FIELD_GET(S2500_PHYID_OUI_MASK2, val));
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
+	u8 mms = OA_TC6_MAC_MMS1;
+	u32 val;
+	int ret;
+
+	/* Set unicast address filter */
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRMASKL(0),
+					0xffffffff);
+	if (ret)
+		return ret;
+
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRMASKH(0),
+					0xffff);
+	if (ret)
+		return ret;
+
+	val = get_unaligned_be32(&mac[2]);
+
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRFILTL(0),
+					val);
+	if (ret)
+		return ret;
+
+	val = S2500_MAC_ADDRFILT_ENABLE | get_unaligned_be16(mac);
+
+	return oa_tc6_write_register_mms(priv->tc6, mms,
+					 S2500_REG_MAC_ADDRFILTH(0),
+					 val);
+}
+
+static int s2500_mac_ctrl_modify_bits(struct s2500_info *priv,
+				      u32 in_bits, bool clr)
+{
+	u32 reg = S2500_REG_MAC_CTRL;
+	u8 mms = OA_TC6_MAC_MMS1;
+	u32 rval = 0;
+	u32 wval = 0;
+	int ret;
+
+	ret = oa_tc6_read_register_mms(priv->tc6, mms, reg, &rval);
+	if (ret)
+		return ret;
+
+	if (clr)
+		wval = rval & ~in_bits;
+	else
+		wval = rval | in_bits;
+	if (rval != wval)
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						reg, wval);
+	return ret;
+}
+
+static int s2500_init(struct s2500_info *priv)
+{
+	u32 val;
+	int ret;
+
+	/* Configure MAC-PHY's behavior */
+	val = OA_TC6_CONFIG0_SYNC | S2500_CONFIG0_RXCTE |
+	      (S2500_CONFIG0_TXCTHRESH_8 <<
+	      S2500_CONFIG0_TXCTHRESH_SHIFT) |
+	      (S2500_CONFIG0_CPS_64 << S2500_CONFIG0_CPS_SHIFT) |
+	      OA_TC6_CONFIG0_FTSS_64BIT_TSTAMP;
+
+	ret = oa_tc6_write_register(priv->tc6, OA_TC6_REG_CONFIG0,
+				    val);
+	if (ret)
+		return ret;
+
+	/* Program the source MAC address into the device */
+	ret = s2500_set_mac_filter(priv->ndev, priv->ndev->dev_addr);
+	if (ret)
+		return ret;
+
+	val = S2500_MAC_CTRL_ADRF | S2500_MAC_CTRL_FCSA;
+
+	return s2500_mac_ctrl_modify_bits(priv, val, false);
+}
+
+static void s2500_shutdown(struct s2500_info *priv)
+{
+	u32 val = S2500_MAC_CTRL_TXEN | S2500_MAC_CTRL_RXEN;
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
+	u32 val = S2500_MAC_CTRL_ADRF;
+	bool clr = false;
+
+	if (rx_flags & IFF_PROMISC)
+		clr = true;
+	return s2500_mac_ctrl_modify_bits(priv, val, clr);
+}
+
+static int s2500_set_multicast_mode(struct s2500_info *priv,
+				    unsigned int rx_flags,
+				    struct netdev_hw_addr_list *mc)
+{
+	struct netdev_hw_addr *ha;
+	u8 mms = OA_TC6_MAC_MMS1;
+	int i, ret = 0;
+	int mc_count;
+	u16 addr;
+	u32 val;
+
+	mc_count = netdev_hw_addr_list_count(mc);
+
+	if ((rx_flags & IFF_ALLMULTI) ||
+	    mc_count > S2500_N_MCAST_FILTERS) {
+		/* Disable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF,
+						 true);
+		if (ret)
+			return ret;
+
+		/* Accept all multicasts */
+		addr = S2500_REG_MAC_ADDRMASKL(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						addr, 0);
+		if (ret)
+			return ret;
+
+		addr = S2500_REG_MAC_ADDRMASKH(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						addr, 0x100);
+		if (ret)
+			return ret;
+
+		addr = S2500_REG_MAC_ADDRFILTL(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						addr, 0);
+		if (ret)
+			return ret;
+
+		val = S2500_MAC_ADDRFILT_ENABLE | 0x00000100;
+		addr = S2500_REG_MAC_ADDRFILTH(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						addr, val);
+	} else if (mc_count == 0) {
+		/* Enable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF,
+						 false);
+		if (ret)
+			return ret;
+
+		/* Disable filters */
+		for (i = 1; i <= S2500_N_MCAST_FILTERS; i++) {
+			addr = S2500_REG_MAC_ADDRFILTH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr, 0);
+			if (ret)
+				return ret;
+		}
+	} else {
+		u32 addrh, addrl;
+
+		/* Disable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF,
+						 true);
+		if (ret)
+			return ret;
+
+		/* Disable filters */
+		for (i = 1; i <= S2500_N_MCAST_FILTERS; i++) {
+			addr = S2500_REG_MAC_ADDRFILTH(i);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr, 0);
+			if (ret)
+				return ret;
+		}
+
+		/* Slot 0 holds the unicast MAC, multicast starts at 1 */
+		i = 1;
+		netdev_hw_addr_list_for_each(ha, mc) {
+			const u8 *mac = ha->addr;
+			int slot = i++;
+
+			addrh = S2500_MAC_ADDRFILT_ENABLE |
+				get_unaligned_be16(mac);
+			addrl = get_unaligned_be32(&mac[2]);
+
+			addr = S2500_REG_MAC_ADDRFILTH(slot);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr,
+							addrh);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRFILTL(slot);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr,
+							addrl);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRMASKL(slot);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr,
+							0xffffffff);
+			if (ret)
+				return ret;
+
+			addr = S2500_REG_MAC_ADDRMASKH(slot);
+			ret = oa_tc6_write_register_mms(priv->tc6,
+							mms, addr,
+							0xffff);
+			if (ret)
+				return ret;
+		}
+	}
+	return ret;
+}
+
+static int s2500_set_rx_mode(struct net_device *ndev,
+			     struct netdev_hw_addr_list *uc,
+			     struct netdev_hw_addr_list *mc)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	int ret;
+
+	ret = s2500_set_promiscuous_mode(priv, ndev->flags);
+	if (ret)
+		return ret;
+
+	return s2500_set_multicast_mode(priv, ndev->flags, mc);
+}
+
+static int s2500_set_mac_address(struct net_device *ndev, void *p)
+{
+	struct sockaddr *addr = p;
+	int ret;
+
+	if (!is_valid_ether_addr(addr->sa_data))
+		return -EADDRNOTAVAIL;
+
+	ret = s2500_set_mac_filter(ndev, addr->sa_data);
+	if (ret)
+		return ret;
+
+	eth_hw_addr_set(ndev, addr->sa_data);
+	return ret;
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
+static int s2500_open(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u32 val;
+	int ret;
+
+	dev_dbg(&ndev->dev, "%s", "s2500_open\n");
+	phy_start(priv->ndev->phydev);
+
+	val = S2500_MAC_CTRL_TXEN | S2500_MAC_CTRL_RXEN;
+	ret = s2500_mac_ctrl_modify_bits(priv, val, false);
+	if (!ret)
+		netif_start_queue(priv->ndev);
+	else
+		phy_stop(priv->ndev->phydev);
+	return ret;
+}
+
+static int s2500_stop(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	dev_dbg(&ndev->dev, "%s", "s2500_stop\n");
+
+	s2500_shutdown(priv);
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
+	.ndo_open              = s2500_open,
+	.ndo_stop              = s2500_stop,
+	.ndo_start_xmit        = s2500_start_xmit,
+	.ndo_set_mac_address   = s2500_set_mac_address,
+	.ndo_set_rx_mode_async = s2500_set_rx_mode,
+	.ndo_eth_ioctl         = phy_do_ioctl_running,
+	.ndo_hwtstamp_get      = s2500_hwtstamp_get,
+	.ndo_hwtstamp_set      = s2500_hwtstamp_set,
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
+	mutex_init(&priv->ptp_adj_lock);
+	ndev->irq = spi->irq;
+
+	/* Ensures that the first read is not from the cache. */
+	priv->stats_read_at = jiffies - S2500_STATS_CACHE_PERIOD;
+
+	spi_set_drvdata(spi, priv);
+
+	ndev->netdev_ops = &s2500_netdev_ops;
+	ndev->ethtool_ops = &s2500_ethtool_ops;
+	ndev->if_port = IF_PORT_10BASET;
+
+	priv->tc6 = oa_tc6_init(spi, ndev, NULL);
+	if (IS_ERR(priv->tc6)) {
+		ret = PTR_ERR(priv->tc6);
+		dev_err(&spi->dev, "OA TC6 init failed\n");
+		return ret;
+	}
+	oa_tc6_set_vend1_mms(priv->tc6, OA_TC6_PHY_C45_VS_MMS12);
+
+	/* All read-only bits. Some are self clear. No need to write */
+	ret = oa_tc6_read_register_mms(priv->tc6, OA_TC6_PHY_C45_VS_MMS12,
+				       S2500_REG_VS_MIIMIRQS, &val);
+	if (ret) {
+		dev_err(&spi->dev, "Failed to read MIIM IRQ status\n");
+		goto err_reg_read;
+	}
+
+	/* Acknowledge all IRQ status bits */
+	ret = oa_tc6_read_register(priv->tc6,
+				   OA_TC6_REG_STATUS0, &val);
+	if (!ret) {
+		/* Clear read only bit */
+		val &= ~S2500_STATUS0_PHY_INT;
+		oa_tc6_write_register(priv->tc6,
+				      OA_TC6_REG_STATUS0, val);
+	}
+
+	ret = device_get_ethdev_address(priv->dev, ndev);
+	if (ret)
+		ret = s2500_read_mac_from_nvmem(priv);
+
+	if (ret) {
+		eth_hw_addr_random(ndev);
+		dev_warn(&spi->dev, "Using random MAC address %pM\n",
+			 ndev->dev_addr);
+	}
+
+	ret = s2500_init(priv);
+	if (ret) {
+		dev_err(&spi->dev, "Failure seen in s2500_init\n");
+		goto err_reg_read;
+	}
+
+	/* Configure PTP as S2500 supports it */
+	ret = s2500_ptp_register(priv);
+	if (ret)
+		goto err_reg_read;
+
+	ret = register_netdev(ndev);
+	if (!ret)
+		return ret;
+	dev_err(&spi->dev, "Failed to register netdev\n");
+	oa_tc6_ptp_unregister(priv->tc6);
+err_reg_read:
+	oa_tc6_exit(priv->tc6);
+	return ret;
+}
+
+static void s2500_remove(struct spi_device *spi)
+{
+	struct s2500_info *priv = spi_get_drvdata(spi);
+
+	dev_dbg(&priv->ndev->dev, "%s", "s2500_remove\n");
+
+	unregister_netdev(priv->ndev);
+	oa_tc6_ptp_unregister(priv->tc6);
+	oa_tc6_exit(priv->tc6);
+}
+
+static const struct of_device_id s2500_of_match[] = {
+	{ .compatible = "onnn,s2500" },
+	{ }
+};
+MODULE_DEVICE_TABLE(of, s2500_of_match);
+
+static const struct spi_device_id s2500_ids[] = {
+	{ "s2500" },
+	{ }
+};
+MODULE_DEVICE_TABLE(spi, s2500_ids);
+
+static struct spi_driver s2500_driver = {
+	.driver = {
+		.name = DRV_NAME,
+		.of_match_table = s2500_of_match,
+	},
+	.probe = s2500_probe,
+	.remove = s2500_remove,
+	.id_table = s2500_ids,
+};
+module_spi_driver(s2500_driver);
+
+MODULE_AUTHOR("Selva Rajagopal <selvamani.rajagopal@onsemi.com>");
+MODULE_AUTHOR("Piergiorgio Beruto");
+MODULE_DESCRIPTION("onsemi MACPHY ethernet driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
new file mode 100644
index 000000000000..2bcf69c0d6a2
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
@@ -0,0 +1,174 @@
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
+	u32 addr;
+	int ret;
+
+	ptp_read_system_prets(ptp_sts);
+	addr = FIELD_PREP(S2500_REG_MMS_MASK,
+			  OA_TC6_PHY_C45_VS_MMS12) |
+			  S2500_REG_VS_PTP_SEC;
+	ret = oa_tc6_read_registers(priv->tc6, addr, &data[0], 2);
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
+static int s2500_ptp_write_time(struct s2500_info *priv,
+				const struct timespec64 *ts)
+{
+	u32 data[2];
+	u32 addr;
+
+	lockdep_assert_held(&priv->ptp_adj_lock);
+
+	if (ts->tv_sec >= (1ULL << 32))
+		return -ERANGE;
+
+	data[0] = (u32)ts->tv_sec;
+	/* bit 31 = execute set command */
+	data[1] = ts->tv_nsec | BIT(31);
+	addr = FIELD_PREP(S2500_REG_MMS_MASK,
+			  OA_TC6_PHY_C45_VS_MMS12) |
+			  S2500_REG_VS_PTP_SETSEC;
+
+	return oa_tc6_write_registers(priv->tc6, addr, &data[0], 2);
+}
+
+static int s2500_ptp_set_time64(struct ptp_clock_info *ptp,
+				const struct timespec64 *ts)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	int ret;
+
+	mutex_lock(&priv->ptp_adj_lock);
+	ret = s2500_ptp_write_time(priv, ts);
+	mutex_unlock(&priv->ptp_adj_lock);
+
+	return ret;
+}
+
+static int s2500_ptp_set_freq(struct s2500_info *priv, long scaled_ppm)
+{
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
+	if (adj > S2500_PTP_ADJ_MAX)
+		return -ERANGE;
+
+	val = (u32)adj | sign_bit;
+	return oa_tc6_write_register_mms(priv->tc6, OA_TC6_PHY_C45_VS_MMS12,
+					 S2500_REG_VS_PTP_ADJ, val);
+}
+
+static int s2500_ptp_adjfine(struct ptp_clock_info *ptp, long scaled_ppm)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+
+	return s2500_ptp_set_freq(priv, scaled_ppm);
+}
+
+static int s2500_ptp_step_time(struct s2500_info *priv, s64 delta)
+{
+	struct timespec64 target, now, delta_ts;
+	struct ptp_system_timestamp sts;
+	int ret;
+
+	memset(&sts, 0, sizeof(sts));
+	ret = s2500_ptp_get_time64(&priv->ptp_clock_info, &now, &sts);
+	if (ret)
+		return ret;
+	if (delta >= 0) {
+		delta_ts = ns_to_timespec64(delta);
+		target = timespec64_add(now, delta_ts);
+	} else {
+		delta_ts = ns_to_timespec64(-delta);
+		target = timespec64_sub(now, delta_ts);
+	}
+	/* The subtraction above can take the target below the epoch */
+	if (target.tv_sec < 0)
+		return -ERANGE;
+	return s2500_ptp_write_time(priv, &target);
+}
+
+static int s2500_ptp_adjtime(struct ptp_clock_info *ptp, s64 delta)
+{
+	struct s2500_info *priv = container_of(ptp, struct s2500_info,
+					       ptp_clock_info);
+	int ret;
+
+	/* Nothing to do */
+	if (delta == 0)
+		return 0;
+
+	/* The device has no add-delta register, so the offset is applied as
+	 * a read-modify-write of the time registers.
+	 */
+	mutex_lock(&priv->ptp_adj_lock);
+	ret = s2500_ptp_step_time(priv, delta);
+	mutex_unlock(&priv->ptp_adj_lock);
+
+	return ret;
+}
+
+int s2500_ptp_register(struct s2500_info *priv)
+{
+	struct ptp_clock_info *info = &priv->ptp_clock_info;
+	int ret;
+
+	info->max_adj = S2500_PTP_MAX_ADJ_PPB;
+	info->owner = THIS_MODULE;
+	info->adjfine = s2500_ptp_adjfine;
+	info->gettimex64 = s2500_ptp_get_time64;
+	info->settime64 = s2500_ptp_set_time64;
+	info->adjtime = s2500_ptp_adjtime;
+
+	ret = oa_tc6_ptp_register(priv->tc6, info);
+	if (ret)
+		dev_err(&priv->spi->dev, "PTP registration failed\n");
+	return ret;
+}
+
diff --git a/include/linux/oa_tc6.h b/include/linux/oa_tc6.h
index 88e7d5491b20..86075ee113fe 100644
--- a/include/linux/oa_tc6.h
+++ b/include/linux/oa_tc6.h
@@ -75,6 +75,7 @@
 #define OA_TC6_PHY_C45_VS_PLCA_MMS4		4	/* MMD 31 */
 #define OA_TC6_PHY_C45_AUTO_NEG_MMS5		5	/* MMD 7 */
 #define OA_TC6_PHY_C45_POWER_UNIT_MMS6		6	/* MMD 13 */
+#define OA_TC6_PHY_C45_VS_MMS12			12	/* for vendors */
 
 struct oa_tc6;
 

-- 
2.43.0

