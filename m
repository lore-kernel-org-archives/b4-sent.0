From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 21:04:25 +0800
Subject: [PATCH RFC v8 2/8] mfd: ls2kbmc: Sanity check for the connected
 pci port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v8-2-16e44f7322f4@gmail.com>
References: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
In-Reply-To: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2625;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=/Lr4vPc1caTNdLxJjHXD0ez/C7ATtTCBQ8ReLhje6Eg=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecxjWTKnhUVNbEpdlZXhBpWJvFtlOYOE4tBqB
 rxNqfLbxSKJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannMYwAKCRCwMePKe/7Z
 bigaD/sEJogHOgHPhc0+ZbcC2O7wX8G6LgQM1YBmOZo3OrHy9Z+dUZDT9UrnljmmcrVzMJvw9s0
 2/HL3ZdUy6aSFG1ver0zmZemXLR/HpNSOIerPdPZ17xL7yvtF313LNwGqdQnLn0evbF7kYHGAVQ
 mHH7lLDz7bk2WgryxlVUKUeAXfln/J+LhthN3QIQogEq5WzgJtjgmNbtnqobI1EIZ6RxxnA+Kgv
 7+HpvtgWAm+6xoWzkFans7l9HDQmFbwZmqbpdruuw9bJUd6wXorActjt1LqWxB7H+Ell5/SnPCk
 euMVq6i4q8//ZEep6tMWu6Q2LgjvScP04FoOYvtVEjv3leb6pOeHGngHe0oeIh4Fg6hgZ3CtjFm
 M8jBrJ0yZJ2Ho6yd73r4B1OimhEsc7nvc133qasorBewshqRoAlp9SqhF6hyqzfGrkiAQ3I0Q6Z
 H4cV1fXyBWPo7uDOGhTjilk/CmHyqasQT0oTzu/5CJPEBn1t9ScWaRD8Yky6tYraaCnBCkRWo4B
 RBobfCUo77uL/UqW2CZnSEHJa7J2qQzyDAScLLwid5VwUgEMSMtbnoa2r3vGbajf9bgKAAdHhhb
 pVxv2ywUGjOGGkJVhOx9d46VkMLxgtrQdSsy4mhb2jIzJHTECLp0FXt18SOIShrI6s5tDSWQKrR
 iLT8zOpIkxmdMHQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the bmc resets, the recovery procedure require to reconfigure the
parent device. The driver assumes that the parent device should be LS7A.
Add a sanity check on initialization to ensure this and prevent from
accidentally operating on non-LS7A ports.

Fixes: d952bba3fbb5 ("mfd: ls2kbmc: Add Loongson-2K BMC reset function support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 32 ++++++++++++++++++++++++++++++++
 1 file changed, 32 insertions(+)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 335590392240ba1e13a2bdf6f9f4efddec045f40..434db99ee501be8e18de7258af0f465fc16c0709 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -35,6 +35,15 @@
 #define LS2K_IPMI3_RES_START		(LS2K_IPMI2_RES_START + LS2K_IPMI_RES_SIZE)
 #define LS2K_IPMI4_RES_START		(LS2K_IPMI3_RES_START + LS2K_IPMI_RES_SIZE)
 
+/* LS7A port Device IDs */
+#define DEV_LS7A1K_PCIE_PORT0	0x7a09
+#define DEV_LS7A1K_PCIE_PORT1	0x7a19
+#define DEV_LS7A1K_PCIE_PORT2	0x7a29
+#define DEV_LS7A2K_PCIE_PORT0	0x7a39
+#define DEV_LS7A2K_PCIE_PORT1	0x7a49
+#define DEV_LS7A2K_PCIE_PORT2	0x7a59
+#define DEV_LS7A2K_PCIE_PORT3	0x7a69
+
 #define LS7A_PCI_CFG_SIZE		0x100
 
 /* LS7A bridge registers */
@@ -490,6 +499,24 @@ static int ls2k_bmc_parse_mode(struct pci_dev *pdev, struct simplefb_platform_da
 	return ret;
 }
 
+static const struct pci_device_id ls7a_ports[] = {
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A1K_PCIE_PORT0) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A1K_PCIE_PORT1) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A1K_PCIE_PORT2) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A2K_PCIE_PORT0) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A2K_PCIE_PORT1) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A2K_PCIE_PORT2) },
+	{ PCI_DEVICE(PCI_VENDOR_ID_LOONGSON, DEV_LS7A2K_PCIE_PORT3) },
+	{ }
+};
+
+static bool ls2k_check_parent(struct pci_dev *dev)
+{
+	struct pci_dev *parent = dev->bus->self;
+
+	return parent && pci_match_id(ls7a_ports, parent) != NULL;
+}
+
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)
 {
 	struct simplefb_platform_data pd;
@@ -501,6 +528,11 @@ static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)
 	if (ret)
 		return ret;
 
+	if (!ls2k_check_parent(dev)) {
+		dev_err(&dev->dev, "Expected to be connected to LS7A PCI-E port\n");
+		return -ENODEV;
+	}
+
 	ddata = devm_kzalloc(&dev->dev, sizeof(*ddata), GFP_KERNEL);
 	if (!ddata)
 		return -ENOMEM;

-- 
2.49.0

