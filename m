From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 20:25:30 +0800
Subject: [PATCH RFC v7 4/8] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v7-4-8aa0fb5a5462@gmail.com>
References: <20260810-ls2kbmc-mod-v7-0-8aa0fb5a5462@gmail.com>
In-Reply-To: <20260810-ls2kbmc-mod-v7-0-8aa0fb5a5462@gmail.com>
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
 bh=+xbRMJCIp18RIJ0wKO3Pv8PASldwSY769xQI4nSINrw=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecNKq6kBydVq7F6pd2HFIrn9pR8uMJZbcbnwo
 8I+wlJ8ch2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannDSgAKCRCwMePKe/7Z
 bsoOD/4zwnIa62jgwLDGu306AceXlq9mXvV6oPrbuJTvcfB6zOOnFCKPTykk/IYqdxEek6k/kdV
 teyct/Qw/T0pUbA+FrZhnAsqXQgClV/Blsy9djSNbOr2ZNAx8GYt5XGsKswCQ+RL5rXX9aB+Wez
 j7PxVZU73J8ZdkwN+C2ELpcpZ8iV29cugbuHUoYeof7jbwwwKZW8ZkAXZTYnpCN+pJ+Q5Ca8ONK
 tfTBp9464Gu+XC38XgrwEzzQeaC5hxOiez6dBKUsX0qHCXmKMIRnCiSuDBx46wDLDfZvY0hBudB
 I6okS0EW6KYmL/alUStS0bKO7TBu0YcJ9i6xiAtO68+AdrPlXm0EjBd2PU+WYvvFmx8kwcIwHeg
 Kpu/hzFV/ozuCnSLGca/4CrXV6Bp3uEtH02CzQRGMmOE1E7HIfuM1whVZSCxwKnET4/cu19gD65
 8J5v3qO9Q2uuwdwwI4Ta+ruRncZN5AfP+ZS90pGWkAJeH1se+Q5BVqqIJttAyL7HAJZDx2bPSPZ
 BERlS+9HXaQk8fOlpA8LPe6fBztWifyhUYspOaT33qudat3vMRTenxMZORbZIMQrIEpcg3DtIEQ
 l5KPiJgboVDRV6skEs3u+HeHBLL88fFUA2q/kGaVRrt+YxkwHD7TDM9dI2zv5WdTOWJIWMvsoau
 O7aONsnXYm27p1w==
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
index 06ec8143d8cdbe2c8e5a141020d96c21b37fa699..5eea53f134215456e0c14345ae4ebc5b66bd433d 100644
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

