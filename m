From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 10 Jul 2026 01:24:20 +0800
Subject: [PATCH RFC v3 4/7] mfd: ls2kbmc: Cancel the work queue on removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ls2kbmc-mod-v3-4-ef718636e78e@gmail.com>
References: <20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com>
In-Reply-To: <20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT9lawhBFSIzWxO5lqlt5Aa/wP+/Dfh55EWUAI
 QwBLcPl3c+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/ZWgAKCRCwMePKe/7Z
 briHEACrKvVmtvVZRW55pmaz28sBbqRO2oKWXzgb9g1SI4v4360VtI57Bhwg1eVKJk0pfsRXakt
 etYPputIcmqfMZMEnGTlt98fYAU7Su22j2PbuJ7znpikF0bqGFTYWCi19kEOPqC/09M5sSbt/AB
 3wYU70SM+maTO9iWF0OEG4sDfEKWcUkcdhcaUFIRGxXZ5MuQ/To9ZGBiAXGNDLRklDEcEdSp8cp
 4YUtNyWC3TiDDsIa68ipLz6jx2ffBPyMIFbM9VExD/ig6T30lvWsdhb/Ck1Xitp2OIS15u/DKaj
 b00ITfqfVeIj8xGtRaeNkPZXT88opQzDrxuP2EEEo6W6Z9NY/nZ3OYdzyg4r4EOeMSmdpwbswgq
 KgcsOeM2r0uPpXnUCoGcYrN2PeSGC3YxsymMgIexqlOgATzIgXuTjeRLIn79pMzHmIkuCSoTPnM
 Fun/KXx8HvP1Epj1dYfjYaOW3nNFjPTiA95Rr/FscEW9KK6O/ra+80hJ3/j8uksmtWMdUYc1MCl
 GKLyg+v9Onv4eQpQHYWZFKLCdfxG4oJsSFcyWUAm4vbwd7ks+WgAXQpFQmhhrd6243rw16XAu/H
 z5vqI5Ay3G7LtD5y/SsxSE7ur5G8n6XlT19Z/+tIx+XIQK3e9BH4NT/llvUK+zynKomdepozOpN
 Ka0UhaawR15tRWA==
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

