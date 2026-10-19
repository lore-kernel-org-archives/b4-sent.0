From: Junyi Zhao <junyi.zhao@amlogic.com>
Date: Mon, 19 Oct 2026 13:34:26 +0800
Subject: [PATCH 1/3] i3c: master: Rework SVC I3C to support vendor glue
 layers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-a9_i3c-v1-1-329d819d621f@amlogic.com>
References: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
In-Reply-To: <20261019-a9_i3c-v1-0-329d819d621f@amlogic.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Frank Li <Frank.Li@nxp.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Miquel Raynal <miquel.raynal@bootlin.com>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-i3c@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, imx@lists.linux.dev, 
 linux-hardening@vger.kernel.org, xianwei.zhao@amlogic.com, 
 Kelvin.Zhang@amlogic.com, Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792388075; l=38557;
 i=junyi.zhao@amlogic.com; s=20260924; h=from:subject:message-id;
 bh=mDIg70438nrWm43cCN+GqrsV9bjxUSew4NhCAFetomU=;
 b=7AJO/fN8QU8pgIIPDPL8ti1amdmYR0MyK8uGsk1cM0kra6o+2EeMZVA90RPQMikwvu0bw13rE
 Z5NOow3OKuIATyHEU17GtZCv2GnSi0HG9TbUTyV5D0lg/+WIiI+lO8b
X-Developer-Key: i=junyi.zhao@amlogic.com; a=ed25519;
 pk=hiL5PjGIksGFiWvEx9J3MhQqU/ro6vNbj72NIw4bbvA=
X-Endpoint-Received: by B4 Relay for junyi.zhao@amlogic.com/20260924 with auth_id=1054
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SVC I3C controller IP can be integrated into SoCs from different
vendors. Peripheral resources associated with the controller, such as
clocks, may vary between vendor implementations.

Rework the driver to separate common functionality from
vendor-specific extensions. The common logic is shared across all
implementations, while platform-dependent operations are provided
through vendor-specific hooks.

Also add a corresponding MAINTAINERS entry for the SILVACO I3C
controller.

Signed-off-by: Junyi Zhao <junyi.zhao@amlogic.com>
---
 MAINTAINERS                                        |   6 +-
 drivers/i3c/master/Kconfig                         |   9 +-
 drivers/i3c/master/Makefile                        |   2 +-
 drivers/i3c/master/svc/Kconfig                     |  21 +
 drivers/i3c/master/svc/Makefile                    |   5 +
 .../master/{svc-i3c-master.c => svc/i3c-main.c}    | 467 ++-------------------
 drivers/i3c/master/svc/i3c-main.h                  | 297 +++++++++++++
 drivers/i3c/master/svc/i3c-silvaco.c               | 173 ++++++++
 8 files changed, 543 insertions(+), 437 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 77bd64bae..dffc63af2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25566,7 +25566,11 @@ L:	linux-i3c@lists.infradead.org (moderated for non-subscribers)
 L:	imx@lists.linux.dev
 S:	Maintained
 F:	Documentation/devicetree/bindings/i3c/silvaco,i3c-master.yaml
-F:	drivers/i3c/master/svc-i3c-master.c
+F:	drivers/i3c/master/svc/Kconfig
+F:	drivers/i3c/master/svc/Makefile
+F:	drivers/i3c/master/svc/i3c-main.c
+F:	drivers/i3c/master/svc/i3c-main.h
+F:	drivers/i3c/master/svc/i3c-silvaco.c
 
 SIMPLEFB FB DRIVER
 M:	Hans de Goede <hansg@kernel.org>
diff --git a/drivers/i3c/master/Kconfig b/drivers/i3c/master/Kconfig
index da96d2aaa..722661c2e 100644
--- a/drivers/i3c/master/Kconfig
+++ b/drivers/i3c/master/Kconfig
@@ -45,13 +45,6 @@ config AST2600_I3C_MASTER
 	  This driver can also be built as a module.  If so, the module
 	  will be called ast2600-i3c-master.
 
-config SVC_I3C_MASTER
-	tristate "Silvaco I3C Dual-Role Master driver"
-	depends on HAS_IOMEM
-	depends on !(ALPHA || PARISC)
-	help
-	  Support for Silvaco I3C Dual-Role Master Controller.
-
 config MIPI_I3C_HCI
 	tristate "MIPI I3C Host Controller Interface driver (EXPERIMENTAL)"
 	depends on HAS_IOMEM
@@ -101,3 +94,5 @@ config AMD_AXI_I3C_MASTER
 
 	  This driver can also be built as a module. If so, the module
 	  will be called amd-i3c-master.
+
+source "drivers/i3c/master/svc/Kconfig"
diff --git a/drivers/i3c/master/Makefile b/drivers/i3c/master/Makefile
index 8d82196dc..a85e566ba 100644
--- a/drivers/i3c/master/Makefile
+++ b/drivers/i3c/master/Makefile
@@ -3,7 +3,7 @@ obj-$(CONFIG_ADI_I3C_MASTER)		+= adi-i3c-master.o
 obj-$(CONFIG_CDNS_I3C_MASTER)		+= i3c-master-cdns.o
 obj-$(CONFIG_DW_I3C_MASTER)		+= dw-i3c-master.o
 obj-$(CONFIG_AST2600_I3C_MASTER)	+= ast2600-i3c-master.o
-obj-$(CONFIG_SVC_I3C_MASTER)		+= svc-i3c-master.o
+obj-$(CONFIG_SVC_I3C)		+= svc/
 obj-$(CONFIG_MIPI_I3C_HCI)		+= mipi-i3c-hci/
 obj-$(CONFIG_RENESAS_I3C)		+= renesas-i3c.o
 obj-$(CONFIG_AMD_AXI_I3C_MASTER)	+= amd-i3c-master.o
diff --git a/drivers/i3c/master/svc/Kconfig b/drivers/i3c/master/svc/Kconfig
new file mode 100644
index 000000000..14fa1e542
--- /dev/null
+++ b/drivers/i3c/master/svc/Kconfig
@@ -0,0 +1,21 @@
+# SPDX-License-Identifier: GPL-2.0-only
+
+config SVC_I3C
+	tristate "SVC I3C Dual-Role Master driver"
+	depends on HAS_IOMEM
+	depends on !(ALPHA || PARISC)
+	help
+	  Support for SVC I3C Dual-Role Master Controller.
+
+if SVC_I3C
+
+config I3C_SILVACO
+	tristate "Silvaco I3C Master support for other vendors"
+	default y
+	help
+	  Support for Silvaco I3C Dual-Role Master Controller with the
+	  generic (upstream) probe glue. This covers the original
+	  compatible strings such as "silvaco,i3c-master-v1" and
+	  "nuvoton,npcm845-i3c".
+
+endif # SVC_I3C
diff --git a/drivers/i3c/master/svc/Makefile b/drivers/i3c/master/svc/Makefile
new file mode 100644
index 000000000..cf18c5da6
--- /dev/null
+++ b/drivers/i3c/master/svc/Makefile
@@ -0,0 +1,5 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+# Copyright (C) 2026 Amlogic, Inc. All rights reserved
+
+obj-$(CONFIG_SVC_I3C)	+= i3c-main.o
+obj-$(CONFIG_I3C_SILVACO)	+= i3c-silvaco.o
diff --git a/drivers/i3c/master/svc-i3c-master.c b/drivers/i3c/master/svc/i3c-main.c
similarity index 79%
rename from drivers/i3c/master/svc-i3c-master.c
rename to drivers/i3c/master/svc/i3c-main.c
index e700392f0..10e2f7761 100644
--- a/drivers/i3c/master/svc-i3c-master.c
+++ b/drivers/i3c/master/svc/i3c-main.c
@@ -6,285 +6,7 @@
  * Author: Miquel RAYNAL <miquel.raynal@bootlin.com>
  * Based on a work from: Conor Culhane <conor.culhane@silvaco.com>
  */
-
-#include <linux/bitfield.h>
-#include <linux/clk.h>
-#include <linux/completion.h>
-#include <linux/errno.h>
-#include <linux/i3c/master.h>
-#include <linux/interrupt.h>
-#include <linux/iopoll.h>
-#include <linux/list.h>
-#include <linux/module.h>
-#include <linux/of.h>
-#include <linux/pinctrl/consumer.h>
-#include <linux/platform_device.h>
-#include <linux/pm_runtime.h>
-
-/* Master Mode Registers */
-#define SVC_I3C_MCONFIG      0x000
-#define   SVC_I3C_MCONFIG_MASTER_EN BIT(0)
-#define   SVC_I3C_MCONFIG_DISTO(x) FIELD_PREP(BIT(3), (x))
-#define   SVC_I3C_MCONFIG_HKEEP(x) FIELD_PREP(GENMASK(5, 4), (x))
-#define   SVC_I3C_MCONFIG_ODSTOP(x) FIELD_PREP(BIT(6), (x))
-#define   SVC_I3C_MCONFIG_PPBAUD(x) FIELD_PREP(GENMASK(11, 8), (x))
-#define   SVC_I3C_MCONFIG_PPLOW(x) FIELD_PREP(GENMASK(15, 12), (x))
-#define   SVC_I3C_MCONFIG_ODBAUD(x) FIELD_PREP(GENMASK(23, 16), (x))
-#define   SVC_I3C_MCONFIG_ODHPP(x) FIELD_PREP(BIT(24), (x))
-#define   SVC_I3C_MCONFIG_SKEW(x) FIELD_PREP(GENMASK(27, 25), (x))
-#define   SVC_I3C_MCONFIG_SKEW_MASK GENMASK(27, 25)
-#define   SVC_I3C_MCONFIG_I2CBAUD(x) FIELD_PREP(GENMASK(31, 28), (x))
-
-#define SVC_I3C_MCTRL        0x084
-#define   SVC_I3C_MCTRL_REQUEST_MASK GENMASK(2, 0)
-#define   SVC_I3C_MCTRL_REQUEST_NONE 0
-#define   SVC_I3C_MCTRL_REQUEST_START_ADDR 1
-#define   SVC_I3C_MCTRL_REQUEST_STOP 2
-#define   SVC_I3C_MCTRL_REQUEST_FORCE_EXIT 6
-#define   SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK 3
-#define   SVC_I3C_MCTRL_REQUEST_PROC_DAA 4
-#define   SVC_I3C_MCTRL_REQUEST_AUTO_IBI 7
-#define   SVC_I3C_MCTRL_TYPE_I3C 0
-#define   SVC_I3C_MCTRL_TYPE_I2C BIT(4)
-#define   SVC_I3C_MCTRL_TYPE_DDR BIT(5)
-#define   SVC_I3C_MCTRL_IBIRESP_AUTO 0
-#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITHOUT_BYTE 0
-#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITH_BYTE BIT(7)
-#define   SVC_I3C_MCTRL_IBIRESP_NACK BIT(6)
-#define   SVC_I3C_MCTRL_IBIRESP_MANUAL GENMASK(7, 6)
-#define   SVC_I3C_MCTRL_DIR(x) FIELD_PREP(BIT(8), (x))
-#define   SVC_I3C_MCTRL_DIR_WRITE 0
-#define   SVC_I3C_MCTRL_DIR_READ 1
-#define   SVC_I3C_MCTRL_ADDR(x) FIELD_PREP(GENMASK(15, 9), (x))
-#define   SVC_I3C_MCTRL_RDTERM(x) FIELD_PREP(GENMASK(23, 16), (x))
-
-#define SVC_I3C_MSTATUS      0x088
-#define   SVC_I3C_MSTATUS_STATE(x) FIELD_GET(GENMASK(2, 0), (x))
-#define   SVC_I3C_MSTATUS_STATE_DAA(x) (SVC_I3C_MSTATUS_STATE(x) == 5)
-#define   SVC_I3C_MSTATUS_STATE_SLVREQ(x) (SVC_I3C_MSTATUS_STATE(x) == 1)
-#define   SVC_I3C_MSTATUS_STATE_IDLE(x) (SVC_I3C_MSTATUS_STATE(x) == 0)
-#define   SVC_I3C_MSTATUS_BETWEEN(x) FIELD_GET(BIT(4), (x))
-#define   SVC_I3C_MSTATUS_NACKED(x) FIELD_GET(BIT(5), (x))
-#define   SVC_I3C_MSTATUS_IBITYPE(x) FIELD_GET(GENMASK(7, 6), (x))
-#define   SVC_I3C_MSTATUS_IBITYPE_IBI 1
-#define   SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST 2
-#define   SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN 3
-#define   SVC_I3C_MINT_SLVSTART BIT(8)
-#define   SVC_I3C_MINT_MCTRLDONE BIT(9)
-#define   SVC_I3C_MINT_COMPLETE BIT(10)
-#define   SVC_I3C_MINT_RXPEND BIT(11)
-#define   SVC_I3C_MINT_TXNOTFULL BIT(12)
-#define   SVC_I3C_MINT_IBIWON BIT(13)
-#define   SVC_I3C_MINT_ERRWARN BIT(15)
-#define   SVC_I3C_MSTATUS_SLVSTART(x) FIELD_GET(SVC_I3C_MINT_SLVSTART, (x))
-#define   SVC_I3C_MSTATUS_MCTRLDONE(x) FIELD_GET(SVC_I3C_MINT_MCTRLDONE, (x))
-#define   SVC_I3C_MSTATUS_COMPLETE(x) FIELD_GET(SVC_I3C_MINT_COMPLETE, (x))
-#define   SVC_I3C_MSTATUS_RXPEND(x) FIELD_GET(SVC_I3C_MINT_RXPEND, (x))
-#define   SVC_I3C_MSTATUS_TXNOTFULL(x) FIELD_GET(SVC_I3C_MINT_TXNOTFULL, (x))
-#define   SVC_I3C_MSTATUS_IBIWON(x) FIELD_GET(SVC_I3C_MINT_IBIWON, (x))
-#define   SVC_I3C_MSTATUS_ERRWARN(x) FIELD_GET(SVC_I3C_MINT_ERRWARN, (x))
-#define   SVC_I3C_MSTATUS_IBIADDR(x) FIELD_GET(GENMASK(30, 24), (x))
-
-#define SVC_I3C_IBIRULES     0x08C
-#define   SVC_I3C_IBIRULES_ADDR(slot, addr) FIELD_PREP(GENMASK(29, 0), \
-						       ((addr) & 0x3F) << ((slot) * 6))
-#define   SVC_I3C_IBIRULES_ADDRS 5
-#define   SVC_I3C_IBIRULES_MSB0 BIT(30)
-#define   SVC_I3C_IBIRULES_NOBYTE BIT(31)
-#define   SVC_I3C_IBIRULES_MANDBYTE 0
-#define SVC_I3C_MINTSET      0x090
-#define SVC_I3C_MINTCLR      0x094
-#define SVC_I3C_MINTMASKED   0x098
-#define SVC_I3C_MERRWARN     0x09C
-#define   SVC_I3C_MERRWARN_NACK BIT(2)
-#define   SVC_I3C_MERRWARN_CRC	BIT(10)
-#define   SVC_I3C_MERRWARN_TIMEOUT BIT(20)
-#define SVC_I3C_MDMACTRL     0x0A0
-#define SVC_I3C_MDATACTRL    0x0AC
-#define   SVC_I3C_MDATACTRL_FLUSHTB BIT(0)
-#define   SVC_I3C_MDATACTRL_FLUSHRB BIT(1)
-#define   SVC_I3C_MDATACTRL_UNLOCK_TRIG BIT(3)
-#define   SVC_I3C_MDATACTRL_TXTRIG_FIFO_NOT_FULL GENMASK(5, 4)
-#define   SVC_I3C_MDATACTRL_RXTRIG_FIFO_NOT_EMPTY 0
-#define   SVC_I3C_MDATACTRL_RXCOUNT(x) FIELD_GET(GENMASK(28, 24), (x))
-#define   SVC_I3C_MDATACTRL_TXCOUNT(x) FIELD_GET(GENMASK(20, 16), (x))
-#define   SVC_I3C_MDATACTRL_TXFULL BIT(30)
-#define   SVC_I3C_MDATACTRL_RXEMPTY BIT(31)
-
-#define SVC_I3C_MWDATAB      0x0B0
-#define   SVC_I3C_MWDATAB_END BIT(8)
-
-#define SVC_I3C_MWDATABE     0x0B4
-#define SVC_I3C_MWDATAH      0x0B8
-#define SVC_I3C_MWDATAHE     0x0BC
-#define SVC_I3C_MRDATAB      0x0C0
-#define SVC_I3C_MRDATAH      0x0C8
-#define SVC_I3C_MWDATAB1     0x0CC
-#define SVC_I3C_MWMSG_SDR    0x0D0
-#define SVC_I3C_MRMSG_SDR    0x0D4
-#define SVC_I3C_MWMSG_DDR    0x0D8
-#define SVC_I3C_MRMSG_DDR    0x0DC
-
-#define SVC_I3C_MDYNADDR     0x0E4
-#define   SVC_MDYNADDR_VALID BIT(0)
-#define   SVC_MDYNADDR_ADDR(x) FIELD_PREP(GENMASK(7, 1), (x))
-
-#define SVC_I3C_MAX_DEVS 32
-#define SVC_I3C_PM_TIMEOUT_MS 1000
-
-/* This parameter depends on the implementation and may be tuned */
-#define SVC_I3C_FIFO_SIZE 16
-#define SVC_I3C_PPBAUD_MAX 15
-#define SVC_I3C_QUICK_I2C_CLK 4170000
-
-#define SVC_I3C_EVENT_IBI	GENMASK(7, 0)
-#define SVC_I3C_EVENT_HOTJOIN	BIT(31)
-
-/*
- * SVC_I3C_QUIRK_FIFO_EMPTY:
- * I3C HW stalls the write transfer if the transmit FIFO becomes empty,
- * when new data is written to FIFO, I3C HW resumes the transfer but
- * the first transmitted data bit may have the wrong value.
- * Workaround:
- * Fill the FIFO in advance to prevent FIFO from becoming empty.
- */
-#define SVC_I3C_QUIRK_FIFO_EMPTY	BIT(0)
-/*
- * SVC_I3C_QUIRK_FLASE_SLVSTART:
- * I3C HW may generate an invalid SlvStart event when emitting a STOP.
- * If it is a true SlvStart, the MSTATUS state is SLVREQ.
- */
-#define SVC_I3C_QUIRK_FALSE_SLVSTART	BIT(1)
-/*
- * SVC_I3C_QUIRK_DAA_CORRUPT:
- * When MCONFIG.SKEW=0 and MCONFIG.ODHPP=0, the ENTDAA transaction gets
- * corrupted and results in a no repeated-start condition at the end of
- * address assignment.
- * Workaround:
- * Set MCONFIG.SKEW to 1 before initiating the DAA process. After the DAA
- * process is completed, return MCONFIG.SKEW to its previous value.
- */
-#define SVC_I3C_QUIRK_DAA_CORRUPT	BIT(2)
-
-struct svc_i3c_cmd {
-	u8 addr;
-	union {
-		bool rnw;
-		u8 cmd;
-		u32 rnw_cmd;
-	};
-	u8 *in;
-	const void *out;
-	unsigned int len;
-	unsigned int actual_len;
-	struct i3c_xfer *xfer;
-	bool continued;
-};
-
-struct svc_i3c_xfer {
-	struct list_head node;
-	struct completion comp;
-	int ret;
-	unsigned int type;
-	unsigned int ncmds;
-	struct svc_i3c_cmd cmds[] __counted_by(ncmds);
-};
-
-struct svc_i3c_regs_save {
-	u32 mconfig;
-	u32 mdynaddr;
-};
-
-struct svc_i3c_drvdata {
-	u32 quirks;
-};
-
-/**
- * struct svc_i3c_master - Silvaco I3C Master structure
- * @base: I3C master controller
- * @dev: Corresponding device
- * @regs: Memory mapping
- * @saved_regs: Volatile values for PM operations
- * @free_slots: Bit array of available slots
- * @addrs: Array containing the dynamic addresses of each attached device
- * @descs: Array of descriptors, one per attached device
- * @irq: Main interrupt
- * @num_clks: I3C clock number
- * @fclk: Fast clock (bus)
- * @clks: I3C clock array
- * @xferqueue: Transfer queue structure
- * @xferqueue.list: List member
- * @xferqueue.cur: Current ongoing transfer
- * @xferqueue.lock: Queue lock
- * @ibi: IBI structure
- * @ibi.num_slots: Number of slots available in @ibi.slots
- * @ibi.slots: Available IBI slots
- * @ibi.tbq_slot: To be queued IBI slot
- * @ibi.lock: IBI lock
- * @lock: Transfer lock, protect between IBI work thread and callbacks from master
- * @drvdata: Driver data
- * @enabled_events: Bit masks for enable events (IBI, HotJoin).
- * @mctrl_config: Configuration value in SVC_I3C_MCTRL for setting speed back.
- */
-struct svc_i3c_master {
-	struct i3c_master_controller base;
-	struct device *dev;
-	void __iomem *regs;
-	struct svc_i3c_regs_save saved_regs;
-	u32 free_slots;
-	u8 addrs[SVC_I3C_MAX_DEVS];
-	struct i3c_dev_desc *descs[SVC_I3C_MAX_DEVS];
-	int irq;
-	int num_clks;
-	struct clk *fclk;
-	struct clk_bulk_data *clks;
-	struct {
-		struct list_head list;
-		struct svc_i3c_xfer *cur;
-		/* Prevent races between transfers */
-		spinlock_t lock;
-	} xferqueue;
-	struct {
-		unsigned int num_slots;
-		struct i3c_dev_desc **slots;
-		struct i3c_ibi_slot *tbq_slot;
-		/* Prevent races within IBI handlers */
-		spinlock_t lock;
-	} ibi;
-	struct mutex lock;
-	const struct svc_i3c_drvdata *drvdata;
-	u32 enabled_events;
-	u32 mctrl_config;
-};
-
-/**
- * struct svc_i3c_i2c_dev_data - Device specific data
- * @index: Index in the master tables corresponding to this device
- * @ibi: IBI slot index in the master structure
- * @ibi_pool: IBI pool associated to this device
- */
-struct svc_i3c_i2c_dev_data {
-	u8 index;
-	int ibi;
-	struct i3c_generic_ibi_pool *ibi_pool;
-};
-
-static inline bool svc_has_quirk(struct svc_i3c_master *master, u32 quirk)
-{
-	return (master->drvdata->quirks & quirk);
-}
-
-static inline bool svc_has_daa_corrupt(struct svc_i3c_master *master)
-{
-	return ((master->drvdata->quirks & SVC_I3C_QUIRK_DAA_CORRUPT) &&
-		!(master->mctrl_config &
-		(SVC_I3C_MCONFIG_SKEW_MASK | SVC_I3C_MCONFIG_ODHPP(1))));
-}
-
-static inline bool is_events_enabled(struct svc_i3c_master *master, u32 mask)
-{
-	return !!(master->enabled_events & mask);
-}
+#include "i3c-main.h"
 
 static bool svc_i3c_master_error(struct svc_i3c_master *master)
 {
@@ -719,7 +441,7 @@ static int svc_i3c_master_set_speed(struct i3c_master_controller *m,
 
 	switch (speed) {
 	case I3C_OPEN_DRAIN_SLOW_SPEED:
-		fclk_rate = clk_get_rate(master->fclk);
+		fclk_rate = master->fclk_rate;
 		if (!fclk_rate) {
 			ret = -EINVAL;
 			goto rpm_out;
@@ -769,7 +491,7 @@ static int svc_i3c_master_bus_init(struct i3c_master_controller *m)
 	}
 
 	/* Timings derivation */
-	fclk_rate = clk_get_rate(master->fclk);
+	fclk_rate = master->fclk_rate;
 	if (!fclk_rate) {
 		ret = -EINVAL;
 		goto rpm_out;
@@ -1997,56 +1719,55 @@ static const struct i3c_master_controller_ops svc_i3c_master_ops = {
 	.set_speed = svc_i3c_master_set_speed,
 };
 
-static int svc_i3c_master_probe(struct platform_device *pdev)
+void svc_i3c_master_remove(struct svc_i3c_master *master)
 {
-	struct device *dev = &pdev->dev;
-	struct svc_i3c_master *master;
-	int ret, i;
+	i3c_master_unregister(&master->base);
+}
+EXPORT_SYMBOL_GPL(svc_i3c_master_remove);
 
-	master = devm_kzalloc(dev, sizeof(*master), GFP_KERNEL);
-	if (!master)
-		return -ENOMEM;
+void svc_i3c_save_regs(struct svc_i3c_master *master)
+{
+	master->saved_regs.mconfig = readl(master->regs + SVC_I3C_MCONFIG);
+	master->saved_regs.mdynaddr = readl(master->regs + SVC_I3C_MDYNADDR);
+}
+EXPORT_SYMBOL_GPL(svc_i3c_save_regs);
 
-	master->drvdata = of_device_get_match_data(dev);
-	if (!master->drvdata)
-		return -EINVAL;
+void svc_i3c_restore_regs(struct svc_i3c_master *master)
+{
+	if (readl(master->regs + SVC_I3C_MDYNADDR) !=
+	    master->saved_regs.mdynaddr) {
+		writel(master->saved_regs.mconfig,
+		       master->regs + SVC_I3C_MCONFIG);
+		writel(master->saved_regs.mdynaddr,
+		       master->regs + SVC_I3C_MDYNADDR);
+	}
+}
+EXPORT_SYMBOL_GPL(svc_i3c_restore_regs);
 
-	master->regs = devm_platform_ioremap_resource(pdev, 0);
-	if (IS_ERR(master->regs))
-		return PTR_ERR(master->regs);
+struct svc_i3c_master *svc_i3c_master_alloc(struct device *dev)
+{
+	struct svc_i3c_master *master;
 
-	master->num_clks = devm_clk_bulk_get_all(dev, &master->clks);
-	if (master->num_clks < 0)
-		return dev_err_probe(dev, -EINVAL, "can't get I3C clocks\n");
+	master = devm_kzalloc(dev, sizeof(*master), GFP_KERNEL);
 
-	for (i = 0; i < master->num_clks; i++) {
-		if (!strcmp(master->clks[i].id, "fast_clk"))
-			break;
-	}
+	return master;
+}
+EXPORT_SYMBOL_GPL(svc_i3c_master_alloc);
 
-	if (i == master->num_clks)
-		return dev_err_probe(dev, -EINVAL,
-				     "can't get I3C peripheral clock\n");
+int svc_i3c_master_probe(struct platform_device *pdev, struct svc_i3c_master *master)
+{
+	struct device *dev = &pdev->dev;
 
-	master->fclk = master->clks[i].clk;
-	if (IS_ERR(master->fclk))
-		return PTR_ERR(master->fclk);
+	int ret;
 
 	master->irq = platform_get_irq(pdev, 0);
 	if (master->irq < 0)
 		return master->irq;
-
-	master->dev = dev;
-	ret = clk_bulk_prepare_enable(master->num_clks, master->clks);
-	if (ret)
-		return dev_err_probe(dev, ret, "can't enable I3C clocks\n");
-
 	mutex_init(&master->lock);
-
 	ret = devm_request_irq(dev, master->irq, svc_i3c_master_irq_handler,
 			       IRQF_NO_SUSPEND, "svc-i3c-irq", master);
 	if (ret)
-		goto err_disable_clks;
+		return ret;
 
 	master->free_slots = GENMASK(SVC_I3C_MAX_DEVS - 1, 0);
 
@@ -2058,128 +1779,18 @@ static int svc_i3c_master_probe(struct platform_device *pdev)
 	master->ibi.slots = devm_kcalloc(&pdev->dev, master->ibi.num_slots,
 					 sizeof(*master->ibi.slots),
 					 GFP_KERNEL);
-	if (!master->ibi.slots) {
-		ret = -ENOMEM;
-		goto err_disable_clks;
-	}
-
-	platform_set_drvdata(pdev, master);
-
-	pm_runtime_set_autosuspend_delay(&pdev->dev, SVC_I3C_PM_TIMEOUT_MS);
-	pm_runtime_use_autosuspend(&pdev->dev);
-	pm_runtime_get_noresume(&pdev->dev);
-	pm_runtime_set_active(&pdev->dev);
-	pm_runtime_enable(&pdev->dev);
+	if (!master->ibi.slots)
+		return -ENOMEM;
 
 	svc_i3c_master_reset(master);
 
 	/* Register the master */
 	ret = i3c_master_register(&master->base, &pdev->dev,
 				  &svc_i3c_master_ops, false);
-	if (ret)
-		goto rpm_disable;
-
-	pm_runtime_put_autosuspend(&pdev->dev);
-
-	return 0;
-
-rpm_disable:
-	pm_runtime_dont_use_autosuspend(&pdev->dev);
-	pm_runtime_put_noidle(&pdev->dev);
-	pm_runtime_disable(&pdev->dev);
-	pm_runtime_set_suspended(&pdev->dev);
-
-err_disable_clks:
-	clk_bulk_disable_unprepare(master->num_clks, master->clks);
 
 	return ret;
 }
-
-static void svc_i3c_master_remove(struct platform_device *pdev)
-{
-	struct svc_i3c_master *master = platform_get_drvdata(pdev);
-
-	i3c_master_unregister(&master->base);
-
-	pm_runtime_dont_use_autosuspend(&pdev->dev);
-	pm_runtime_disable(&pdev->dev);
-}
-
-static void svc_i3c_save_regs(struct svc_i3c_master *master)
-{
-	master->saved_regs.mconfig = readl(master->regs + SVC_I3C_MCONFIG);
-	master->saved_regs.mdynaddr = readl(master->regs + SVC_I3C_MDYNADDR);
-}
-
-static void svc_i3c_restore_regs(struct svc_i3c_master *master)
-{
-	if (readl(master->regs + SVC_I3C_MDYNADDR) !=
-	    master->saved_regs.mdynaddr) {
-		writel(master->saved_regs.mconfig,
-		       master->regs + SVC_I3C_MCONFIG);
-		writel(master->saved_regs.mdynaddr,
-		       master->regs + SVC_I3C_MDYNADDR);
-	}
-}
-
-static int __maybe_unused svc_i3c_runtime_suspend(struct device *dev)
-{
-	struct svc_i3c_master *master = dev_get_drvdata(dev);
-
-	svc_i3c_save_regs(master);
-	clk_bulk_disable_unprepare(master->num_clks, master->clks);
-	pinctrl_pm_select_sleep_state(dev);
-
-	return 0;
-}
-
-static int __maybe_unused svc_i3c_runtime_resume(struct device *dev)
-{
-	struct svc_i3c_master *master = dev_get_drvdata(dev);
-	int ret;
-
-	pinctrl_pm_select_default_state(dev);
-	ret = clk_bulk_prepare_enable(master->num_clks, master->clks);
-	if (ret)
-		return ret;
-
-	svc_i3c_restore_regs(master);
-
-	return 0;
-}
-
-static const struct dev_pm_ops svc_i3c_pm_ops = {
-	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend,
-				      pm_runtime_force_resume)
-	SET_RUNTIME_PM_OPS(svc_i3c_runtime_suspend,
-			   svc_i3c_runtime_resume, NULL)
-};
-
-static const struct svc_i3c_drvdata npcm845_drvdata = {
-	.quirks = SVC_I3C_QUIRK_FIFO_EMPTY |
-		SVC_I3C_QUIRK_FALSE_SLVSTART |
-		SVC_I3C_QUIRK_DAA_CORRUPT,
-};
-
-static const struct svc_i3c_drvdata svc_default_drvdata = {};
-
-static const struct of_device_id svc_i3c_master_of_match_tbl[] = {
-	{ .compatible = "nuvoton,npcm845-i3c", .data = &npcm845_drvdata },
-	{ .compatible = "silvaco,i3c-master-v1", .data = &svc_default_drvdata },
-	{ /* sentinel */ },
-};
-MODULE_DEVICE_TABLE(of, svc_i3c_master_of_match_tbl);
-
-static struct platform_driver svc_i3c_master = {
-	.probe = svc_i3c_master_probe,
-	.remove = svc_i3c_master_remove,
-	.driver = {
-		.name = "silvaco-i3c-master",
-		.of_match_table = svc_i3c_master_of_match_tbl,
-		.pm = &svc_i3c_pm_ops,
-	},
-};
-module_platform_driver(svc_i3c_master);
+EXPORT_SYMBOL_GPL(svc_i3c_master_probe);
 
 MODULE_AUTHOR("Conor Culhane <conor.culhane@silvaco.com>");
 MODULE_AUTHOR("Miquel Raynal <miquel.raynal@bootlin.com>");
diff --git a/drivers/i3c/master/svc/i3c-main.h b/drivers/i3c/master/svc/i3c-main.h
new file mode 100644
index 000000000..f72d9c26b
--- /dev/null
+++ b/drivers/i3c/master/svc/i3c-main.h
@@ -0,0 +1,297 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Silvaco dual-role I3C master driver
+ *
+ * Copyright (C) 2020 Silvaco
+ * Author: Miquel RAYNAL <miquel.raynal@bootlin.com>
+ * Based on a work from: Conor Culhane <conor.culhane@silvaco.com>
+ */
+
+#ifndef _SVC_I3C_MASTER_H_
+#define _SVC_I3C_MASTER_H_
+
+#include <linux/bitfield.h>
+#include <linux/clk.h>
+#include <linux/completion.h>
+#include <linux/errno.h>
+#include <linux/i3c/master.h>
+#include <linux/interrupt.h>
+#include <linux/iopoll.h>
+#include <linux/list.h>
+#include <linux/module.h>
+#include <linux/of.h>
+#include <linux/pinctrl/consumer.h>
+#include <linux/platform_device.h>
+#include <linux/pm_runtime.h>
+
+/* Master Mode Registers */
+#define SVC_I3C_MCONFIG      0x000
+#define   SVC_I3C_MCONFIG_MASTER_EN BIT(0)
+#define   SVC_I3C_MCONFIG_DISTO(x) FIELD_PREP(BIT(3), (x))
+#define   SVC_I3C_MCONFIG_HKEEP(x) FIELD_PREP(GENMASK(5, 4), (x))
+#define   SVC_I3C_MCONFIG_ODSTOP(x) FIELD_PREP(BIT(6), (x))
+#define   SVC_I3C_MCONFIG_PPBAUD(x) FIELD_PREP(GENMASK(11, 8), (x))
+#define   SVC_I3C_MCONFIG_PPLOW(x) FIELD_PREP(GENMASK(15, 12), (x))
+#define   SVC_I3C_MCONFIG_ODBAUD(x) FIELD_PREP(GENMASK(23, 16), (x))
+#define   SVC_I3C_MCONFIG_ODHPP(x) FIELD_PREP(BIT(24), (x))
+#define   SVC_I3C_MCONFIG_SKEW(x) FIELD_PREP(GENMASK(27, 25), (x))
+#define   SVC_I3C_MCONFIG_SKEW_MASK GENMASK(27, 25)
+#define   SVC_I3C_MCONFIG_I2CBAUD(x) FIELD_PREP(GENMASK(31, 28), (x))
+
+#define SVC_I3C_MCTRL        0x084
+#define   SVC_I3C_MCTRL_REQUEST_MASK GENMASK(2, 0)
+#define   SVC_I3C_MCTRL_REQUEST_NONE 0
+#define   SVC_I3C_MCTRL_REQUEST_START_ADDR 1
+#define   SVC_I3C_MCTRL_REQUEST_STOP 2
+#define   SVC_I3C_MCTRL_REQUEST_FORCE_EXIT 6
+#define   SVC_I3C_MCTRL_REQUEST_IBI_ACKNACK 3
+#define   SVC_I3C_MCTRL_REQUEST_PROC_DAA 4
+#define   SVC_I3C_MCTRL_REQUEST_AUTO_IBI 7
+#define   SVC_I3C_MCTRL_TYPE_I3C 0
+#define   SVC_I3C_MCTRL_TYPE_I2C BIT(4)
+#define   SVC_I3C_MCTRL_TYPE_DDR BIT(5)
+#define   SVC_I3C_MCTRL_IBIRESP_AUTO 0
+#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITHOUT_BYTE 0
+#define   SVC_I3C_MCTRL_IBIRESP_ACK_WITH_BYTE BIT(7)
+#define   SVC_I3C_MCTRL_IBIRESP_NACK BIT(6)
+#define   SVC_I3C_MCTRL_IBIRESP_MANUAL GENMASK(7, 6)
+#define   SVC_I3C_MCTRL_DIR(x) FIELD_PREP(BIT(8), (x))
+#define   SVC_I3C_MCTRL_DIR_WRITE 0
+#define   SVC_I3C_MCTRL_DIR_READ 1
+#define   SVC_I3C_MCTRL_ADDR(x) FIELD_PREP(GENMASK(15, 9), (x))
+#define   SVC_I3C_MCTRL_RDTERM(x) FIELD_PREP(GENMASK(23, 16), (x))
+
+#define SVC_I3C_MSTATUS      0x088
+#define   SVC_I3C_MSTATUS_STATE(x) FIELD_GET(GENMASK(2, 0), (x))
+#define   SVC_I3C_MSTATUS_STATE_DAA(x) (SVC_I3C_MSTATUS_STATE(x) == 5)
+#define   SVC_I3C_MSTATUS_STATE_SLVREQ(x) (SVC_I3C_MSTATUS_STATE(x) == 1)
+#define   SVC_I3C_MSTATUS_STATE_IDLE(x) (SVC_I3C_MSTATUS_STATE(x) == 0)
+#define   SVC_I3C_MSTATUS_BETWEEN(x) FIELD_GET(BIT(4), (x))
+#define   SVC_I3C_MSTATUS_NACKED(x) FIELD_GET(BIT(5), (x))
+#define   SVC_I3C_MSTATUS_IBITYPE(x) FIELD_GET(GENMASK(7, 6), (x))
+#define   SVC_I3C_MSTATUS_IBITYPE_IBI 1
+#define   SVC_I3C_MSTATUS_IBITYPE_MASTER_REQUEST 2
+#define   SVC_I3C_MSTATUS_IBITYPE_HOT_JOIN 3
+#define   SVC_I3C_MINT_SLVSTART BIT(8)
+#define   SVC_I3C_MINT_MCTRLDONE BIT(9)
+#define   SVC_I3C_MINT_COMPLETE BIT(10)
+#define   SVC_I3C_MINT_RXPEND BIT(11)
+#define   SVC_I3C_MINT_TXNOTFULL BIT(12)
+#define   SVC_I3C_MINT_IBIWON BIT(13)
+#define   SVC_I3C_MINT_ERRWARN BIT(15)
+#define   SVC_I3C_MSTATUS_SLVSTART(x) FIELD_GET(SVC_I3C_MINT_SLVSTART, (x))
+#define   SVC_I3C_MSTATUS_MCTRLDONE(x) FIELD_GET(SVC_I3C_MINT_MCTRLDONE, (x))
+#define   SVC_I3C_MSTATUS_COMPLETE(x) FIELD_GET(SVC_I3C_MINT_COMPLETE, (x))
+#define   SVC_I3C_MSTATUS_RXPEND(x) FIELD_GET(SVC_I3C_MINT_RXPEND, (x))
+#define   SVC_I3C_MSTATUS_TXNOTFULL(x) FIELD_GET(SVC_I3C_MINT_TXNOTFULL, (x))
+#define   SVC_I3C_MSTATUS_IBIWON(x) FIELD_GET(SVC_I3C_MINT_IBIWON, (x))
+#define   SVC_I3C_MSTATUS_ERRWARN(x) FIELD_GET(SVC_I3C_MINT_ERRWARN, (x))
+#define   SVC_I3C_MSTATUS_IBIADDR(x) FIELD_GET(GENMASK(30, 24), (x))
+
+#define SVC_I3C_IBIRULES     0x08C
+#define   SVC_I3C_IBIRULES_ADDR(slot, addr) FIELD_PREP(GENMASK(29, 0), \
+						       ((addr) & 0x3F) << ((slot) * 6))
+#define   SVC_I3C_IBIRULES_ADDRS 5
+#define   SVC_I3C_IBIRULES_MSB0 BIT(30)
+#define   SVC_I3C_IBIRULES_NOBYTE BIT(31)
+#define   SVC_I3C_IBIRULES_MANDBYTE 0
+#define SVC_I3C_MINTSET      0x090
+#define SVC_I3C_MINTCLR      0x094
+#define SVC_I3C_MINTMASKED   0x098
+#define SVC_I3C_MERRWARN     0x09C
+#define   SVC_I3C_MERRWARN_NACK BIT(2)
+#define   SVC_I3C_MERRWARN_CRC	BIT(10)
+#define   SVC_I3C_MERRWARN_TIMEOUT BIT(20)
+#define SVC_I3C_MDMACTRL     0x0A0
+#define SVC_I3C_MDATACTRL    0x0AC
+#define   SVC_I3C_MDATACTRL_FLUSHTB BIT(0)
+#define   SVC_I3C_MDATACTRL_FLUSHRB BIT(1)
+#define   SVC_I3C_MDATACTRL_UNLOCK_TRIG BIT(3)
+#define   SVC_I3C_MDATACTRL_TXTRIG_FIFO_NOT_FULL GENMASK(5, 4)
+#define   SVC_I3C_MDATACTRL_RXTRIG_FIFO_NOT_EMPTY 0
+#define   SVC_I3C_MDATACTRL_RXCOUNT(x) FIELD_GET(GENMASK(28, 24), (x))
+#define   SVC_I3C_MDATACTRL_TXCOUNT(x) FIELD_GET(GENMASK(20, 16), (x))
+#define   SVC_I3C_MDATACTRL_TXFULL BIT(30)
+#define   SVC_I3C_MDATACTRL_RXEMPTY BIT(31)
+
+#define SVC_I3C_MWDATAB      0x0B0
+#define   SVC_I3C_MWDATAB_END BIT(8)
+
+#define SVC_I3C_MWDATABE     0x0B4
+#define SVC_I3C_MWDATAH      0x0B8
+#define SVC_I3C_MWDATAHE     0x0BC
+#define SVC_I3C_MRDATAB      0x0C0
+#define SVC_I3C_MRDATAH      0x0C8
+#define SVC_I3C_MWDATAB1     0x0CC
+#define SVC_I3C_MWMSG_SDR    0x0D0
+#define SVC_I3C_MRMSG_SDR    0x0D4
+#define SVC_I3C_MWMSG_DDR    0x0D8
+#define SVC_I3C_MRMSG_DDR    0x0DC
+
+#define SVC_I3C_MDYNADDR     0x0E4
+#define   SVC_MDYNADDR_VALID BIT(0)
+#define   SVC_MDYNADDR_ADDR(x) FIELD_PREP(GENMASK(7, 1), (x))
+
+#define SVC_I3C_MAX_DEVS 32
+#define SVC_I3C_PM_TIMEOUT_MS 1000
+
+/* This parameter depends on the implementation and may be tuned */
+#define SVC_I3C_FIFO_SIZE 16
+#define SVC_I3C_PPBAUD_MAX 15
+#define SVC_I3C_QUICK_I2C_CLK 4170000
+
+#define SVC_I3C_EVENT_IBI	GENMASK(7, 0)
+#define SVC_I3C_EVENT_HOTJOIN	BIT(31)
+
+/*
+ * SVC_I3C_QUIRK_FIFO_EMPTY:
+ * I3C HW stalls the write transfer if the transmit FIFO becomes empty,
+ * when new data is written to FIFO, I3C HW resumes the transfer but
+ * the first transmitted data bit may have the wrong value.
+ * Workaround:
+ * Fill the FIFO in advance to prevent FIFO from becoming empty.
+ */
+#define SVC_I3C_QUIRK_FIFO_EMPTY	BIT(0)
+/*
+ * SVC_I3C_QUIRK_FLASE_SLVSTART:
+ * I3C HW may generate an invalid SlvStart event when emitting a STOP.
+ * If it is a true SlvStart, the MSTATUS state is SLVREQ.
+ */
+#define SVC_I3C_QUIRK_FALSE_SLVSTART	BIT(1)
+/*
+ * SVC_I3C_QUIRK_DAA_CORRUPT:
+ * When MCONFIG.SKEW=0 and MCONFIG.ODHPP=0, the ENTDAA transaction gets
+ * corrupted and results in a no repeated-start condition at the end of
+ * address assignment.
+ * Workaround:
+ * Set MCONFIG.SKEW to 1 before initiating the DAA process. After the DAA
+ * process is completed, return MCONFIG.SKEW to its previous value.
+ */
+#define SVC_I3C_QUIRK_DAA_CORRUPT	BIT(2)
+
+struct svc_i3c_cmd {
+	u8 addr;
+	union {
+		bool rnw;
+		u8 cmd;
+		u32 rnw_cmd;
+	};
+	u8 *in;
+	const void *out;
+	unsigned int len;
+	unsigned int actual_len;
+	struct i3c_xfer *xfer;
+	bool continued;
+};
+
+struct svc_i3c_xfer {
+	struct list_head node;
+	struct completion comp;
+	int ret;
+	unsigned int type;
+	unsigned int ncmds;
+	struct svc_i3c_cmd cmds[] __counted_by(ncmds);
+};
+
+struct svc_i3c_regs_save {
+	u32 mconfig;
+	u32 mdynaddr;
+};
+
+struct svc_i3c_drvdata {
+	u32 quirks;
+	const void *bsp_data;
+};
+
+/**
+ * struct svc_i3c_master - Silvaco I3C Master structure
+ * @base: I3C master controller
+ * @dev: Corresponding device
+ * @regs: Memory mapping
+ * @saved_regs: Volatile values for PM operations
+ * @free_slots: Bit array of available slots
+ * @addrs: Array containing the dynamic addresses of each attached device
+ * @descs: Array of descriptors, one per attached device
+ * @irq: Main interrupt
+ * @fclk_rate: Fast clock (bus) rate, in Hz, set by the glue layer
+ * @bsp_priv: Private data owned by the glue layer
+ * @xferqueue: Transfer queue structure
+ * @xferqueue.list: List member
+ * @xferqueue.cur: Current ongoing transfer
+ * @xferqueue.lock: Queue lock
+ * @ibi: IBI structure
+ * @ibi.num_slots: Number of slots available in @ibi.slots
+ * @ibi.slots: Available IBI slots
+ * @ibi.tbq_slot: To be queued IBI slot
+ * @ibi.lock: IBI lock
+ * @lock: Transfer lock, protect between IBI work thread and callbacks from master
+ * @drvdata: Driver data
+ * @enabled_events: Bit masks for enable events (IBI, HotJoin).
+ * @mctrl_config: Configuration value in SVC_I3C_MCTRL for setting speed back.
+ */
+struct svc_i3c_master {
+	struct i3c_master_controller base;
+	struct device *dev;
+	void __iomem *regs;
+	struct svc_i3c_regs_save saved_regs;
+	u32 free_slots;
+	u8 addrs[SVC_I3C_MAX_DEVS];
+	struct i3c_dev_desc *descs[SVC_I3C_MAX_DEVS];
+	int irq;
+	unsigned long fclk_rate;
+	void *bsp_priv;
+	struct {
+		struct list_head list;
+		struct svc_i3c_xfer *cur;
+		/* Prevent races between transfers */
+		spinlock_t lock;
+	} xferqueue;
+	struct {
+		unsigned int num_slots;
+		struct i3c_dev_desc **slots;
+		struct i3c_ibi_slot *tbq_slot;
+		/* Prevent races within IBI handlers */
+		spinlock_t lock;
+	} ibi;
+	struct mutex lock;
+	const struct svc_i3c_drvdata *drvdata;
+	u32 enabled_events;
+	u32 mctrl_config;
+};
+
+/**
+ * struct svc_i3c_i2c_dev_data - Device specific data
+ * @index: Index in the master tables corresponding to this device
+ * @ibi: IBI slot index in the master structure
+ * @ibi_pool: IBI pool associated to this device
+ */
+struct svc_i3c_i2c_dev_data {
+	u8 index;
+	int ibi;
+	struct i3c_generic_ibi_pool *ibi_pool;
+};
+
+static inline bool svc_has_quirk(struct svc_i3c_master *master, u32 quirk)
+{
+	return (master->drvdata->quirks & quirk);
+}
+
+static inline bool svc_has_daa_corrupt(struct svc_i3c_master *master)
+{
+	return ((master->drvdata->quirks & SVC_I3C_QUIRK_DAA_CORRUPT) &&
+		!(master->mctrl_config &
+		(SVC_I3C_MCONFIG_SKEW_MASK | SVC_I3C_MCONFIG_ODHPP(1))));
+}
+
+static inline bool is_events_enabled(struct svc_i3c_master *master, u32 mask)
+{
+	return !!(master->enabled_events & mask);
+}
+
+void svc_i3c_save_regs(struct svc_i3c_master *master);
+void svc_i3c_restore_regs(struct svc_i3c_master *master);
+struct svc_i3c_master *svc_i3c_master_alloc(struct device *dev);
+void svc_i3c_master_remove(struct svc_i3c_master *master);
+int svc_i3c_master_probe(struct platform_device *pdev, struct svc_i3c_master *master);
+
+#endif /* _SVC_I3C_MASTER_H_ */
diff --git a/drivers/i3c/master/svc/i3c-silvaco.c b/drivers/i3c/master/svc/i3c-silvaco.c
new file mode 100644
index 000000000..da2fc1560
--- /dev/null
+++ b/drivers/i3c/master/svc/i3c-silvaco.c
@@ -0,0 +1,173 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Silvaco dual-role I3C master driver
+ *
+ * Copyright (C) 2020 Silvaco
+ * Author: Miquel RAYNAL <miquel.raynal@bootlin.com>
+ * Based on a work from: Conor Culhane <conor.culhane@silvaco.com>
+ */
+#include "i3c-main.h"
+
+struct svc_origin_priv {
+	int num_clks;
+	struct clk_bulk_data *clks;
+};
+
+static int silvaco_i3c_probe(struct platform_device *pdev)
+{
+	struct device *dev = &pdev->dev;
+	struct svc_i3c_master *master;
+	struct svc_origin_priv *priv;
+	int ret, i;
+
+	master = svc_i3c_master_alloc(dev);
+	if (!master)
+		return -ENOMEM;
+
+	priv = devm_kzalloc(dev, sizeof(*priv), GFP_KERNEL);
+	if (!priv)
+		return -ENOMEM;
+
+	master->drvdata = of_device_get_match_data(dev);
+	if (!master->drvdata)
+		return -EINVAL;
+
+	master->regs = devm_platform_ioremap_resource(pdev, 0);
+	if (IS_ERR(master->regs))
+		return PTR_ERR(master->regs);
+
+	master->irq = platform_get_irq(pdev, 0);
+	if (master->irq < 0)
+		return master->irq;
+
+	priv->num_clks = devm_clk_bulk_get_all(dev, &priv->clks);
+	if (priv->num_clks < 0)
+		return dev_err_probe(dev, -EINVAL, "can't get I3C clocks\n");
+
+	for (i = 0; i < priv->num_clks; i++) {
+		if (!strcmp(priv->clks[i].id, "fast_clk"))
+			break;
+	}
+
+	if (i == priv->num_clks)
+		return dev_err_probe(dev, -EINVAL,
+				     "can't get I3C peripheral clock\n");
+
+	if (IS_ERR(priv->clks[i].clk))
+		return PTR_ERR(priv->clks[i].clk);
+
+	ret = clk_bulk_prepare_enable(priv->num_clks, priv->clks);
+	if (ret)
+		return dev_err_probe(dev, ret, "can't enable I3C clocks\n");
+
+	master->dev = dev;
+	master->bsp_priv = priv;
+	master->fclk_rate = clk_get_rate(priv->clks[i].clk);
+	if (!master->fclk_rate) {
+		dev_err(dev, "can't get I3C fast clock rate\n");
+		ret = -EINVAL;
+		goto err_disable_clks;
+	}
+
+	pm_runtime_set_autosuspend_delay(dev, SVC_I3C_PM_TIMEOUT_MS);
+	pm_runtime_use_autosuspend(dev);
+	pm_runtime_get_noresume(dev);
+	pm_runtime_set_active(dev);
+	pm_runtime_enable(dev);
+
+	ret = svc_i3c_master_probe(pdev, master);
+	if (ret)
+		goto rpm_disable;
+
+	platform_set_drvdata(pdev, master);
+	pm_runtime_put_autosuspend(dev);
+
+	return 0;
+
+rpm_disable:
+	pm_runtime_dont_use_autosuspend(dev);
+	pm_runtime_put_noidle(dev);
+	pm_runtime_disable(dev);
+	pm_runtime_set_suspended(dev);
+
+err_disable_clks:
+	clk_bulk_disable_unprepare(priv->num_clks, priv->clks);
+
+	return ret;
+}
+
+static void silvaco_i3c_remove(struct platform_device *pdev)
+{
+	struct svc_i3c_master *master = platform_get_drvdata(pdev);
+
+	svc_i3c_master_remove(master);
+
+	pm_runtime_dont_use_autosuspend(&pdev->dev);
+	pm_runtime_disable(&pdev->dev);
+}
+
+static int __maybe_unused silvaco_i3c_runtime_suspend(struct device *dev)
+{
+	struct svc_i3c_master *master = dev_get_drvdata(dev);
+	struct svc_origin_priv *priv = master->bsp_priv;
+
+	svc_i3c_save_regs(master);
+	clk_bulk_disable_unprepare(priv->num_clks, priv->clks);
+	pinctrl_pm_select_sleep_state(dev);
+
+	return 0;
+}
+
+static int __maybe_unused silvaco_i3c_runtime_resume(struct device *dev)
+{
+	struct svc_i3c_master *master = dev_get_drvdata(dev);
+	struct svc_origin_priv *priv = master->bsp_priv;
+	int ret;
+
+	pinctrl_pm_select_default_state(dev);
+	ret = clk_bulk_prepare_enable(priv->num_clks, priv->clks);
+	if (ret)
+		return ret;
+
+	svc_i3c_restore_regs(master);
+
+	return 0;
+}
+
+static const struct dev_pm_ops silvaco_i3c_pm_ops = {
+	SET_NOIRQ_SYSTEM_SLEEP_PM_OPS(pm_runtime_force_suspend,
+				      pm_runtime_force_resume)
+	SET_RUNTIME_PM_OPS(silvaco_i3c_runtime_suspend,
+			   silvaco_i3c_runtime_resume, NULL)
+};
+
+static const struct svc_i3c_drvdata npcm845_drvdata = {
+	.quirks = SVC_I3C_QUIRK_FIFO_EMPTY |
+		SVC_I3C_QUIRK_FALSE_SLVSTART |
+		SVC_I3C_QUIRK_DAA_CORRUPT,
+};
+
+static const struct svc_i3c_drvdata svc_default_drvdata = {};
+
+static const struct of_device_id svc_i3c_master_of_match_tbl[] = {
+	{ .compatible = "nuvoton,npcm845-i3c", .data = &npcm845_drvdata },
+	{ .compatible = "silvaco,i3c-master-v1", .data = &svc_default_drvdata },
+	{ /* sentinel */ },
+};
+MODULE_DEVICE_TABLE(of, svc_i3c_master_of_match_tbl);
+
+static struct platform_driver silvaco_i3c_driver = {
+	.probe = silvaco_i3c_probe,
+	.remove = silvaco_i3c_remove,
+	.driver = {
+		.name = "silvaco-i3c-master",
+		.of_match_table = svc_i3c_master_of_match_tbl,
+		.pm = &silvaco_i3c_pm_ops,
+	},
+};
+module_platform_driver(silvaco_i3c_driver);
+
+MODULE_AUTHOR("Conor Culhane <conor.culhane@silvaco.com>");
+MODULE_AUTHOR("Miquel Raynal <miquel.raynal@bootlin.com>");
+MODULE_DESCRIPTION("Silvaco dual-role I3C master driver");
+MODULE_LICENSE("GPL v2");

-- 
2.42.0

