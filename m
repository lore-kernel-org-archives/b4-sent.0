From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 10 Aug 2026 20:25:32 +0800
Subject: [PATCH RFC v7 6/8] mfd: ls2kbmc: Able to be compiled as a module
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-ls2kbmc-mod-v7-6-8aa0fb5a5462@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=726;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=4cYoUAWfr6lC2eTeoh29c5JZOLqOi/IiHDJf/iiky6g=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecNK0qg/Jrjw9Ll/FOMMe2v4VrXstJSrbKo1T
 0g6uyqzZI6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannDSgAKCRCwMePKe/7Z
 bmdXEACUGds/nD1M/ElkbmFm5dpHvSWni1XBM8ta7+UpMn7UJDVmG6j6NP/OnyknmR1f3GuJabc
 IUiA5y5lM3RtzP3kH0ei8AET0QU++Jqz5spcpfTkPqwl62xexWiK/+FTp8LayV6oFGlWAn6zlVQ
 3hazb/MzsEAB+bNSHDtJ1My96tVoczHn560d9jqijiskIadHTn5Kpy123QVwzb61T0ClnAp+tM2
 s7AMmKN8PM4fpTCxhgY8wA+4VoKTvBiDYiwX2ebQzx6Owf7oE3qjSZfTV5gEA2JHL7tbNS6DqIX
 6Dq50ie5/hb0u9serMr++x+rSh+FUjrGHyowikPS+d8l/LnEbiFKtIErPrN8/+hdtPELSnz50M9
 aUdNoY39nNBNwlKuAZuXebaG1VNjxErAw1SeqKerw5KE+51C/s1ilkDLcNSMvmOiOi1y/Q+dzuz
 SdiBN8/tMRTaDhMylT8+xyt8K48EJr8sBC6QBE+zAzY8ZhrrRQfnxdZr4cUYHc9t1XTKqNt/o6g
 3Nduc21OHEAHp8GycA4Oz/ufws6H940Z99eFKkrNUmjIkBLrBIletqLUOc17SLCjbGpz/soSa+S
 iw95vRAEpWmY/CkRky/9e3YxxMNSKhGQbd88gseh/N1ireVQXiuHRRAjEm8MyNQcjZKi6PAOEm1
 NdbW8oyhomPvSqw==
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

