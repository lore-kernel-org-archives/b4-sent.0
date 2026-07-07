From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 05:16:30 +0800
Subject: [PATCH RFC v2 6/7] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v2-6-2afdd1741766@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWy2BtfGvpZzh4Pe7QoaJHUEnS1gewIilFlrR
 AgJBRH/0uqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1stgAKCRCwMePKe/7Z
 bjGVEACrkaxJ+WPSJPiFGptWyPSHBxCT2vI9TjVYUdcIQd4PMAgd+5Mk632EBhYZ74UobzVKiWo
 vRrpV0226ZpY2w7qh6R9BV3wahykB5psUkFQ3K/yMPXUgqFDzFnnYI80/wZlVlRWWiqfEyKYN9l
 Cx39oF8SYR0dVn/Emwu3rdELrOomDXb6owRNCLTOJpAro47Bc141rJYbsO9I0AP+HAwAXobnOqj
 Pt2a9U5AyBGBnC25DAo8PFXD56bfzCuuzq4vDnzWtvM6vcO3IgB0S3LIID0GNvQ6gbai430lmP4
 A6uzqXSG6LxuhT/I/zdckNB2BowIO4y2hh85V3OFjES0+foWD26BWYMS+p18m7IAGIv4tBqSjAU
 VnS855yOsD9UlWvA+0MZajg2gQjG74HfBT3NAfRXuHCjtw00ZXly0S985j6nR9pXTtVlgfBJH4F
 SK+ZDYb78UW4BlWw9fTdyGDPkv5FCzwurDA0kWN2VPtskioMdLwRjtUO8IzOCj17kZ7dWueio/R
 oC7Ij34PskzdJdo1FjqowRPWCwcaWODz6KUH+UT+jaYzd+RD8Z5i7eGkZJFLGZ3blJajnt3E5Iz
 ZujniJ+Mxe+Kfb5xzIJ2oUhWJb98WBDubLoQpT//lXU+sq3LOW8M4AksTRGCB4XmA4Pt793rcpG
 AxDaSAyc80TTJ+A==
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

