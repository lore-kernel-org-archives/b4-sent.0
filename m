From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 16 Sep 2025 21:42:52 +0530
Subject: [PATCH 1/2] PCI/ASPM: Override the ASPM and Clock PM states set by
 BIOS for devicetree platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250916-pci-dt-aspm-v1-1-778fe907c9ad@oss.qualcomm.com>
References: <20250916-pci-dt-aspm-v1-0-778fe907c9ad@oss.qualcomm.com>
In-Reply-To: <20250916-pci-dt-aspm-v1-0-778fe907c9ad@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, "David E. Box" <david.e.box@linux.intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bjorn Helgaas <helgaas@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6096;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=mb8JVPsHMaTMVCXcaz6UM3OfVWvgWcj7i6rK1yWo59s=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsg42TNlR9tF76aMB4UPJlbkiSgeC5RKX+pzWEs/IeXtj
 ErLjS6nOxmNWRgYuRhkxRRZ0pc6azV6nL6xJEJ9OswgViaQKQxcnAIwkUhT9v9xy4/rcfk+/TEh
 PinXYatCnKD3D+X33p7zWead+NL+V3WhUd+reyWNF42dYhONynT0d27YujRT8/pp04hygZyD2wR
 /NZQkOtjZ1df9y7/5o7c1/3mVILusvtN7G4+eyNfWBgfkX9o9OJjp7B3akVF27sjN379WaPxvjz
 1gWL6Ue6Ov8ne1utgMq+Wr0vsYmOf7NWpLRqXc4Ht/2eXa7T7ulFzpx5eEIzXPxqj5PGGN10gNn
 e+yZF2v9mKeEHPL/xa7j4XWd3hLvuiSrPhhWtD8/lFYUPGzfwxyUyY0sXc5aTrXuLHxvSzu3pan
 knXh7/pnhc4N085mpN6uibI8pGx+cMXuE3FR62zVp6UAAA==
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

So far, the PCI subsystem has honored the ASPM and Clock PM states set by
the BIOS (through LNKCTL) during device initialization. This was done
conservatively to avoid issues with the buggy devices that advertise
ASPM capabilities, but behave erratically if the ASPM states are enabled.
So the PCI subsystem ended up trusting the BIOS to enable only the ASPM
states that were known to work for the devices.

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
introduced to set the default ASPM and Clock PM states and they will
override the BIOS set states by enabling all of them if CONFIG_OF is
enabled. To aid debugging, print the overridden ASPM and Clock PM states.

In the future, these helpers could be extended to allow other platforms
like VMD, newer ACPI systems with a cutoff year etc... to follow the path.

Link: https://lore.kernel.org/linux-pci/20250828204345.GA958461@bhelgaas
Suggested-by: Bjorn Helgaas <helgaas@kernel.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pcie/aspm.c | 48 +++++++++++++++++++++++++++++++++++++++++++-----
 1 file changed, 43 insertions(+), 5 deletions(-)

diff --git a/drivers/pci/pcie/aspm.c b/drivers/pci/pcie/aspm.c
index 919a05b9764791c3cc469c9ada62ba5b2c405118..1e7218c5e9127699fdbf172c277aad3f847c43be 100644
--- a/drivers/pci/pcie/aspm.c
+++ b/drivers/pci/pcie/aspm.c
@@ -235,13 +235,15 @@ struct pcie_link_state {
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
 
@@ -373,6 +375,20 @@ static void pcie_set_clkpm(struct pcie_link_state *link, int enable)
 	pcie_set_clkpm_nocheck(link, enable);
 }
 
+static void pcie_clkpm_set_default_link_state(struct pcie_link_state *link,
+					      int enabled)
+{
+	struct pci_dev *pdev = link->downstream;
+
+	link->clkpm_default = enabled;
+
+	/* Override the BIOS disabled Clock PM state for devicetree platforms */
+	if (IS_ENABLED(CONFIG_OF) && !enabled) {
+		link->clkpm_default = 1;
+		pci_info(pdev, "Clock PM state overridden\n");
+	}
+}
+
 static void pcie_clkpm_cap_init(struct pcie_link_state *link, int blacklist)
 {
 	int capable = 1, enabled = 1;
@@ -394,7 +410,7 @@ static void pcie_clkpm_cap_init(struct pcie_link_state *link, int blacklist)
 			enabled = 0;
 	}
 	link->clkpm_enabled = enabled;
-	link->clkpm_default = enabled;
+	pcie_clkpm_set_default_link_state(link, enabled);
 	link->clkpm_capable = capable;
 	link->clkpm_disable = blacklist ? 1 : 0;
 }
@@ -788,6 +804,29 @@ static void aspm_l1ss_init(struct pcie_link_state *link)
 		aspm_calc_l12_info(link, parent_l1ss_cap, child_l1ss_cap);
 }
 
+static void pcie_aspm_set_default_link_state(struct pcie_link_state *link)
+{
+	struct pci_dev *pdev = link->downstream;
+	u32 override;
+
+	/* Set BIOS enabled states as the default */
+	link->aspm_default = link->aspm_enabled;
+
+	/* Override the BIOS disabled ASPM states for devicetree platforms */
+	if (IS_ENABLED(CONFIG_OF)) {
+		link->aspm_default = PCIE_LINK_STATE_ASPM_ALL;
+		override = link->aspm_default & ~link->aspm_enabled;
+		if (override)
+			pci_info(pdev, "ASPM states overridden: %s%s%s%s%s%s\n",
+				 (override & PCIE_LINK_STATE_L0S) ? "L0s, " : "",
+				 (override & PCIE_LINK_STATE_L1) ? "L1, " : "",
+				 (override & PCIE_LINK_STATE_L1_1) ? "L1.1, " : "",
+				 (override & PCIE_LINK_STATE_L1_2) ? "L1.2, " : "",
+				 (override & PCIE_LINK_STATE_L1_1_PCIPM) ? "L1.1 PCI-PM, " : "",
+				 (override & PCIE_LINK_STATE_L1_2_PCIPM) ? "L1.2 PCI-PM" : "");
+	}
+}
+
 static void pcie_aspm_cap_init(struct pcie_link_state *link, int blacklist)
 {
 	struct pci_dev *child = link->downstream, *parent = link->pdev;
@@ -865,8 +904,7 @@ static void pcie_aspm_cap_init(struct pcie_link_state *link, int blacklist)
 		pcie_capability_write_word(child, PCI_EXP_LNKCTL, child_lnkctl);
 	}
 
-	/* Save default state */
-	link->aspm_default = link->aspm_enabled;
+	pcie_aspm_set_default_link_state(link);
 
 	/* Setup initial capable state. Will be updated later */
 	link->aspm_capable = link->aspm_support;

-- 
2.45.2

