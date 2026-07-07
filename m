From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 03:24:03 +0800
Subject: [PATCH RFC 2/5] mfd: ls2kbmc: sanity check for the connected pci
 port
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v1-2-c344bf5defa3@gmail.com>
References: <20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com>
In-Reply-To: <20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com>
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2613;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=rHqqMI0QwbQRHGWtPih1J6SfJtGSYtOe0nOgtjKfQFI=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTVJbJaOX+ug0wEXICB8dkHbNin2LD1ux3otFI
 Gqrclpvk32JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1SWwAKCRCwMePKe/7Z
 biMHD/4nbu1tvuKAKUP1XxuBNDqAWBSN//wHZmLHENpkcqhPMIBwZAmyS41M74YNUc5CWV+zJuW
 8F5YZc27JZkJlwGxhzBRDGrMutTXI4gFiuN8tSArnkZ9FrHGdc1n5Mtox9CeuLF/yCi7OportKV
 thrJgVZZNkCju+bdcqVF8qorq5BjMvBGKtv2qGz5ADFr0CmKsbzpOa5BB9ZdAPC02HZquS2Q3zK
 SsIBy9p+p4izXW/74EYofh57pdYDAz013kJiu3Q6Xa9KOoiR3hBvwl8vzvUFTX8deFbOn8PhlJG
 90VNQkZrn2PqW/n5SKYDFSsmHDT8YzzpBqB0Kr3GrLD3cXB4gGV7cI3Ppk8HJYjMtP1jA1vfFHD
 ATLLyQmEl4ewfWUErmXLms9kh1OaGt6L8sinNURqRlJLPKpSvk1KbhuVGJt7x9w1vIGtrd6t2nr
 XBC5SOBX8WW370zoDDQq1+cn8UEQRpWyiYpJjhSv0gXnNUAbfZ4FguiQLsDTe2HkOko3HW9nru+
 WXaXEY0SDjKL/E1+206PXTNqkBN2RFyYqK+rF+IFLY9q8Om8VLARs3PPuYDFUj4+O7f/Ia4rbpY
 +n4oPlCk/FYUZNlE2RuTSWWCE8Tvh4PtORzQKWA/NNWmUfX+CzxGaOYf3FQV8wosdnu+VucUAib
 lEG+TUHEyfhJOCw==
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
index 30b275bc48794a22249aeb8ba805ef78772d3466..39ce5e55ffd6d3a578008dd752b3e8dceec9bd81 100644
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
@@ -476,6 +485,24 @@ static int ls2k_bmc_parse_mode(struct pci_dev *pdev, struct simplefb_platform_da
 	return -EINVAL;
 }
 
+static struct pci_device_id ls7a_ports[] = {
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
+	return pci_match_id(ls7a_ports, parent) != NULL;
+}
+
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)
 {
 	struct simplefb_platform_data pd;
@@ -487,6 +514,11 @@ static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)
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

