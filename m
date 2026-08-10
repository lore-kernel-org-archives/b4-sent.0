From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 21:04:31 +0800
Subject: [PATCH RFC v8 8/8] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v8-8-16e44f7322f4@gmail.com>
References: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
In-Reply-To: <20260810-ls2kbmc-mod-v8-0-16e44f7322f4@gmail.com>
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
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecxjuLocFhKFEGmvnRkYvp85MXealIssarLZz
 Sl4dMs4LAWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannMYwAKCRCwMePKe/7Z
 bnlWD/4xgfwlalceBe7M+T02Baov/hJBfeEDrnZ71V7LuqCm04rJwAi40oOmMSXwptRb7Vl5rnZ
 /FBmYxCz3Zz4QCTTn6s/cE++8hjhoolhaM81DdSAGEdrXb/5wM8owRrlMuUGzr1sKVineRXUri3
 0NLNVynA1fJ6pL+oWKK6VV9y+8bPpKp4M5VU6MT+t6QIHt4KfVPELpyozkCSYe8txtTdwfnOH0w
 llp8N+DZaaHFgiXQuJaOwV9FjdksyRuiFFb4PaaVBKs8HpWeSMqneYwkDRE8XOUidq91eIY4sa3
 X+c8VcSpei2h8rv4LPQV8tI7QF7UUqlqQSygNLE81r0jswQZEZsjTzNnkOyYCj3UW5yOGHPnpFq
 5B+sgga+t1Yh+Q1+RKQcnHNTJ2nqWx+NMvnmI3heCQ6Ydd1GhbEgi9Q1uHErPTLabpfm5mv36k7
 uvGpEX9DyywKkgEsXpIdqY98kIHVgznUlMSA/rSSHjvx1dyFmlJiQqALcl+YyPsLvm+60sumMov
 FeUo5dfNI/W2kGPwiYAShSGgMVgAM50nKvwRAvmFeqc5xTlONb+P8KMhULsACmnJ2MZyw+C89Me
 Y0m9ElY9DTA1Kl2mMYI2H9+uFShq52IQlW4z++2OLsF8rDz3J59ZAPQA5pJkfTSY/5IC2I6lBWq
 +TbRUt9j12MyAiA==
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

