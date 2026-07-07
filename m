From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 03:24:05 +0800
Subject: [PATCH RFC 4/5] mfd: ls2kbmc: able to compile as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v1-4-c344bf5defa3@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTVJcD6gGVO19zp22QalNg3kYFTI65qqdenkl/
 4gffUKG/WGJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1SXAAKCRCwMePKe/7Z
 bujuD/9e+pw37MQ1Ut4nArqo1WnTYudvEnOf3F01zpsQEuZgotjmmNzoUrcWstURnBp4Gs34Awn
 T+Jzyb7F6TvGuUrsjY1ouyQs09YinguulPLVlnq9WmnTAL1q5AHFf/E8uGIwWWpnWhO1V7GURae
 j4mCX37YToVd0m1gJ00737uo2TxD3WIu8kA2SmtkYy6Aj6ZcVpHJXBDqHJ1pHZ3HKIc0Wt2zM35
 Dd6KY4pyiLsHjqvdXot2X37y2fMh05hUskbacaopZvCCXsIHNUOfkCZGzA0oVeyRCPKDlrrCuAq
 WuplFDQ9SDlxlDKDYzTgGSG12LYJEEY64+YHa/QxZqiF+JpfTMwkGRNoHXb97yzNihwD9HeSeHL
 z7nkv1WmM4+LC9u56q7skFZKXmYS+c/7YbDiToFBL+ioDbHCic08pnB0ipjA5QT1cl4Gx20ixlG
 a4igooveqoW8X6ttHrnSyFyilF4TKfD4wHgnAzWEtgTq7QIWK3J5CQdz4Yi47gK/MaBDufdQU9h
 9QjFIx/fCh+HbYF08NNvdJbp/0ib73hGmbEMikWMWUgEelBOy7UsEJJ/xKCiha1neR8idTgh/DU
 oDtT1voZvJTNTWamSdd1G0EG4vnn4wJk+V7IrjF9t0Bp0lP9wYz+6zjm5qxa9BwycD7MMILC230
 6T0UMn2RTf8Vcbw==
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

