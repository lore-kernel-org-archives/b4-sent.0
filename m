From: Matt Thompson <matt@boondocker.io>
Date: Fri, 13 Nov 2026 17:28:51 -0700
Subject: [PATCH RFC 3/3] PCI: rockchip-host: Recover downstream
 configuration access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-rfc-b4-v1-3-b91dcb502250@boondocker.io>
References: <20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io>
In-Reply-To: <20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794616129; l=5010;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=wf8dMR8QRs/deeBcDxOpgy/o2/ItJSjrMfmmN+jiJf4=;
 b=YWXdzf81bKPE8glX2Xr4f/8+pdN5eFimU1YqRjUDLikrUAaAjQN9/8SimiKGpNYl33QZ+WXq5
 XvFWHdFWPOfBpkvBPBPH2OYS7cix7Em95CMHKNSQMhGFrKSDIiBoWSq
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The link status can change between the readiness check and a downstream
PCI configuration read. A link that reports up can also fail to return
a usable completion.

On arm64, annotate downstream loads for all three access widths so a
synchronous external abort returns PCIBIOS_DEVICE_NOT_FOUND with all-ones
data. Keep little-endian conversion and I/O read ordering on success.

After retraining, the controller can continue to block configuration
traffic until its AXI link-down latch is cleared. Clear the latch before
downstream config reads and writes once the link readiness checks pass.

Link: https://lore.kernel.org/linux-pci/20261024-rockchip-pcie-resume-v1-2-58e54a5cf5f1@iav.lv/

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 drivers/pci/controller/pcie-rockchip-host.c | 63 +++++++++++++++++++++++++++--
 drivers/pci/controller/pcie-rockchip.h      |  1 +
 2 files changed, 60 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 35105c1..64c7da5 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -29,6 +29,10 @@
 #include "../pci.h"
 #include "pcie-rockchip.h"
 
+#ifdef CONFIG_ARM64
+#include <asm/asm-extable.h>
+#endif
+
 static void rockchip_pcie_enable_bw_int(struct rockchip_pcie *rockchip)
 {
 	u32 status;
@@ -149,16 +153,37 @@ static bool rockchip_pcie_downstream_ready(struct rockchip_pcie *rockchip)
 	       PCIE_LINK_TRAINING_DONE(rockchip_pcie_read(rockchip, PCIE_CORE_CTRL));
 }
 
+#ifdef CONFIG_ARM64
+/*
+ * An absent completion can raise a synchronous external abort even when
+ * the link status indicated up immediately before the config transaction.
+ */
+#define rockchip_pcie_cfg_load(insn, addr, val)			\
+	({								\
+		int err = 0;					\
+		asm volatile(__DEFINE_ASM_GPR_NUMS			\
+			     "1: " #insn " %w0, [%2]\n"			\
+			     "2:\n"					\
+			     _ASM_EXTABLE_MMIO_READ_ERR_ZERO("1b", "2b",	\
+							    "%w1", "%w0")	\
+			     : "=&r" (val), "+r" (err)			\
+			     : "r" (addr) : "memory");			\
+		err;							\
+	})
+#endif
+
 static int rockchip_pcie_rd_other_conf(struct rockchip_pcie *rockchip,
 				       struct pci_bus *bus, u32 devfn,
 				       int where, int size, u32 *val)
 {
 	void __iomem *addr;
+#ifdef CONFIG_ARM64
+	u32 data;
+	int err;
+#endif
 
-	if (!rockchip_pcie_downstream_ready(rockchip)) {
-		*val = ~0U;
-		return PCIBIOS_DEVICE_NOT_FOUND;
-	}
+	if (!rockchip_pcie_downstream_ready(rockchip))
+		goto absent;
 
 	addr = rockchip->reg_base + PCIE_ECAM_OFFSET(bus->number, devfn, where);
 
@@ -174,6 +199,28 @@ static int rockchip_pcie_rd_other_conf(struct rockchip_pcie *rockchip,
 		rockchip_pcie_cfg_configuration_accesses(rockchip,
 						AXI_WRAPPER_TYPE1_CFG);
 
+	/* Clear the AXI link-down latch before downstream config traffic. */
+	rockchip_pcie_write(rockchip, 0, PCIE_CORE_AXI_LINK_DOWN);
+
+#ifdef CONFIG_ARM64
+	if (size == 4) {
+		err = rockchip_pcie_cfg_load(ldr, addr, data);
+		*val = le32_to_cpu((__force __le32)data);
+	} else if (size == 2) {
+		err = rockchip_pcie_cfg_load(ldrh, addr, data);
+		*val = le16_to_cpu((__force __le16)data);
+	} else if (size == 1) {
+		err = rockchip_pcie_cfg_load(ldrb, addr, data);
+		*val = data;
+	} else {
+		*val = 0;
+		return PCIBIOS_BAD_REGISTER_NUMBER;
+	}
+	if (err)
+		goto absent;
+	/* Preserve the I/O read ordering of readl/readw/readb. */
+	__io_ar(*val);
+#else
 	if (size == 4) {
 		*val = readl(addr);
 	} else if (size == 2) {
@@ -184,7 +231,12 @@ static int rockchip_pcie_rd_other_conf(struct rockchip_pcie *rockchip,
 		*val = 0;
 		return PCIBIOS_BAD_REGISTER_NUMBER;
 	}
+#endif
 	return PCIBIOS_SUCCESSFUL;
+
+absent:
+	*val = ~0U;
+	return PCIBIOS_DEVICE_NOT_FOUND;
 }
 
 static int rockchip_pcie_wr_other_conf(struct rockchip_pcie *rockchip,
@@ -208,6 +260,9 @@ static int rockchip_pcie_wr_other_conf(struct rockchip_pcie *rockchip,
 		rockchip_pcie_cfg_configuration_accesses(rockchip,
 						AXI_WRAPPER_TYPE1_CFG);
 
+	/* Clear the AXI link-down latch before downstream config traffic. */
+	rockchip_pcie_write(rockchip, 0, PCIE_CORE_AXI_LINK_DOWN);
+
 	if (size == 4)
 		writel(val, addr);
 	else if (size == 2)
diff --git a/drivers/pci/controller/pcie-rockchip.h b/drivers/pci/controller/pcie-rockchip.h
index b5da156..1cc3621 100644
--- a/drivers/pci/controller/pcie-rockchip.h
+++ b/drivers/pci/controller/pcie-rockchip.h
@@ -164,6 +164,7 @@
 #define MIN_AXI_ADDR_BITS_PASSED		8
 #define PCIE_ADDR_MASK			GENMASK_ULL(63, MIN_AXI_ADDR_BITS_PASSED)
 #define PCIE_CORE_AXI_CONF_BASE		0xc00000
+#define PCIE_CORE_AXI_LINK_DOWN		(PCIE_CORE_AXI_CONF_BASE + 0x824)
 #define PCIE_CORE_OB_REGION_ADDR0	(PCIE_CORE_AXI_CONF_BASE + 0x0)
 #define   PCIE_CORE_OB_REGION_ADDR0_NUM_BITS	0x3f
 #define   PCIE_CORE_OB_REGION_ADDR0_LO_ADDR	PCIE_ADDR_MASK

-- 
Git-155)

