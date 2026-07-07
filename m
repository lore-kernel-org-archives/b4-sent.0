From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 05:16:28 +0800
Subject: [PATCH RFC v2 4/7] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v2-4-2afdd1741766@gmail.com>
References: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
In-Reply-To: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1441;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=mntUM15kvZ5qHuhBJ5Gk7CAScyEYG01WrWkE9WJIf5U=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWy1krEPRRnT/H3otyGIGhIUHD0Mm+LAVg/ql
 PJvdFu5SWWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1stQAKCRCwMePKe/7Z
 bjwUEAC3WeBgthTssDKCJMjpBmHqP1cLuumVsXMoGAuCuZR4bRRWTd2sUuKbZ9qLvCZ8OhCWia2
 qjPnz4nDwGhTXUtrWCd7UxXUPgeVthzPgRGDbimRGBxoeRJq8TkFLL1uMe+t0tFqIOykiwJA7rW
 6z86ncz8nO5CvVSFQaiMOfqv5FDYEOC/7EUcQZxQfrgjZnapkTnJ+1BtdtsoszYfcVJ1Jhrcqzl
 LSEoTygOYic8J4WYD7AzPu1bgrpGS3sVGxB8t1ZcH6YYH3YMyT7NFwwtnfoDk+K9qnn/zY2go52
 Ma/9Vl9c/M56G67k7sRLYnb7ZHgqov1Gw7mdCAh758PU1lanOFnWvYKmjPMZSXXUj8MUcHbjk+A
 Bcz53rqkbMBO9+Ida+WELb31Mude3udQQ6OwA6Vqqb05xZfOFsPON9jrAj6xQhU1/PWPUvry4Yo
 nberd0LQYTn6DVEYbleYSrHzjgRIGpaa1ObgDxQt1aRrs+F60SPZZt9rHb7SW1iTdakDee7W7l8
 9zLeL9BcrWi1VF8cU4eev5v2KluzoFj7qdDUho2lTAByNGh0xcN/KByh0GE1n/7BHtesxEUJRMu
 BkwwfG6+DEC2sDyskhc4eGCQzEXI9mMeymGG4E97XWpQqh6yJoKAKSx1Z2fceLigKYSC2DfbGgf
 QsdzMFAWaE5f74Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the device is being removeed, the work queue should be canceled to
avoid any pending work to be executed after the device is removed.

Fixes: d952bba3fbb5 ("mfd: ls2kbmc: Add Loongson-2K BMC reset function support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index a5465c42a77b8b7b81e3ad787d6036679c6ba6df..f87224105b3720cca97dcef089dad63fe57bc8c2 100644
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
@@ -385,6 +391,8 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
 
 	INIT_WORK(&ddata->bmc_reset_work, ls2k_bmc_events_fn);
 
+	devm_add_action_or_reset(ddata->dev, ls2k_bmc_cancel_wq, ddata);
+
 	ret = devm_request_irq(&pdev->dev, pdev->irq, ls2k_bmc_interrupt,
 			       IRQF_SHARED | IRQF_TRIGGER_FALLING, "ls2kbmc pcie", ddata);
 	if (ret) {

-- 
2.49.0

