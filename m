From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 11 Aug 2026 16:07:25 +0800
Subject: [PATCH RFC v9 1/8] mfd: ls2kbmc: Make a copy when parsing mode
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-ls2kbmc-mod-v9-1-4fa9a5584406@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2931;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=JAJhKtMfhB8SZK77fsh9uMLhohDQu5vL9aOCwD3CkNk=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqethM5Tw6frJWDr4Hu15fSvxKUyL65VTimNxTS
 AxxPRNnL9mJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanrYTAAKCRCwMePKe/7Z
 biTmD/9F+xqO8ncTmdLs+Y3bXQQKsoQQdrjW3It6VkzTOx16OiX7ANlpj+JOxDYnZOAKb22lmqa
 Nb6D8tRh8xN1kTQSTxVEcXIUr+M/0oNOZO7U2iXPNiV29L8E4DP63oyDFUYiNdAzc8YpIzIZrEE
 tCdTFqTHqr2hwAaBnOrq5fTrdzHyeP/7zToOefQyWhn1/QThZZkT+Jw2Bq6+oKFNvFDCYbeiwxs
 qBEdhnkQVIJV4kYrUzWUMC5lyxUjhClhANkjCje6OJfpumNKH0NFjSqOl0oXcxtzxNIWwERQwUp
 KPYIpLdf8vh39lWeY+14cVGD9RWQL3Ox8iXeqFC+0tcHUMsV9saisy4M5budxW9GdyjwdafpvLa
 P6PiGPMFyyKVlbwtJ/9KH3/EWKHdggAwFJYOLRTtvUUCHzPKmUXbvr7/YRs5SoRbJER3y08E14P
 iuJhbmkDxQpGfxUVttS+Dg0yqcFLSmLhK884yD8mU4Kd1Owp2quZwWgk58E0k05xiG6NEg09DBH
 GHjTgCStfQHwD+PLjwD6IxncMg1N8ZlcGm0U+suJmY33sZfI4a+NKCcO/y+xAc90UnUEtRMbpfG
 EYVDSZMUFQ/lM67V46iMIwrXfNcLhKHMnBH9mJs02YE5ggONlrhBbLK2u4kppobTgBj2Dl0RW46
 MqD/ml+ejr7kenw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When parsing the mode string from BMC, the string is manipulated
in-place with strsep(), preventing from parsing it again. Make a copy of
the original string and manipulate the copy instead to fix this.

Fixes: 0d64f6d1ffe9 ("mfd: ls2kbmc: Introduce Loongson-2K BMC core driver")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/mfd/ls2k-bmc-core.c | 51 +++++++++++++++++++++++++++++++++++++--------
 1 file changed, 42 insertions(+), 9 deletions(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 408056bfb2fe757a5bde43775a483a48352e706d..335590392240ba1e13a2bdf6f9f4efddec045f40 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -427,34 +427,67 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
  */
 static int ls2k_bmc_parse_mode(struct pci_dev *pdev, struct simplefb_platform_data *pd)
 {
-	char *mode;
+	/* Assume 64 bytes is enough for the resolution string */
+	char mode_buf[64], mode_buf_orig[64];
+	char *mode = mode_buf;
+	const void __iomem *mode_base;
 	int depth, ret;
 
 	/* The last 16M of PCI BAR0 is used to store the resolution string. */
-	mode = devm_ioremap(&pdev->dev, pci_resource_start(pdev, 0) + SZ_16M, SZ_16M);
-	if (!mode)
+	mode_base = ioremap(pci_resource_start(pdev, 0) + SZ_16M,
+			    sizeof(mode_buf));
+	if (!mode_base)
 		return -ENOMEM;
+	memcpy_fromio(mode_buf, mode_base, sizeof(mode_buf) - 1);
+	mode_buf[sizeof(mode_buf) - 1] = '\0';
+	iounmap((void __iomem *)mode_base);
+	memcpy(mode_buf_orig, mode_buf, sizeof(mode_buf_orig));
 
-	/* The resolution field starts with the flag "video=". */
+	/* The resolution field is required to start with "video=". */
 	if (!strncmp(mode, "video=", 6))
 		mode = mode + 6;
+	else {
+		ret = -EINVAL;
+		goto invalid_mode;
+	}
 
-	ret = kstrtoint(strsep(&mode, "x"), 10, &pd->width);
+	ret = kstrtouint(strsep(&mode, "x"), 10, &pd->width);
 	if (ret)
-		return ret;
+		goto invalid_mode;
 
-	ret = kstrtoint(strsep(&mode, "-"), 10, &pd->height);
+	if (mode == NULL) {
+		ret = -EINVAL;
+		goto invalid_mode;
+	}
+	ret = kstrtouint(strsep(&mode, "-"), 10, &pd->height);
 	if (ret)
-		return ret;
+		goto invalid_mode;
 
+	if (mode == NULL) {
+		ret = -EINVAL;
+		goto invalid_mode;
+	}
 	ret = kstrtoint(strsep(&mode, "@"), 10, &depth);
 	if (ret)
-		return ret;
+		goto invalid_mode;
+	if (depth <= 0) {
+		ret = -EINVAL;
+		goto invalid_mode;
+	}
+	if (pd->width > U32_MAX / depth) {
+		ret = -EOVERFLOW;
+		goto invalid_mode;
+	}
 
 	pd->stride = pd->width * depth / 8;
 	pd->format = depth == 32 ? "a8r8g8b8" : "r5g6b5";
 
 	return 0;
+
+invalid_mode:
+	dev_err(&pdev->dev, "Invalid resolution string: %*pE\n",
+		(int)strlen(mode_buf_orig), mode_buf_orig);
+	return ret;
 }
 
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)

-- 
2.49.0

