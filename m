From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 31 Jul 2026 01:03:25 +0800
Subject: [PATCH RFC v4 4/7] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ls2kbmc-mod-v4-4-d201502ba239@gmail.com>
References: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
In-Reply-To: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1480;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=/0Zc8SBBqzivjk5dmyl3TFu1CZBMiGpU8UG5gVg9tKE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqa4PjPzAzEdsdVuiD4bZW/su2PZUzTlyvJc23x
 38ejXJssDiJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCamuD4wAKCRCwMePKe/7Z
 btqSEADTFcu+lLEgR2fLSWruUjxtdazz08ba8knbWiAew0hwVX+sDyeTbYEw9Rh6CabskVztEfu
 wyAocdxBirv5qdmAtM8VeIA5DXhBwFLN4vfRUrywPskUS0VaqmvRP+TPXCdstIwAli4fIU4/qqh
 0uX28JTj9heJ4NmFKoH0y3OELwbA5f1EJ5YDp2679BsJi942zH3+Qg4B8dM7RRuoLq3flmfN4K2
 XifHZ/PV7Ld7Z2WkcIEXD5kj10vb8ZepK+VR9K/d614DuUOH8YlKeHn1ShBOX2MF9lFDLOiaFD4
 NPq/lkkXCCmH9xNuGC9v3WfHt2+xkJifqg8sE3JzZ9JKMwjATgj6qjklsdz+P70cmGUYyAnJiwZ
 EZ2Ak8oI70CTKYltHyDiDS9UaxEUOBizP6ivOhO+6WIzEA37YIyWhDZN4kQne20J3qxmoRs1Y/S
 pcmrV66acE7DXKFiPgnBISLCbOGCNDIdxp7mlepNAmX6RBIXSs0qNIXIdigG1GGKZgt+XMGM6IX
 pZVjjJTZBpJbbKmYeQf4LV0Dno+Li5GY98T+JE7ehmPxsIz9CeEibKyhne880aBItfspPEoh7iO
 nKvuTJ4SlClYHO7wBIK16HPSe3iqfAEb1x/ClnB1zZ41Tj7drboiPg+gvMY2abhfZWp35zbnlJW
 FNmCH4fuJ5pEvlw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the device is being removeed, the work queue should be canceled to
avoid any pending work to be executed after the device is removed.

Fixes: d952bba3fbb5 ("mfd: ls2kbmc: Add Loongson-2K BMC reset function support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index a5465c42a77b8b7b81e3ad787d6036679c6ba6df..1466b314fc4e577fe5e31404444648b5b0447ebb 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -375,6 +375,12 @@ static void ls2k_bmc_save_pci_data(struct pci_dev *pdev, struct ls2k_bmc_ddata *
 	pci_read_config_dword(pdev, PCI_INTERRUPT_LINE, &ddata->bmc_pci_data.interrupt_line);
 }
 
+static void ls2k_bmc_cancel_wq(void *data)
+{
+	struct ls2k_bmc_ddata *ddata = data;
+	(void) cancel_work_sync(&ddata->bmc_reset_work);
+}
+
 static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
 {
 	struct pci_dev *pdev = to_pci_dev(ddata->dev);
@@ -385,6 +391,10 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
 
 	INIT_WORK(&ddata->bmc_reset_work, ls2k_bmc_events_fn);
 
+	ret = devm_add_action_or_reset(ddata->dev, ls2k_bmc_cancel_wq, ddata);
+	if (ret)
+		return ret;
+
 	ret = devm_request_irq(&pdev->dev, pdev->irq, ls2k_bmc_interrupt,
 			       IRQF_SHARED | IRQF_TRIGGER_FALLING, "ls2kbmc pcie", ddata);
 	if (ret) {

-- 
2.49.0

