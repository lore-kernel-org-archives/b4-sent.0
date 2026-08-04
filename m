From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 05 Aug 2026 03:14:24 +0800
Subject: [PATCH RFC v6 6/7] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-ls2kbmc-mod-v6-6-16ccde412d86@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcjoXquxcExGmzNKNXqYe7lZ4evwBVXc1tACpJ
 i0Ow1+hDBmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanI6FwAKCRCwMePKe/7Z
 bs4xEACkkjPoZ4frourWCDrLVpnwZ9g19IY2JK5fzIO+yv+/MQCFHhE4Mq95iixKs3B+MD6TeDT
 LN8Ifak/NYu8GfEXxBouT3L3eWE6EsXmzY5iX3g9gUueoqYodDdN9CeGi1IgH8E7W38DWE8zLBc
 8XHuc8jeBIGvJVnRXBZ4EfFK0eRCyR6J/PmdbFngQuMYa8Qm58otmF1khLZK6t5PgNQLpSdAtMA
 N1enra2L64NXrxU9VbHeIrDBVFgVp5sJZjD+/4gXrBdwQHcH/eC+Mj9YnbKZLlMqETn8T8RFRfK
 2DqejuN7KCisXKeiMl1/DJxOe0VIJt13rBMvF9X2PSIAxjGeYKxlxOS6EJP+yYFm/yv7XGkUnq+
 SnQ0o49C4eMFeJPNYCaoMsvGY3tC49u4s9zzMw6Fh072G5iFxjO5/g4E/KeLoHVOGGXj/Mf4Jxr
 abSRCGp6Wg0gTBQ0Ej1bshsrv0bF419ptqKMS0YEEEhAUSGvUmF0hf3Xxs2PrPKyAXfuSm+dp3V
 ZDA3gGQNBIbgSKOEwTWbjqBoQiCyIqOv4oQltvx0xwixpuhVpoxh8syFbaF1+SlMPSn9BCRgBGG
 UyyRmiDoMuCSldRqDu0magRLYknzUgMTo3wFv/3aCyKLJyC8PL+qT2gJgM827hOiImWk8PYz7dn
 YaGvYi613XlEIVA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make ls2kmc able to be compiled as a module

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/mfd/Kconfig b/drivers/mfd/Kconfig
index 763ce6a34782bdd5d2b1a4d840c75b040092d83e..a7a9f97af248c88489dc1203a1ba05f2ce4827df 100644
--- a/drivers/mfd/Kconfig
+++ b/drivers/mfd/Kconfig
@@ -2494,7 +2494,7 @@ config MFD_LOONGSON_SE
 	  which will forward them to the corresponding engine.
 
 config MFD_LS2K_BMC_CORE
-	bool "Loongson-2K Board Management Controller Support"
+	tristate "Loongson-2K Board Management Controller Support"
 	depends on PCI && ACPI_GENERIC_GSI
 	select MFD_CORE
 	help

-- 
2.49.0

