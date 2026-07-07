From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 05:16:29 +0800
Subject: [PATCH RFC v2 5/7] ipmi: ls2k: Relax the dependency to its mfd
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v2-5-2afdd1741766@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1266;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=DqOdU6W3FkZ9wJNJOs/NgLGl94jX8Hgep53VmIhV2nQ=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWy2XVz3ApPzEdI2SNhXBf238YqE2zwfSBpMH
 n2WUuN0u/qJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1stgAKCRCwMePKe/7Z
 bqm3D/9MQsw3k6073js/YOH+ZqftmgwO0Qr/Xgp34IMKDpI0yn6rhiBQosfTMezUAR80LBNkna8
 ilD1CFyinknMotXTgdXrlOvnSZjiKyGklxqxE2n0S/06zW/g0h/+afcbVt3QU+Fg56PnA9jkTEl
 XwfGkMUztR9Uu0qKgdOKVbRrsat81c+MAukc5WUQZxvsJT4q7+sl5YBrsHtPuVfyRVYulaCaA3o
 FoJONlDolngJBeA+C6EkWBOwhgwYkEfG6oazUEfplISSNwEvTMR5cZmjZJNgiPEFTmkxdN2dt3k
 MMGlmUUnSelp3wUxGct8iWe1ET+oNnLbfQu7AfrMF7pRn+50SSr07hS0iRO6uMgqvIwOgTRQXq8
 so63iYVmXKVSqDXOubeoDxchwdU2TiXGHavo64e54ocPP6WFtdp6kyG9Be0dGOEH0p4Wqr99pIW
 cWbZ47ViOSiKaaCcsfiRafJVFT2uvaxt0bs5krm6CFAuwer3zOm8QZ7qEN+nl9EWa4cKlls/GTg
 rSDkb6swFRCpumcsL0UpN1UVBicky/nc9e97TBaUxPx3g62i//XurcH0ZJK9a0k7wNYiLLsVqBz
 F42S/Z6qTPPa3+p5K/NciUZz8ECNitFwf5fKuOGiA89rktA9TKcJgHm6R4yUl2K73KTbVKsjyZN
 vsKQ7n05YNuXTYQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no strong dependency between the IPMI driver and its mfd
driver. Although the IPMI driver will not work without the mfd driver,
it is not a hard dependency. The IPMI driver can actually be compiled
without the mfd driver, and it will just fail to probe. When the mfd
driver is loaded, the IPMI driver will probe successfully. Therefore,
the dependency of the IPMI driver on its mfd driver should be relaxed
to "imply" from "select". This will allow the mfd driver to be compiled
as a module and the IPMI driver to be compiled as a part of the ipmi_si
module.

Fixes: d46651d4e3c0 ("ipmi: Add Loongson-2K BMC support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/char/ipmi/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/char/ipmi/Kconfig b/drivers/char/ipmi/Kconfig
index 669f7600019747bcd2b37563477cf336f19a0407..f456e3e89416932f0d21bb742153a503aeb24267 100644
--- a/drivers/char/ipmi/Kconfig
+++ b/drivers/char/ipmi/Kconfig
@@ -87,7 +87,7 @@ config IPMI_IPMB
 config IPMI_LS2K
 	bool 'Loongson-2K IPMI interface'
 	depends on LOONGARCH
-	select MFD_LS2K_BMC_CORE
+	imply MFD_LS2K_BMC_CORE
 	help
 	  Provides a driver for Loongson-2K IPMI interfaces.
 

-- 
2.49.0

