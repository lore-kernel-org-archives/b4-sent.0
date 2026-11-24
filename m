From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 24 Nov 2026 14:10:03 -0800
Subject: [PATCH net-next v12 15/15] net: ethernet: onsemi: s2500: Add
 driver support for S2500
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-s2500-mac-phy-support-v12-15-3575855d99f9@onsemi.com>
References: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
In-Reply-To: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=44897;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=2TQB8Ygu0aRCncLo2aESqIQ8v8oQpN3qoyj1g54Ov+Y=;
 b=6xBi+kYWHECCoZxvF/arpgtIlIOvGIt4uWXCdLGGeQNHuP/qiVQzMEXVUYTY0onejWUKEXmUf
 U5IlCeVZtm4DjsNc9UZ/cAOX9XFC8BjFoCklgc7ayd5AQU0Il3Afhns
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support for onsemi's S2500, 802.3cg compliant Ethernet
transceiver with integrated MAC-PHY. Works with
OPEN Alliance TC6 framework.

Hardware timestamp support is present in the driver. adjtime
functionality is implemented as a read-modify-write of the time
registers as the device has no add-delta register.

Driver has ethtool support for printing some device
registers, MAC, PHY and rmon stats and timestamp related
traffic counters.

The MAC address is taken from a device tree property if
present, otherwise from the device, otherwise a random
address is used.

Driver supports a maximum of three multicast filters. If
the system has more than 3 multicast addresses to support,
all multicast traffic is allowed.

Raise the transmit credit threshold from the default of 1
credit to 8, using the new oa_tc6_tx_credit_threshold_set()
helper, so that the MAC-PHY asserts the interrupt only when at
least 8 transmit credits are free.

Enable RX cut-through.

Enable the MAC's hardware FCS generation, so the host does
not have to append the FCS to transmitted frames.

Statistics read from the device are cached for 100 ms, so
repeated ethtool queries within that period return the
cached counters. The rx_otherhost_dropped link statistic
is refreshed every 3 seconds while the interface is up.

Support self-test. Also Add imply NET_SELFTESTS in Kconfig
so that users would be able to disable self-test and still
compile.

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v12
  - Squashed self-test for S2500 into this patch as number of
    patches nearing the maximum 15.
  - Moved OA TC6 framework API changes to its own patch.
  - Fixed RX filter and multicast handling.
  - Added rx_otherhost_dropped statistic, refreshed periodically.
changes in v11
  - fixed a potential "Oops" due to jumping to wrong label on error
    while enabling RX cut-through feature
  - Function that enables RX cut-through is made private
  - Moved the frame drop feature to separate patch as it is not
    related to S2500 driver support.
  - MAINTAINERS file changed to include files under onsemi too.
changes in v10
  - Removed the code that overwrites CONFIG0 after oa_tc6_init
    is done.
  - Removed the code that clears status0 register that would
    interfere interrupt handling
  - setting tx credit threshold to 8 credits
  - New API documentation moved to this patch
changes in v9
  - moved net_selftest entry in ethtool_ops to the correct patch
  - Moved MAINTAINERS changes here for driver files.
  - Fix the order of variable declaration to keep reverse Christmas
    tree format.
changes in v8
  - changes to use the new MMS read/write API in OA TC6 framework
  - Updated to improve adjtime/adjfine implementation
  - cleanup to remove unnecessary definitions/initializations
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
  - removed only model information as it has no practical use
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
 drivers/net/ethernet/onsemi/Kconfig               |  21 +
 drivers/net/ethernet/onsemi/Makefile              |   6 +
 drivers/net/ethernet/onsemi/s2500/Kconfig         |  20 +
 drivers/net/ethernet/onsemi/s2500/Makefile        |   6 +
 drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c | 389 +++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h  | 165 +++++++
 drivers/net/ethernet/onsemi/s2500/s2500_main.c    | 496 ++++++++++++++++++++++
 drivers/net/ethernet/onsemi/s2500/s2500_ptp.c     | 156 +++++++
 11 files changed, 1262 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 5020e938604a..e30e76acba5c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -21039,6 +21039,7 @@ M:	Selvamani Rajagopal <selvamani.rajagopal@onsemi.com>
 L:	netdev@vger.kernel.org
 S:	Supported
 F:	Documentation/devicetree/bindings/net/onnn,s2500.yaml
+F:	drivers/net/ethernet/onsemi/
 
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
index 000000000000..afef0c9ebc72
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
diff --git a/drivers/net/ethernet/onsemi/Makefile b/drivers/net/ethernet/onsemi/Makefile
new file mode 100644
index 000000000000..1091c55dcbe6
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Makefile for the onsemi network device drivers.
+#
+
+obj-$(CONFIG_S2500_MACPHY) += s2500/
diff --git a/drivers/net/ethernet/onsemi/s2500/Kconfig b/drivers/net/ethernet/onsemi/s2500/Kconfig
new file mode 100644
index 000000000000..4bd28dc560e6
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/Kconfig
@@ -0,0 +1,20 @@
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
+	  It works under the framework that conforms to OPEN Alliance
+	  10BASE-T1x Serial Interface specification.
+
+	  To compile this driver as a module, choose M here. The module will be
+	  called s2500.
diff --git a/drivers/net/ethernet/onsemi/s2500/Makefile b/drivers/net/ethernet/onsemi/s2500/Makefile
new file mode 100644
index 000000000000..807eabaa7a3c
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/Makefile
@@ -0,0 +1,6 @@
+# SPDX-License-Identifier: GPL-2.0-only
+#
+# Makefile for the onsemi network device drivers.
+#
+obj-$(CONFIG_S2500_MACPHY) := s2500.o
+s2500-objs := s2500_main.o s2500_ethtool.o s2500_ptp.o
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
new file mode 100644
index 000000000000..77d7d172efe0
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ethtool.c
@@ -0,0 +1,389 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#include <linux/ethtool.h>
+#include <net/selftests.h>
+#include <linux/phy.h>
+
+#include "s2500_hw_def.h"
+
+#define S2500_NUM_REGS			38
+#define S2500_REGDUMP_LEN		(sizeof(u32) * (S2500_NUM_REGS * 2))
+
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
+	{ S2500_REG_VS_MIIMIRQE,     S2500_VS_MMS12 },
+	{ S2500_REG_VS_MIIMIRQS,     S2500_VS_MMS12 },
+	{ S2500_REG_VS_DIOCFG0,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_CHIPID,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_TWEAKS2,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_MACID0,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_MACID1,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_NVM_HEALTH,   S2500_VS_MMS12 },
+	{ S2500_REG_VS_PTP_SEC,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_PTPNSEC,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_PTP_SETSEC,   S2500_VS_MMS12 },
+	{ S2500_REG_VS_SETNSEC,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_PTP_ADJ,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_CMPCTL,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_CMPSEC,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_CMPNSEC,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_CMPPER,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_CAPCTL,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_CAPSEC,       S2500_VS_MMS12 },
+	{ S2500_REG_VS_CAPNSEC,      S2500_VS_MMS12 },
+	{ S2500_REG_VS_BCNCNT,       S2500_VS_MMS12 },
+};
+
+enum s2500_stat_idx {
+	S2500_MSTOCTETSTX_IDX = 0,
+	S2500_MSTFRAMESTXOK_IDX,
+	S2500_MSTBCASTTXOK_IDX,
+	S2500_MSTMCASTTXOK_IDX,
+	S2500_MSTFRAMESTX64_IDX,
+	S2500_MSTFRAMESTX65_IDX,
+	S2500_MSTFRAMESTX128_IDX,
+	S2500_MSTFRAMESTX256_IDX,
+	S2500_MSTFRAMESTX512_IDX,
+	S2500_MSTFRAMESTX1024_IDX,
+	S2500_MSTTXUNDERFLOW_IDX,
+	S2500_MSTSINGLECOL_IDX,
+	S2500_MSTMULTICOL_IDX,
+	S2500_MSTEXCESSCOL_IDX,
+	S2500_MSTDEFERREDTX_IDX,
+	S2500_MSTCRSERR_IDX,
+	S2500_MSTOCTETSRX_IDX,
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
+	{ 1024, 1522 },
+	{ },
+};
+
+static_assert(ARRAY_SIZE(s2500_rmon_stat_map) == S2500_NUM_RMON_STATS);
+
+#define STAT_REG_OFFSET(x) ((S2500_REG_MAC_ST##x) - \
+			   S2500_REG_MAC_FIRST_STAT)
+
+/* Adds the registers just read to the counters. The hardware clears them on
+ * read, so each read returns only the delta since the previous read. Hence
+ * the values are accumulated. Called with stats_lock held.
+ */
+static void s2500_accumulate_stats(struct s2500_info *priv, const u32 *regs)
+{
+	u64 *data = priv->stats_data;
+	const u32 *rptr = regs;
+
+	lockdep_assert_held(&priv->stats_lock);
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
+	for (rptr += 2; (rptr - regs) < STAT_REG_OFFSET(OCTETSRXL); ++rptr)
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
+}
+
+/* Reads the statistics registers, unless that was done recently, and adds
+ * them to the counters. If @buf is not NULL it receives a copy of the
+ * counters, taken in the same locked section, so that the caller gets whole
+ * 64-bit values and a set that belongs together while the stats work keeps
+ * adding to them. The copy is made also when no register was read.
+ */
+void s2500_update_stats(struct s2500_info *priv, u64 *buf)
+{
+	u32 regs[S2500_NUM_STAT_REGS];
+	bool have_regs = false;
+	u32 addr;
+
+	if (!time_is_after_jiffies(priv->stats_last_update +
+				   S2500_STATS_CACHE_PERIOD)) {
+		addr = FIELD_PREP(S2500_REG_MMS_MASK, OA_TC6_MAC_MMS1) |
+				  S2500_REG_MAC_STOCTETSTXL;
+		have_regs = !oa_tc6_read_registers(priv->tc6, addr, regs,
+						   S2500_NUM_STAT_REGS);
+	}
+
+	if (!have_regs && !buf)
+		return;
+
+	spin_lock_bh(&priv->stats_lock);
+	if (have_regs) {
+		priv->stats_last_update = jiffies;
+		s2500_accumulate_stats(priv, regs);
+	}
+	if (buf)
+		memcpy(buf, priv->stats_data, sizeof(priv->stats_data));
+	spin_unlock_bh(&priv->stats_lock);
+}
+
+/* Cannot sleep, so no register is read here: the stats work keeps the
+ * counters up to date. The standard counters the driver keeps in
+ * ndev->stats are reported as well, as the core clears @stats first.
+ */
+void s2500_get_stats64(struct net_device *ndev,
+		       struct rtnl_link_stats64 *stats)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	netdev_stats_to_stats64(stats, &ndev->stats);
+
+	spin_lock_bh(&priv->stats_lock);
+	stats->rx_otherhost_dropped =
+		priv->stats_data[S2500_MSTRXDROPPED_IDX];
+	spin_unlock_bh(&priv->stats_lock);
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
+	case ETH_SS_TEST:
+		if (!IS_ENABLED(CONFIG_NET_SELFTESTS))
+			return -EOPNOTSUPP;
+		return net_selftest_get_count();
+	default:
+		return -EOPNOTSUPP;
+	}
+}
+
+static void s2500_get_strings(struct net_device *ndev, u32 stringset,
+			      u8 *buf)
+{
+	switch (stringset) {
+	case ETH_SS_TEST:
+		net_selftest_get_strings(buf);
+		break;
+	}
+}
+
+static void s2500_get_eth_mac_stats(struct net_device *ndev,
+				    struct ethtool_eth_mac_stats *mac_stats)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u64 st[S2500_NUM_STAT_VARS];
+
+	if (mac_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv, st);
+
+	mac_stats->OctetsTransmittedOK = st[S2500_MSTOCTETSTX_IDX];
+	mac_stats->FramesTransmittedOK = st[S2500_MSTFRAMESTXOK_IDX];
+	mac_stats->BroadcastFramesXmittedOK = st[S2500_MSTBCASTTXOK_IDX];
+	mac_stats->MulticastFramesXmittedOK = st[S2500_MSTMCASTTXOK_IDX];
+	mac_stats->SingleCollisionFrames = st[S2500_MSTSINGLECOL_IDX];
+	mac_stats->MultipleCollisionFrames = st[S2500_MSTMULTICOL_IDX];
+	mac_stats->FramesAbortedDueToXSColls = st[S2500_MSTEXCESSCOL_IDX];
+	mac_stats->FramesWithDeferredXmissions = st[S2500_MSTDEFERREDTX_IDX];
+	mac_stats->CarrierSenseErrors = st[S2500_MSTCRSERR_IDX];
+	mac_stats->FramesLostDueToIntMACXmitError =
+		st[S2500_MSTTXUNDERFLOW_IDX];
+	mac_stats->OctetsReceivedOK = st[S2500_MSTOCTETSRX_IDX];
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
+	u64 st[S2500_NUM_STAT_VARS];
+
+	if (phy_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv, st);
+	phy_stats->SymbolErrorDuringCarrier = st[S2500_MSTSYMBOLERRS_IDX];
+}
+
+static void s2500_rmon_stats(struct net_device *ndev,
+			     struct ethtool_rmon_stats *rmon_stats,
+			     const struct ethtool_rmon_hist_range **ranges)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u64 st[S2500_NUM_STAT_VARS];
+	u8 offset;
+	int i;
+
+	if (rmon_stats->src != ETHTOOL_MAC_STATS_SRC_AGGREGATE)
+		return;
+
+	s2500_update_stats(priv, st);
+
+	rmon_stats->undersize_pkts = st[S2500_MSTRUNTSERR_IDX];
+	rmon_stats->oversize_pkts = st[S2500_MSTRXTOOLONG_IDX];
+
+	for (i = 0; i < 6; i++) {
+		offset = s2500_rmon_stat_map[i];
+		rmon_stats->hist_tx[i] = st[offset];
+	}
+
+	for (i = 0; i < 6; i++) {
+		offset = s2500_rmon_stat_map[i + 6];
+		rmon_stats->hist[i] = st[offset];
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
+	.get_eth_mac_stats = s2500_get_eth_mac_stats,
+	.get_eth_phy_stats = s2500_get_eth_phy_stats,
+	.get_rmon_stats = s2500_rmon_stats,
+	.get_ts_info = s2500_get_ts_info,
+	.get_regs_len = s2500_get_regs_len,
+	.get_regs = s2500_get_regs,
+	.self_test = net_selftest,
+};
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
new file mode 100644
index 000000000000..1d80bec76824
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_hw_def.h
@@ -0,0 +1,165 @@
+/* SPDX-License-Identifier: GPL-2.0-or-later */
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#ifndef S2500_HW_DEF_H
+#define S2500_HW_DEF_H
+
+#include <linux/bitfield.h>
+#include <linux/kernel.h>
+#include <linux/netdevice.h>
+#include <linux/spi/spi.h>
+#include <linux/ptp_clock_kernel.h>
+#include <linux/mutex.h>
+#include <linux/spinlock.h>
+#include <linux/workqueue.h>
+#include <linux/ktime.h>
+#include <linux/errno.h>
+#include <linux/oa_tc6.h>
+
+#define DRV_NAME			"s2500"
+
+#define S2500_N_MCAST_FILTERS		3
+
+/* Vendor specific memory map selector (MMS 10..15 are vendor defined) */
+#define S2500_VS_MMS12			12
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
+/* Individual/group bit, the LSB of the first address byte (1 = multicast) */
+#define S2500_ADDR_IG_BIT		BIT(8)
+
+/* MAC statistic registers */
+#define S2500_REG_MAC_STOCTETSTXL	48
+#define S2500_REG_MAC_STOCTETSRXL	65
+#define S2500_REG_MAC_STRXDROPPED	82
+
+/* First/last statistic register for sequential access */
+#define S2500_REG_MAC_FIRST_STAT	S2500_REG_MAC_STOCTETSTXL
+#define S2500_REG_MAC_LAST_STAT		S2500_REG_MAC_STRXDROPPED
+
+#define S2500_NUM_STAT_REGS \
+	(S2500_REG_MAC_LAST_STAT - S2500_REG_MAC_FIRST_STAT + 1)
+#define S2500_NUM_STAT_VARS		(S2500_NUM_STAT_REGS - 2)
+#define S2500_STATS_CACHE_PERIOD	msecs_to_jiffies(100)
+#define S2500_STATS_WORK_PERIOD		msecs_to_jiffies(3000)
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
+/* MIIM IRQ enable register */
+#define S2500_REG_VS_MIIMIRQE		0x10
+
+/* MIIM IRQ status register */
+#define S2500_REG_VS_MIIMIRQS		0x11
+
+/* Digital I/O config register */
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
+/* Frequency adjust magnitude, 1 LSB = 0.000125 ppm = 1/8 ppb */
+#define S2500_PTP_ADJ_MAX		GENMASK(27, 0)
+#define S2500_PTP_ADJ_BASE		8000000000ULL
+#define S2500_PTP_MAX_ADJ_PPB		(S2500_PTP_ADJ_MAX / 8)
+
+/* PTP registers */
+#define S2500_REG_VS_PTP_SEC		0x1010
+#define S2500_REG_VS_PTPNSEC		0x1011
+#define S2500_REG_VS_PTP_SETSEC		0x1012
+#define S2500_REG_VS_SETNSEC		0x1013
+#define S2500_REG_VS_PTP_ADJ		0x1014
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
+	unsigned long stats_last_update;
+
+	/* Protects stats_data and stats_last_update. */
+	spinlock_t stats_lock;
+	struct delayed_work stats_work;
+
+	/* PTP related variables */
+	struct ptp_clock_info ptp_clock_info;
+	struct oa_tc6 *tc6;
+};
+
+int s2500_ptp_register(struct s2500_info *priv);
+
+void s2500_update_stats(struct s2500_info *priv, u64 *buf);
+void s2500_get_stats64(struct net_device *ndev,
+		       struct rtnl_link_stats64 *stats);
+
+#endif /* S2500_HW_DEF_H */
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_main.c b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
new file mode 100644
index 000000000000..55dbf3ba032d
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_main.c
@@ -0,0 +1,496 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+/*
+ * Copyright 2026 Semiconductor Components Industries, LLC ("onsemi").
+ * onsemi's S2500 10BASE-T1S MAC-PHY driver
+ */
+
+#include <linux/etherdevice.h>
+#include <linux/if_ether.h>
+#include <linux/module.h>
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
+	u8 mms = S2500_VS_MMS12;
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
+	/* Mapping for bits from PHY ID register to OUI as given below.
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
+	return 0;
+}
+
+/* Writes MAC address to macphy registers */
+static int s2500_write_filter(struct s2500_info *priv, int slot,
+			      const u8 *mac)
+{
+	u8 mms = OA_TC6_MAC_MMS1;
+	u32 val;
+	int ret;
+
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRMASKL(slot),
+					0xffffffff);
+	if (ret)
+		return ret;
+
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRMASKH(slot),
+					0xffff);
+	if (ret)
+		return ret;
+
+	val = get_unaligned_be32(&mac[2]);
+
+	ret = oa_tc6_write_register_mms(priv->tc6, mms,
+					S2500_REG_MAC_ADDRFILTL(slot), val);
+	if (ret)
+		return ret;
+
+	val = S2500_MAC_ADDRFILT_ENABLE | get_unaligned_be16(mac);
+
+	return oa_tc6_write_register_mms(priv->tc6, mms,
+					 S2500_REG_MAC_ADDRFILTH(slot), val);
+}
+
+static int s2500_set_mac_filter(struct net_device *ndev, const u8 *mac)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	int ret;
+
+	/* Disable slot 0 before programming its address. */
+	ret = oa_tc6_write_register_mms(priv->tc6, OA_TC6_MAC_MMS1,
+					S2500_REG_MAC_ADDRFILTH(0), 0);
+	if (ret)
+		return ret;
+
+	return s2500_write_filter(priv, 0, mac);
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
+	ret = oa_tc6_tx_credit_threshold_set(priv->tc6,
+					     OA_TC6_CONFIG0_TXCTHRESH_8);
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
+static int s2500_clear_mcast_filters(struct s2500_info *priv)
+{
+	int i, ret;
+
+	for (i = 1; i <= S2500_N_MCAST_FILTERS; i++) {
+		ret = oa_tc6_write_register_mms(priv->tc6, OA_TC6_MAC_MMS1,
+						S2500_REG_MAC_ADDRFILTH(i), 0);
+		if (ret)
+			return ret;
+	}
+
+	return 0;
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
+	if ((rx_flags & (IFF_PROMISC | IFF_ALLMULTI)) ||
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
+						addr, S2500_ADDR_IG_BIT);
+		if (ret)
+			return ret;
+
+		addr = S2500_REG_MAC_ADDRFILTL(1);
+		ret = oa_tc6_write_register_mms(priv->tc6, mms,
+						addr, 0);
+		if (ret)
+			return ret;
+
+		val = S2500_MAC_ADDRFILT_ENABLE | S2500_ADDR_IG_BIT;
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
+		ret = s2500_clear_mcast_filters(priv);
+	} else {
+		/* Disable multicast filter */
+		ret = s2500_mac_ctrl_modify_bits(priv,
+						 S2500_MAC_CTRL_MCSF,
+						 true);
+		if (ret)
+			return ret;
+
+		/* Disable filters */
+		ret = s2500_clear_mcast_filters(priv);
+		if (ret)
+			return ret;
+
+		/* Slot 0 holds the unicast MAC, multicast starts at 1 */
+		i = 1;
+		netdev_hw_addr_list_for_each(ha, mc) {
+			ret = s2500_write_filter(priv, i++, ha->addr);
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
+	ret = eth_prepare_mac_addr_change(ndev, p);
+	if (ret)
+		return ret;
+
+	ret = s2500_set_mac_filter(ndev, addr->sa_data);
+	if (ret)
+		return ret;
+
+	eth_commit_mac_addr_change(ndev, p);
+	return 0;
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
+static void s2500_stats_work(struct work_struct *work)
+{
+	struct s2500_info *priv = container_of(to_delayed_work(work),
+					       struct s2500_info, stats_work);
+
+	s2500_update_stats(priv, NULL);
+	schedule_delayed_work(&priv->stats_work, S2500_STATS_WORK_PERIOD);
+}
+
+static int s2500_open(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+	u32 val;
+	int ret;
+
+	phy_start(priv->ndev->phydev);
+
+	val = S2500_MAC_CTRL_TXEN | S2500_MAC_CTRL_RXEN;
+	ret = s2500_mac_ctrl_modify_bits(priv, val, false);
+	if (!ret) {
+		netif_start_queue(priv->ndev);
+		schedule_delayed_work(&priv->stats_work,
+				      S2500_STATS_WORK_PERIOD);
+	} else {
+		phy_stop(priv->ndev->phydev);
+	}
+	return ret;
+}
+
+static int s2500_stop(struct net_device *ndev)
+{
+	struct s2500_info *priv = netdev_priv(ndev);
+
+	cancel_delayed_work_sync(&priv->stats_work);
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
+	.ndo_get_stats64       = s2500_get_stats64,
+	.ndo_eth_ioctl         = phy_do_ioctl_running,
+	.ndo_hwtstamp_get      = s2500_hwtstamp_get,
+	.ndo_hwtstamp_set      = s2500_hwtstamp_set,
+};
+
+static int s2500_probe(struct spi_device *spi)
+{
+	struct oa_tc6_quirks tc6_quirks = {
+		.quirk_flags = OA_TC6_CONFIG_RX_CUT_THROUGH,
+		.vend1_mms = S2500_VS_MMS12,
+	};
+	struct device *dev = &spi->dev;
+	struct net_device *ndev;
+	struct s2500_info *priv;
+	int ret;
+
+	if (!spi->irq)
+		return dev_err_probe(dev, -ENODEV, "Missing interrupt\n");
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
+	spin_lock_init(&priv->stats_lock);
+	INIT_DELAYED_WORK(&priv->stats_work, s2500_stats_work);
+	ndev->irq = spi->irq;
+
+	/* Ensures that the first read is not from the cache. */
+	priv->stats_last_update = jiffies - S2500_STATS_CACHE_PERIOD;
+
+	spi_set_drvdata(spi, priv);
+
+	ndev->netdev_ops = &s2500_netdev_ops;
+	ndev->ethtool_ops = &s2500_ethtool_ops;
+	ndev->if_port = IF_PORT_10BASET;
+	ndev->priv_flags |= IFF_LIVE_ADDR_CHANGE;
+
+	priv->tc6 = oa_tc6_init(spi, ndev, &tc6_quirks);
+	if (IS_ERR(priv->tc6))
+		return dev_err_probe(dev, PTR_ERR(priv->tc6),
+				     "OA TC6 init failed\n");
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
+		dev_err_probe(dev, ret, "Failed to initialize device\n");
+		goto err_tc6_exit;
+	}
+
+	/* Configure PTP as S2500 supports it */
+	ret = s2500_ptp_register(priv);
+	if (ret)
+		goto err_tc6_exit;
+
+	ret = register_netdev(ndev);
+	if (ret) {
+		dev_err_probe(dev, ret, "Failed to register netdev\n");
+		oa_tc6_ptp_unregister(priv->tc6);
+		goto err_tc6_exit;
+	}
+
+	return 0;
+
+err_tc6_exit:
+	oa_tc6_exit(priv->tc6);
+	return ret;
+}
+
+static void s2500_remove(struct spi_device *spi)
+{
+	struct s2500_info *priv = spi_get_drvdata(spi);
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
+MODULE_AUTHOR("Selvamani Rajagopal <selvamani.rajagopal@onsemi.com>");
+MODULE_AUTHOR("Piergiorgio Beruto");
+MODULE_DESCRIPTION("onsemi MACPHY ethernet driver");
+MODULE_LICENSE("GPL");
diff --git a/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
new file mode 100644
index 000000000000..595067a97ae5
--- /dev/null
+++ b/drivers/net/ethernet/onsemi/s2500/s2500_ptp.c
@@ -0,0 +1,156 @@
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
+	addr = FIELD_PREP(S2500_REG_MMS_MASK, S2500_VS_MMS12) |
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
+	addr = FIELD_PREP(S2500_REG_MMS_MASK, S2500_VS_MMS12) |
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
+	u64 adj;
+	u32 val;
+
+	if (diff_by_scaled_ppm(S2500_PTP_ADJ_BASE, scaled_ppm, &adj))
+		sign_bit = 1U << 31;
+
+	/* check overflow */
+	if (adj > S2500_PTP_ADJ_MAX)
+		return -ERANGE;
+
+	val = (u32)adj | sign_bit;
+	return oa_tc6_write_register_mms(priv->tc6, S2500_VS_MMS12,
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
+	ktime_t start;
+	s64 elapsed;
+	int ret;
+
+	start = ktime_get_raw();
+	ret = s2500_ptp_get_time64(&priv->ptp_clock_info, &now, NULL);
+	if (ret)
+		return ret;
+	if (delta >= 0) {
+		delta_ts = ns_to_timespec64(delta);
+		target = timespec64_add(now, delta_ts);
+	} else {
+		delta_ts = ns_to_timespec64(-delta);
+		target = timespec64_sub(now, delta_ts);
+	}
+
+	/* Adjust the time to take the SPI transaction time into
+	 * account.
+	 */
+	elapsed = ktime_to_ns(ktime_sub(ktime_get_raw(), start));
+	timespec64_add_ns(&target, elapsed);
+
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
+
+	info->max_adj = S2500_PTP_MAX_ADJ_PPB;
+	info->owner = THIS_MODULE;
+	info->adjfine = s2500_ptp_adjfine;
+	info->gettimex64 = s2500_ptp_get_time64;
+	info->settime64 = s2500_ptp_set_time64;
+	info->adjtime = s2500_ptp_adjtime;
+
+	return oa_tc6_ptp_register(priv->tc6, info);
+}

-- 
2.43.0

