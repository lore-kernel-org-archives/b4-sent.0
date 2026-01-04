From: Ziyao Li <liziyao@uniontech.com>
Date: Sun, 04 Jan 2026 18:00:40 +0800
Subject: [PATCH v2] PCI: loongson: Override PCIe bridge supported speeds
 for older Loongson 3C6000 series steppings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260104-loongson-pci1-v2-1-d151e57b6ef8@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAEc6WmkC/3WOywrCMBBFf6XM2kgmKlZX/od0kcekHdCkJDUoJ
 f9u7N7lOXAPd4VMiSnDtVshUeHMMTRQuw7spMNIgl1jUFKdZK+UeMQYxhyDmC2jODpy0p17j8Z
 A28yJPL+33n1oPHFeYvps+YI/+69UUKA4XLQ2xiF6426v0L4sZKe9jU8Yaq1fUrvm364AAAA=
X-Change-ID: 20250822-loongson-pci1-4ded0d78f1bb
To: Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: niecheng1@uniontech.com, zhanjun@uniontech.com, 
 guanwentao@uniontech.com, Kexy Biscuit <kexybiscuit@aosc.io>, 
 linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Lain Fearyncess Yang <fsf@live.com>, Ayden Meng <aydenmeng@yeah.net>, 
 Mingcong Bai <jeffbai@aosc.io>, Xi Ruoyao <xry111@xry111.site>, 
 Ziyao Li <liziyao@uniontech.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767520839; l=3718;
 i=liziyao@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=+rmbxah69iyFGRtuc9PZUgFv4IGdfBjrB3ad/JWqtLY=;
 b=ZxZv5+fXgRd84L/BWuPniRPwH/9kkJGe9cLb9R1XVfFrGtzdgl4zXQvPjFFMyydY1nLb/MLpJ
 BQAtIl4gueoDVYrQBOqmEt6ZhQpE+SwdUJNLIuSl+PZUzLCej0eBw+z
X-Developer-Key: i=liziyao@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for liziyao@uniontech.com/20250730 with auth_id=471
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Older steppings of the Loongson 3C6000 series incorrectly report the
supported link speeds on their PCIe bridges (device IDs 3c19, 3c29) as
only 2.5 GT/s, despite the upstream bus supporting speeds from 2.5 GT/s
up to 16 GT/s.

As a result, certain PCIe devices would be incorrectly probed as a Gen1-
only, even if higher link speeds are supported, harming performance and
prevents dynamic link speed functionality from being enabled in drivers
such as amdgpu.

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
Changes in v2:
- Link to v1: https://lore.kernel.org/r/20250822-loongson-pci1-v1-1-39aabbd11fbd@uniontech.com
- Move from arch/loongarch/pci/pci.c to drivers/pci/controller/pci-loongson.c
- Fix falling through logic and add kernel log output by Xi Ruoyao
---
 drivers/pci/controller/pci-loongson.c | 39 +++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/drivers/pci/controller/pci-loongson.c b/drivers/pci/controller/pci-loongson.c
index bc630ab8a283..75a1b494b527 100644
--- a/drivers/pci/controller/pci-loongson.c
+++ b/drivers/pci/controller/pci-loongson.c
@@ -176,6 +176,45 @@ static void loongson_pci_msi_quirk(struct pci_dev *dev)
 }
 DECLARE_PCI_FIXUP_FINAL(PCI_VENDOR_ID_LOONGSON, DEV_LS7A_PCIE_PORT5, loongson_pci_msi_quirk);
 
+/*
+ * Older steppings of the Loongson 3C6000 series incorrectly report the
+ * supported link speeds on their PCIe bridges (device IDs 3c19, 3c29) as
+ * only 2.5 GT/s, despite the upstream bus supporting speeds from 2.5 GT/s
+ * up to 16 GT/s.
+ */
+static void quirk_loongson_pci_bridge_supported_speeds(struct pci_dev *pdev)
+{
+	u8 supported_speeds = pdev->supported_speeds;
+
+	switch (pdev->bus->max_bus_speed) {
+	case PCIE_SPEED_16_0GT:
+		supported_speeds |= PCI_EXP_LNKCAP2_SLS_16_0GB;
+		fallthrough;
+	case PCIE_SPEED_8_0GT:
+		supported_speeds |= PCI_EXP_LNKCAP2_SLS_8_0GB;
+		fallthrough;
+	case PCIE_SPEED_5_0GT:
+		supported_speeds |= PCI_EXP_LNKCAP2_SLS_5_0GB;
+		fallthrough;
+	case PCIE_SPEED_2_5GT:
+		supported_speeds |= PCI_EXP_LNKCAP2_SLS_2_5GB;
+		break;
+	default:
+		pci_warn(pdev, "unexpected max bus speed");
+		return;
+	}
+
+	if (supported_speeds != pdev->supported_speeds) {
+		pci_info(pdev, "fixing up supported link speeds: 0x%x => 0x%x",
+			 pdev->supported_speeds, supported_speeds);
+		pdev->supported_speeds = supported_speeds;
+	}
+}
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c19,
+			 quirk_loongson_pci_bridge_supported_speeds);
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c29,
+			 quirk_loongson_pci_bridge_supported_speeds);
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

