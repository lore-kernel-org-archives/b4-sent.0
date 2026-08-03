From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 04 Aug 2026 00:55:52 +0800
Subject: [PATCH RFC v5 4/7] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-ls2kbmc-mod-v5-4-e6bc5cdd9a93@gmail.com>
References: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
In-Reply-To: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
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
 bh=JfJpObrd5YhUsg0KmTA+Fgw5Trzi5JwERZB1GRhNqG0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcMhKuM+IF3Na2gINNmXwdAd99/qiKJDFzpe81
 fBBn4lrj/SJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanDISgAKCRCwMePKe/7Z
 bkCMD/0d9TDXHqudXnVDofETx3w2WKdtK4V5hw6PTRf5VCAhGd9fl5txALHVjZWr0loSsNbYCPJ
 0Smgh7HSul9o+2nAQum4J/36M1UfBgKoWy8soL7cyMFRJo/YNCpYXpI5jqLPQKsgAXihyACzEfi
 NSw8KssTl1CdWgmotQrY5MI/b6W3JVRSFCqvbfGg6pNPv2EG406wnrkncsxwUSsKtEuxAs050ds
 9GLsHJ2CPTgVH1tEFmPCS3S6NQhfM6kUctroJeCQ3w1dJqunAWVRcYtOcUwE6sydTj5xuUFfRvO
 fxhFl2eG8Yw4nq+bIrQGh31zdfVP5g4PMdhOKTxjJC8g1QEx0akXY/9DxcCWeoaZnL7Hk/urp+O
 QDig1UomR27DjBIGS1N1oQmEwOaOaPdneAllfEBwC/bOxtvJWAoiuCNaFlROYvkPrgZxKCjPs99
 0y0VBKuwG0Bx4X3HsdATKhjQr7k4cLttZ2tP4AENMBzGuPIoThI+XB+WYCnV60e+FgAfHzRdLLG
 hUqMkO00OsqFbR5j4o1fvmZyvandW+e046DeB9/kswHzHwPlWptvYlL+m7+YZNdhrAT3b/y6tzz
 xh3dtFuJBiAuAqXSivkPfXa5uRWHPhwBdkYGTL2ms21rSLGC2JuzV1F+eKRCI1zQadnfob0/cLR
 ETSKrLnoi1nb+/w==
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
index e12f2ca2fbef360ceda14ee6fc64f500e4944120..e7bebfe696ac4554eb6283279811a27ed865ab73 100644
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

