From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 22 Sep 2025 21:46:44 +0530
Subject: [PATCH v2 1/2] PCI/ASPM: Override the ASPM and Clock PM states set
 by BIOS for devicetree platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250922-pci-dt-aspm-v2-1-2a65cf84e326@oss.qualcomm.com>
References: <20250922-pci-dt-aspm-v2-0-2a65cf84e326@oss.qualcomm.com>
In-Reply-To: <20250922-pci-dt-aspm-v2-0-2a65cf84e326@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "David E. Box" <david.e.box@linux.intel.com>, 
 Kai-Heng Feng <kai.heng.feng@canonical.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Chia-Lin Kao <acelan.kao@canonical.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bjorn Helgaas <helgaas@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6329;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zOY/YZNFZgYDJqgX5yqfztyJ+9R+sQwSgHsfQBHv6p0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBo0XZ0SjjmwAGqE8BXfPlpBPUHmvkTYg+5DT2LD
 Xm4YdqjzEmJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaNF2dAAKCRBVnxHm/pHO
 9Ym+B/wOCDXEuLOwpseiw93QczJKiKKJRiH5FfWdXZpkcC1w948wqyZGk43A1VVk+aE0Likim6v
 Fml+hnqtQo9B7tfCEvNYNshYNHCGsyssr0VYOYPkwPg7ju7Y8Lbg+fEhn/39I1oH7FpT/JyQv6C
 ctfPr4VIjzJRU2QIkGDB70jDvdqRlAkPqcb0XA3PSEER9kDcykJK5srYA+wL0tfqwh1Rp1lR3sD
 nbkkzmmaFvnxmZjc2QsBKO1tiKTn2NbgodSVFPlrtYewxNkd74sfK+gSE1uM9iEaKnN7yh8O/oZ
 g/RBZ3KufcKgh7N6piZVC0B6RF+3osPJlmGL9Ozu5Dn+yvM2
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, the PCI subsystem has honored the ASPM and Clock PM states set by
the BIOS (through LNKCTL) during device initialization, if it relies on the
default state selected using:

* Kconfig: CONFIG_PCIEASPM_DEFAULT=y, or
* cmdline: "pcie_aspm=off", or
* FADT: ACPI_FADT_NO_ASPM

This was done conservatively to avoid issues with the buggy devices that
advertise ASPM capabilities, but behave erratically if the ASPM states are
enabled. So the PCI subsystem ended up trusting the BIOS to enable only the
ASPM states that were known to work for the devices.

But this turned out to be a problem for devicetree platforms, especially
the ARM based devicetree platforms powering Embedded and *some* Compute
devices as they tend to run without any standard BIOS. So the ASPM states
on these platforms were left disabled during boot and the PCI subsystem
never bothered to enable them, unless the user has forcefully enabled the
ASPM states through Kconfig, cmdline, and sysfs or the device drivers
themselves, enabling the ASPM states through pci_enable_link_state() APIs.

This caused runtime power issues on those platforms. So a couple of
approaches were tried to mitigate this BIOS dependency without user
intervention by enabling the ASPM states in the PCI controller drivers
after device enumeration, and overriding the ASPM/Clock PM states
by the PCI controller drivers through an API before enumeration.

But it has been concluded that none of these mitigations should really be
required and the PCI subsystem should enable the ASPM states advertised by
the devices without relying on BIOS or the PCI controller drivers. If any
device is found to be misbehaving after enabling ASPM states that they
advertised, then those devices should be quirked to disable the problematic
ASPM/Clock PM states.

In an effort to do so, start by overriding the ASPM and Clock PM states set
by the BIOS for devicetree platforms first. Separate helper functions are
introduced to override the BIOS set states by enabling all of them if
of_have_populated_dt() returns true. To aid debugging, print the overridden
ASPM and Clock PM states as well.

In the future, these helpers could be extended to allow other platforms
like VMD, newer ACPI systems with a cutoff year etc... to follow the path.

Link: https://lore.kernel.org/linux-pci/20250828204345.GA958461@bhelgaas
Suggested-by: Bjorn Helgaas <helgaas@kernel.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Link: https://patch.msgid.link/20250916-pci-dt-aspm-v1-1-778fe907c9ad@oss.qualcomm.com
---
 drivers/pci/pcie/aspm.c | 42 ++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 40 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 919a05b9764791c3cc469c9ada62ba5b2c405118..cda31150aec1b67b6a48b60569222ea3d1c3d41f 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -15,6 +15,7 @@
 #include <linux/math.h>
 #include <linux/module.h>
 #include <linux/moduleparam.h>
+#include <linux/of.h>
 #include <linux/pci.h>
 #include <linux/pci_regs.h>
 #include <linux/errno.h>
@@ -235,13 +236,15 @@ struct pcie_link_state {
 	u32 aspm_support:7;		/* Supported ASPM state */
 	u32 aspm_enabled:7;		/* Enabled ASPM state */
 	u32 aspm_capable:7;		/* Capable ASPM state with latency */
-	u32 aspm_default:7;		/* Default ASPM state by BIOS */
+	u32 aspm_default:7;		/* Default ASPM state by BIOS or
+					   override */
 	u32 aspm_disable:7;		/* Disabled ASPM state */
 
 	/* Clock PM state */
 	u32 clkpm_capable:1;		/* Clock PM capable? */
 	u32 clkpm_enabled:1;		/* Current Clock PM state */
-	u32 clkpm_default:1;		/* Default Clock PM state by BIOS */
+	u32 clkpm_default:1;		/* Default Clock PM state by BIOS or
+					   override */
 	u32 clkpm_disable:1;		/* Clock PM disabled */
 };
 
@@ -373,6 +376,18 @@ static void pcie_set_clkpm(struct pcie_link_state *link, int enable)
 	pcie_set_clkpm_nocheck(link, enable);
 }
 
+static void pcie_clkpm_override_default_link_state(struct pcie_link_state *link,
+						   int enabled)
+{
+	struct pci_dev *pdev = link->downstream;
+
+	/* Override the BIOS disabled Clock PM state for devicetree platforms */
+	if (of_have_populated_dt() && !enabled) {
+		link->clkpm_default = 1;
+		pci_info(pdev, "Clock PM state overridden: ClockPM+\n");
+	}
+}
+
 static void pcie_clkpm_cap_init(struct pcie_link_state *link, int blacklist)
 {
 	int capable = 1, enabled = 1;
@@ -395,6 +410,7 @@ static void pcie_clkpm_cap_init(struct pcie_link_state *link, int blacklist)
 	}
 	link->clkpm_enabled = enabled;
 	link->clkpm_default = enabled;
+	pcie_clkpm_override_default_link_state(link, enabled);
 	link->clkpm_capable = capable;
 	link->clkpm_disable = blacklist ? 1 : 0;
 }
@@ -788,6 +804,26 @@ static void aspm_l1ss_init(struct pcie_link_state *link)
 		aspm_calc_l12_info(link, parent_l1ss_cap, child_l1ss_cap);
 }
 
+static void pcie_aspm_override_default_link_state(struct pcie_link_state *link)
+{
+	struct pci_dev *pdev = link->downstream;
+	u32 override;
+
+	/* Override the BIOS disabled ASPM states for devicetree platforms */
+	if (of_have_populated_dt()) {
+		link->aspm_default = PCIE_LINK_STATE_ASPM_ALL;
+		override = link->aspm_default & ~link->aspm_enabled;
+		if (override)
+			pci_info(pdev, "ASPM states overridden: %s%s%s%s%s%s\n",
+				 (override & PCIE_LINK_STATE_L0S) ? "L0s+, " : "",
+				 (override & PCIE_LINK_STATE_L1) ? "L1+, " : "",
+				 (override & PCIE_LINK_STATE_L1_1) ? "L1.1+, " : "",
+				 (override & PCIE_LINK_STATE_L1_2) ? "L1.2+, " : "",
+				 (override & PCIE_LINK_STATE_L1_1_PCIPM) ? "L1.1 PCI-PM+, " : "",
+				 (override & PCIE_LINK_STATE_L1_2_PCIPM) ? "L1.2 PCI-PM+" : "");
+	}
+}
+
 static void pcie_aspm_cap_init(struct pcie_link_state *link, int blacklist)
 {
 	struct pci_dev *child = link->downstream, *parent = link->pdev;
@@ -868,6 +904,8 @@ static void pcie_aspm_cap_init(struct pcie_link_state *link, int blacklist)
 	/* Save default state */
 	link->aspm_default = link->aspm_enabled;
 
+	pcie_aspm_override_default_link_state(link);
+
 	/* Setup initial capable state. Will be updated later */
 	link->aspm_capable = link->aspm_support;
 

-- 
2.48.1

