From: Matt Thompson <matt@boondocker.io>
Date: Mon, 16 Nov 2026 02:35:47 -0700
Subject: [PATCH RFC v3 5/6] PCI: rockchip-host: Defer retraining during
 initial link training
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rfc-b4-v3-5-0bf052b68f2a@boondocker.io>
References: <20261116-rfc-b4-v3-0-0bf052b68f2a@boondocker.io>
In-Reply-To: <20261116-rfc-b4-v3-0-0bf052b68f2a@boondocker.io>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794821744; l=4671;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=KUXpKSAKyk225bpT79IH2hk0YJswSkRu8Uhog5/Ier8=;
 b=sNVtW5seraedhdRLtk/01tgNfKXot3Oe0ZrNnzO7kxnYpnZRc9MJhR0eFYN8XN15mSkDH8B5P
 iKpB8swdS4NCD8ogtJv+gkpNAEPatfYGTf7msQ1lNr7PkDL9KlitTKG
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clearing Link Disable starts initial training. A retrain request can
arrive while the PHY is still in Detect, when it cannot recover a data
link that later stalls in initialization. On RockPro64 the link could
reach L0 while the data link remained unable to pass configuration
traffic.

Remember an early request and give initialization 50 ms to finish.
If a later downstream access finds the PHY ready with data link
initialization still pending, issue the saved request once and leave
configuration access blocked until the data link becomes ready.

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 drivers/pci/controller/pcie-rockchip-host.c | 45 +++++++++++++++++++++++++++--
 drivers/pci/controller/pcie-rockchip.h      |  3 ++
 2 files changed, 46 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 64ac6f4..d6c494f 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -19,6 +19,7 @@
 #include <linux/irq.h>
 #include <linux/irqchip/chained_irq.h>
 #include <linux/irqdomain.h>
+#include <linux/jiffies.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/of_pci.h>
@@ -123,11 +124,28 @@ static int rockchip_pcie_wr_own_conf(struct rockchip_pcie *rockchip,
 				     int where, int size, u32 val)
 {
 	u32 mask, tmp, offset;
+	bool link_control = where == 0xc0 + PCI_EXP_LNKCTL;
 	void __iomem *addr;
 
 	offset = where & ~0x3;
 	addr = rockchip->apb_base + PCIE_RC_CONFIG_NORMAL_BASE + offset;
 
+	/*
+	 * Let the PHY finish initial training after Link Disable is cleared.
+	 * Retain a request made during this phase in case the data link does
+	 * not finish initializing on its own.
+	 */
+	if (link_control && (val & PCI_EXP_LNKCTL_LD)) {
+		rockchip->retrain_pending = false;
+	} else if (link_control && (val & PCI_EXP_LNKCTL_RL)) {
+		rockchip->retrain_pending = false;
+		if (!PCIE_LINK_TRAINING_DONE(rockchip_pcie_read(rockchip, PCIE_CORE_CTRL))) {
+			rockchip->retrain_pending = true;
+			rockchip->retrain_after = jiffies + msecs_to_jiffies(50);
+			val &= ~PCI_EXP_LNKCTL_RL;
+		}
+	}
+
 	if (size == 4) {
 		writel(val, addr);
 		return PCIBIOS_SUCCESSFUL;
@@ -149,8 +167,29 @@ static int rockchip_pcie_wr_own_conf(struct rockchip_pcie *rockchip,
 
 static bool rockchip_pcie_downstream_ready(struct rockchip_pcie *rockchip)
 {
-	return PCIE_LINK_UP(rockchip_pcie_read(rockchip, PCIE_CLIENT_BASIC_STATUS1)) &&
-	       PCIE_LINK_TRAINING_DONE(rockchip_pcie_read(rockchip, PCIE_CORE_CTRL));
+	u32 status = rockchip_pcie_read(rockchip, PCIE_CLIENT_BASIC_STATUS1);
+	u32 core = rockchip_pcie_read(rockchip, PCIE_CORE_CTRL);
+	u32 control;
+
+	if (!PCIE_LINK_TRAINING_DONE(core))
+		return false;
+	if (PCIE_LINK_UP(status)) {
+		rockchip->retrain_pending = false;
+		return true;
+	}
+
+	if (rockchip->retrain_pending &&
+	    time_after_eq(jiffies, rockchip->retrain_after) &&
+	    (status & PCIE_CLIENT_LINK_STATUS_MASK) == PCIE_CLIENT_LINK_STATUS_DL_INIT) {
+		rockchip->retrain_pending = false;
+		rockchip_pcie_rd_own_conf(rockchip, 0xc0 + PCI_EXP_LNKCTL, 2, &control);
+		if (!(control & PCI_EXP_LNKCTL_LD)) {
+			rockchip_pcie_wr_own_conf(rockchip, 0xc0 + PCI_EXP_LNKCTL, 2,
+						  control | PCI_EXP_LNKCTL_RL);
+		}
+	}
+
+	return false;
 }
 
 #ifdef CONFIG_ARM64
@@ -914,6 +953,8 @@ static int rockchip_pcie_suspend_noirq(struct device *dev)
 	struct rockchip_pcie *rockchip = dev_get_drvdata(dev);
 	int ret;
 
+	rockchip->retrain_pending = false;
+
 	/* disable core and cli int since we don't need to ack PME_ACK */
 	rockchip_pcie_write(rockchip, (PCIE_CLIENT_INT_CLI << 16) |
 			    PCIE_CLIENT_INT_CLI, PCIE_CLIENT_INT_MASK);
diff --git a/drivers/pci/controller/pcie-rockchip.h b/drivers/pci/controller/pcie-rockchip.h
index 1cc3621..5fdd06b 100644
--- a/drivers/pci/controller/pcie-rockchip.h
+++ b/drivers/pci/controller/pcie-rockchip.h
@@ -58,6 +58,7 @@
 #define   PCIE_CLIENT_NEG_LINK_WIDTH_SHIFT	6
 #define   PCIE_CLIENT_NEG_LINK_SPEED		BIT(5)
 #define PCIE_CLIENT_BASIC_STATUS1	(PCIE_CLIENT_BASE + 0x48)
+#define   PCIE_CLIENT_LINK_STATUS_DL_INIT	0x00200000
 #define   PCIE_CLIENT_LINK_STATUS_UP		0x00300000
 #define   PCIE_CLIENT_LINK_STATUS_MASK		0x00300000
 #define PCIE_CLIENT_INT_MASK		(PCIE_CLIENT_BASE + 0x4c)
@@ -325,6 +326,8 @@ struct rockchip_pcie {
 	void    __iomem *msg_region;
 	phys_addr_t msg_bus_addr;
 	bool is_rc;
+	bool retrain_pending;
+	unsigned long retrain_after;
 	struct resource *mem_res;
 };
 

-- 
Git-155)

