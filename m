From: Ziyao Li <liziyao@uniontech.com>
Date: Tue, 13 Jan 2026 10:38:58 +0800
Subject: [PATCH v4] PCI: loongson: Override PCIe bridge supported speeds
 for Loongson-3C6000 series
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-loongson-pci1-v4-1-1921d6479fe4@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAEGwZWkC/3XOQQrCMBCF4auUrI1kksa2rryHuEgyUxvQpDS1K
 KV3NwqCFF3+D+ZjZpZo8JTYvpjZQJNPPoYc5aZgrjPhTNxjbiaF1KKWkl9iDOcUA++dB14iocC
 qbsFalm/6gVp/f3vHU+7OpzEOjzc/wWv9J03AgavGGGsRoLV4uIX8y0iu27p4ZS9tkh9hJ0CUa
 0FmAUED6cruqK1/CepbaNaCyoJGdNqQsqZRa2FZlifoRZhfMgEAAA==
X-Change-ID: 20250822-loongson-pci1-4ded0d78f1bb
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: niecheng1@uniontech.com, zhanjun@uniontech.com, 
 guanwentao@uniontech.com, Kexy Biscuit <kexybiscuit@aosc.io>, 
 linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 loongarch@lists.linux.dev, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Lain Fearyncess Yang <fsf@live.com>, Ayden Meng <aydenmeng@yeah.net>, 
 Mingcong Bai <jeffbai@aosc.io>, Xi Ruoyao <xry111@xry111.site>, 
 Ziyao Li <liziyao@uniontech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768271938; l=4318;
 i=liziyao@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=7rRFGJVoKl5sZ/Owx3rAS56AhpTg53fD7seUm2ML6+o=;
 b=k+ClNVeu7ISFrUJFeAR6ztHNTkB8wEYHkrxhXmEMH0UD1lTMTQP0V+P+LDiY6GJ9c1RmVO1r2
 FWAVbiQzb1wCyAs1y6RO5epfFZpd0Xf+VMx3gZnMZRe9aDrc5Mot04K
X-Developer-Key: i=liziyao@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for liziyao@uniontech.com/20250730 with auth_id=471
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Older steppings of the Loongson-3C6000 series incorrectly report the
supported link speeds on their PCIe bridges (device IDs 0x3c19, 0x3c29)
as only 2.5 GT/s, despite the upstream bus supporting speeds from
2.5 GT/s up to 16 GT/s.

As a result, since commit 774c71c52aa4 ("PCI/bwctrl: Enable only if more
than one speed is supported"), bwctrl will be disabled if there's only
one 2.5 GT/s value in vector `supported_speeds`.

Also, amdgpu reads the value by pcie_get_speed_cap() in amdgpu_device_
partner_bandwidth(), for its dynamic adjustment of PCIe clocks and
lanes in power management. We hope this can prevent similar problems
in future driver changes (similar checks may be implemented in other
GPU, storage controller, NIC, etc. drivers).

Manually override the `supported_speeds` field for affected PCIe bridges
with those found on the upstream bus to correctly reflect the supported
link speeds.

This patch was originally found from AOSC OS[1].

Link: https://github.com/AOSC-Tracking/linux/pull/2 #1
Tested-by: Lain Fearyncess Yang <fsf@live.com>
Tested-by: Ayden Meng <aydenmeng@yeah.net>
Signed-off-by: Ayden Meng <aydenmeng@yeah.net>
Signed-off-by: Mingcong Bai <jeffbai@aosc.io>
[Xi Ruoyao: Fix falling through logic and add kernel log output.]
Signed-off-by: Xi Ruoyao <xry111@xry111.site>
Link: https://github.com/AOSC-Tracking/linux/commit/4392f441363abdf6fa0a0433d73175a17f493454
[Ziyao Li: move from drivers/pci/quirks.c to drivers/pci/controller/pci-loongson.c]
Signed-off-by: Ziyao Li <liziyao@uniontech.com>
Tested-by: Mingcong Bai <jeffbai@aosc.io>
---
Changes in v4:
- rename subject
- use 0x3c19/0x3c29 instead of 3c19/3c29
- Link to v3: https://lore.kernel.org/r/20260109-loongson-pci1-v3-1-5ddc5ae3ba93@uniontech.com

Changes in v3:
- Adjust commit message
- Make the program flow more intuitive
- Link to v2: https://lore.kernel.org/r/20260104-loongson-pci1-v2-1-d151e57b6ef8@uniontech.com

Changes in v2:
- Link to v1: https://lore.kernel.org/r/20250822-loongson-pci1-v1-1-39aabbd11fbd@uniontech.com
- Move from arch/loongarch/pci/pci.c to drivers/pci/controller/pci-loongson.c
- Fix falling through logic and add kernel log output by Xi Ruoyao
---
 drivers/pci/controller/pci-loongson.c | 38 +++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/drivers/pci/controller/pci-loongson.c b/drivers/pci/controller/pci-loongson.c
index bc630ab8a283..3d0873b63cd6 100644
--- a/drivers/pci/controller/pci-loongson.c
+++ b/drivers/pci/controller/pci-loongson.c
@@ -176,6 +176,44 @@ static void loongson_pci_msi_quirk(struct pci_dev *dev)
 }
 DECLARE_PCI_FIXUP_FINAL(PCI_VENDOR_ID_LOONGSON, DEV_LS7A_PCIE_PORT5, loongson_pci_msi_quirk);
 
+/*
+ * Older steppings of the Loongson-3C6000 series incorrectly report the
+ * supported link speeds on their PCIe bridges (device IDs 0x3c19,
+ * 0x3c29) as only 2.5 GT/s, despite the upstream bus supporting speeds
+ * from 2.5 GT/s up to 16 GT/s.
+ */
+static void loongson_pci_bridge_speed_quirk(struct pci_dev *pdev)
+{
+	u8 old_supported_speeds = pdev->supported_speeds;
+
+	switch (pdev->bus->max_bus_speed) {
+	case PCIE_SPEED_16_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_16_0GB;
+		fallthrough;
+	case PCIE_SPEED_8_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_8_0GB;
+		fallthrough;
+	case PCIE_SPEED_5_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_5_0GB;
+		fallthrough;
+	case PCIE_SPEED_2_5GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_2_5GB;
+		break;
+	default:
+		pci_warn(pdev, "unexpected max bus speed");
+
+		return;
+	}
+
+	if (pdev->supported_speeds != old_supported_speeds)
+		pci_info(pdev, "fixing up supported link speeds: 0x%x => 0x%x",
+			 old_supported_speeds, pdev->supported_speeds);
+}
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c19,
+			 loongson_pci_bridge_speed_quirk);
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c29,
+			 loongson_pci_bridge_speed_quirk);
+
 static struct loongson_pci *pci_bus_to_loongson_pci(struct pci_bus *bus)
 {
 	struct pci_config_window *cfg;

---
base-commit: ea1013c1539270e372fc99854bc6e4d94eaeff66
change-id: 20250822-loongson-pci1-4ded0d78f1bb

Best regards,
-- 
Ziyao Li <liziyao@uniontech.com>

