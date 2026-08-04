From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 05 Aug 2026 03:14:22 +0800
Subject: [PATCH RFC v6 4/7] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-ls2kbmc-mod-v6-4-16ccde412d86@gmail.com>
References: <20260805-ls2kbmc-mod-v6-0-16ccde412d86@gmail.com>
In-Reply-To: <20260805-ls2kbmc-mod-v6-0-16ccde412d86@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcjoX4PGr3fi2gyACC1u+oTkUNeYJpXcHqn55+
 svT259NZLOJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanI6FwAKCRCwMePKe/7Z
 bnmgD/91eSK0ImtZVckcCKjN0w7Ib2AYx6+aqsrumocsjTwSGjSA6WXRn6o2Mvm1fCFo96mV//F
 g7ravbOvXqlbld0IAw7rthwCPU+UwGBB8XuW73dUxFGDJ7X6ofNK6EjEh8ruG7AdqZBkxhnDAmt
 1dw5+WBFar21oHwpfwLVu3HOaCu1qFGrXqF5sRVUKrW1C+m+vBPtC09P9yUz74a/q92J58seWiH
 kjthTkX4+wF5ho7TKrMGMsvstfRf2tovpvh9eNTmuo1LvHpozlV3RNG57CY7I+cTJJWCjLlXl6c
 zuKwKCsZz8i6PbVZOQMbirwEUd+/Hb9TPGZU3xt5UDz68gRPAMK7SON+tjWQd1eZTL/GrMV7IBb
 Qjo8GHdlbmSCEUnIy0cT6h18GfpwAq32owcwWw6Xhzsqs0HMKx4vv6u8pRPHKpqR+P3JWVWltCi
 ABplnkhgyfXUgh8AyEj2AcXgVAEuHbrEtwZVK/C15ZrsEm7/8pnnyrxa9pQDjT4XZRs/9YikgOw
 LIdtwrkiVayrU66/Y9MIyxDtnGF6aOoiVzouuAWzC/ShyJIk+znA4jwXiiwc9cFtjU6v3EPqduM
 yQpcQVZc7xpoKt7bDmd9fY6DFKwc8INujqe+7BKl9QeL6oHFIs3f7tHhHrjYhQOyPIBrpctk4Yt
 15UOdUkfUnrAK0A==
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

