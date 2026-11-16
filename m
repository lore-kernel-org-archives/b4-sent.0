From: Matt Thompson <matt@boondocker.io>
Date: Mon, 16 Nov 2026 02:35:46 -0700
Subject: [PATCH RFC v3 4/6] PCI: Resume downstream ports before sysfs Link
 Control writes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-rfc-b4-v3-4-0bf052b68f2a@boondocker.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794821744; l=1870;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=WwxhOpFrtKsCRMga9k7eAPDdOyaWOUhvS24ZacGcwHM=;
 b=Vt/YxUV8iyuFcHYDbGV8VJ1jDUfHBt7r3E0+peNj47PQhLuHZVbc/DW+gkn2Gb1zSm98duTUN
 ShveA0x/eUaAq51euaX34+7tof+wu4vc4pOXXy7r4ZsVWOwU7sG1VR/
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Configuration space can remain accessible while a port is runtime
suspended. A sysfs Link Control write can then reach hardware before
runtime resume restores the saved state. On RockPro64 a rescan resumed
the port and restored the saved Link Disable bit after userspace had
cleared it, leaving the endpoint absent.

Resume a runtime-suspended downstream port before writing overlapping
Link Control bytes. The configuration access already holds the runtime
PM reference across the write.

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 drivers/pci/pci-sysfs.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/pci/pci-sysfs.c b/drivers/pci/pci-sysfs.c
index 6669e9a..ff47ea1 100644
--- a/drivers/pci/pci-sysfs.c
+++ b/drivers/pci/pci-sysfs.c
@@ -786,6 +786,7 @@ static ssize_t pci_write_config(struct file *filp, struct kobject *kobj,
 	struct pci_dev *dev = to_pci_dev(kobj_to_dev(kobj));
 	unsigned int size = count;
 	loff_t init_off = off;
+	loff_t lnkctl = pci_pcie_cap(dev) + PCI_EXP_LNKCTL;
 	u8 *data = (u8 *) buf;
 	int ret;
 
@@ -809,6 +810,21 @@ static ssize_t pci_write_config(struct file *filp, struct kobject *kobj,
 
 	pci_config_pm_runtime_get(dev);
 
+	/*
+	 * Link Control can be written while config space remains accessible in
+	 * runtime suspend. Restore saved state first so a later resume cannot
+	 * replace the new link setting with the saved value.
+	 */
+	if (count && pci_is_pcie(dev) && pcie_downstream_port(dev) &&
+	    pm_runtime_suspended(&dev->dev) &&
+	    off < lnkctl + sizeof(u16) && off + count > lnkctl) {
+		ret = pm_runtime_resume(&dev->dev);
+		if (ret < 0) {
+			pci_config_pm_runtime_put(dev);
+			return ret;
+		}
+	}
+
 	if ((off & 1) && size) {
 		pci_user_write_config_byte(dev, off, data[off - init_off]);
 		off++;

-- 
Git-155)

