From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 11 Aug 2026 16:07:32 +0800
Subject: [PATCH RFC v9 8/8] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ls2kbmc-mod-v9-8-4fa9a5584406@gmail.com>
References: <20260811-ls2kbmc-mod-v9-0-4fa9a5584406@gmail.com>
In-Reply-To: <20260811-ls2kbmc-mod-v9-0-4fa9a5584406@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=727;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=UkpVPtBCUcqPjbP+E9BhIFiau/5G+QeU7wsp0vFpbTU=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqethMWV2qXS58xFfnyVtc9+wioVm8Kh4sBoBiV
 pryLDceLX6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanrYTAAKCRCwMePKe/7Z
 bueaEACGsvnW1rziCnhuVXB+rj60QbepcXFUhcfymHjD9/vP/7IOUOjdxdre9+WYkp243W9fho/
 e5O7tR5FA/4IV087cymr7XZ9CJMUtPE26EmX0eE2qIxWTG4pNkv469yCe2UqEuErPTwHNrZQOoU
 7pVc2h+HKdgFXDoimOciguf8yC//dqYeEv8optTX8Ky2LR7AzQ+X9jI0hdXiDFHEpKA96Xj0673
 Pc2JCdxIEEzoqeyQSlePezWuqIvtO8IpIiw72iR69fg0zjejqhGjXjbaZcM7j9Juo9GGdqNFfA/
 08CoKL5wgejhkOafxdXjHxLBtBvT+iCgJk8BfQp5snip0gj/nK0kWjmelr+OAEhde3UgOOt4gft
 YlsIAW9LdX+Yo5IdvnzbSD791Lfh5etds1b+crw2ewCUGDB4B3W49xDxiMVVZpaGsg9SJQ8ZZJY
 PQJX/+Z72kOONVaId18oLbo16RmJDRO2A1KXFzoF+FAcBdJI+gvY4afZrAklmcMdh6A+zsnh/Wc
 DwxijvrggBDD9nOhGKcuayEOBl3gJTH75NVuKjahk3TO5baUw0/uAR97Ztuj8nDTJpdMOgNRRd4
 CuHewcm7WS6ozePJqCvFvb7TjQYvhKRoUd0z7esjK+ffp4PqUyrWcelPGOY3sG1fm4SVmZ5i3Vf
 uEFiKeESkHFNKOQ==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make ls2kbmc able to be compiled as a module

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

