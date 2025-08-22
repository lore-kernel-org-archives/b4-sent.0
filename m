From: Ziyao <liziyao@uniontech.com>
Date: Fri, 22 Aug 2025 17:15:58 +0800
Subject: [PATCH RESEND] PCI: Override PCIe bridge supported speeds for
 older Loongson 3C6000 series steppings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-loongson-pci1-v1-1-39aabbd11fbd@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAE01qGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyMj3Zz8/Lz04vw83YLkTENdk5TUFIMUc4s0w6QkJaCegqLUtMwKsHn
 RSkGuwa5+LkqxtbUAxRNBqmcAAAA=
X-Change-ID: 20250822-loongson-pci1-4ded0d78f1bb
To: Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 loongarch@lists.linux.dev, niecheng1@uniontech.com, zhanjun@uniontech.com, 
 guanwentao@uniontech.com, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Lain Fearyncess Yang <fsf@live.com>, Mingcong Bai <jeffbai@aosc.io>, 
 Ayden Meng <aydenmeng@yeah.net>, Ziyao <liziyao@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755854158; l=2862;
 i=liziyao@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=7xgYquKCBWgLgcwEUYsMzaOeKqJ2pkwi5F04w/83CmQ=;
 b=4SQnoM5gRY/+gdNOKjlnMONV5R8RlOLqacb/Px3bQrAeMEACvDqhac2rM4vmbswmwm2afAwZQ
 0+S2BqiB5bRD4RXfwBUD0v6nMPOSh+K19IIE2TFDYzG24aEYM7r/8Qq
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

This patch is found from AOSC OS[1].

Link: https://github.com/AOSC-Tracking/linux/pull/2 #1
Tested-by: Lain Fearyncess Yang <fsf@live.com>
Tested-by: Mingcong Bai <jeffbai@aosc.io>
Tested-by: Ayden Meng <aydenmeng@yeah.net>
Signed-off-by: Ayden Meng <aydenmeng@yeah.net>
Signed-off-by: Ziyao <liziyao@uniontech.com>
---
PCI: Override PCIe bridge supported speeds for older Loongson 3C6000
 series steppings
---
 drivers/pci/quirks.c | 24 ++++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/drivers/pci/quirks.c b/drivers/pci/quirks.c
index d97335a401930fe8204e7ca91a8474b6b02554c1..8d29b130f45854d2bff8c47e6529a41a3231221e 100644
--- a/drivers/pci/quirks.c
+++ b/drivers/pci/quirks.c
@@ -1956,6 +1956,30 @@ DECLARE_PCI_FIXUP_FINAL(PCI_VENDOR_ID_INTEL,	PCI_DEVICE_ID_INTEL_E7525_MCH,	quir
 
 DECLARE_PCI_FIXUP_CLASS_FINAL(PCI_VENDOR_ID_HUAWEI, 0x1610, PCI_CLASS_BRIDGE_PCI, 8, quirk_pcie_mch);
 
+/*
+ * Older steppings of the Loongson 3C6000 series incorrectly report the
+ * supported link speeds on their PCIe bridges (device IDs 3c19, 3c29) as
+ * only 2.5 GT/s, despite the upstream bus supporting speeds from 2.5 GT/s
+ * up to 16 GT/s.
+ */
+static void quirk_loongson_pci_bridge_supported_speeds(struct pci_dev *pdev)
+{
+	switch (pdev->bus->max_bus_speed) {
+	case PCIE_SPEED_16_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_16_0GB;
+	case PCIE_SPEED_8_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_8_0GB;
+	case PCIE_SPEED_5_0GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_5_0GB;
+	case PCIE_SPEED_2_5GT:
+		pdev->supported_speeds |= PCI_EXP_LNKCAP2_SLS_2_5GB;
+	default:
+		break;
+	}
+}
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c19, quirk_loongson_secondary_bridge_supported_speeds);
+DECLARE_PCI_FIXUP_HEADER(PCI_VENDOR_ID_LOONGSON, 0x3c29, quirk_loongson_secondary_bridge_supported_speeds);
+
 /*
  * HiSilicon KunPeng920 and KunPeng930 have devices appear as PCI but are
  * actually on the AMBA bus. These fake PCI devices can support SVA via

---
base-commit: 3957a5720157264dcc41415fbec7c51c4000fc2d
change-id: 20250822-loongson-pci1-4ded0d78f1bb

Best regards,
-- 
Ziyao <liziyao@uniontech.com>

