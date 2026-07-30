From: Miao Wang <shankerwangmiao@gmail.com>
Date: Fri, 31 Jul 2026 01:03:22 +0800
Subject: [PATCH RFC v4 1/7] mfd: ls2kbmc: Make a copy when parsing mode
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260731-ls2kbmc-mod-v4-1-d201502ba239@gmail.com>
References: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
In-Reply-To: <20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2561;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=6DIyNM6vk8kNUgYv2UMACNnAgWrwjVEMmwrMrjQaG1w=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqa4PjUaqGYl/WVatdOZe/SdbX8EQIZBwhvmvr7
 ghslqSIRCaJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCamuD4wAKCRCwMePKe/7Z
 bo/MD/9o/aNJDVHGcU0YThjfIZvV1S2VMeBKP5l9hkppTDd2H3BcMO+YT6xszLIkKFP2QV0JSR8
 ZtuC4rW7HCSjTU8kcXKQTO9pJLTmZ/WCbt9j9ys8skuSPQ9M4hoXLrnmcobl+bqOku9zpomb1Fh
 lGYZaK1KucymrGEvP4LauL+tmA5K5nHtzcOGm74cUyY3EVRNx+FPeA4FP06z3dh+5oLPEv7SBAN
 of9OZ/u8yMzuUOGuJ+OTidRkHDEWC7mu2JjNIbiXdrJsh7rQqxyO/aN0qiVLFR61TkHTAF95IrI
 fdiivfLJji4xy0gLDNTH5Ig88qXD9mzYzL1s/kLNW99bzE1YBTbYRvPWl8KC73yP6ne2KE0jqK6
 OEV/tRyvXbItC3eUPm7XznaEOKKnzoVAf+Nn/UA4UCAsmLS/fIu9M5+GQIL/bw8Af4OnOjLsCqD
 8tj5TYYq+vfg25tB+nnzIItQX9B4Fe3weeBa/nqYj+bX5r20MxCGnnS6A3o7QjErJU8zTbWAdRj
 0KoN2Ew7z/zxYVYpHJXpF3BefEL7NECF550oJG41xtLurErBlmpW9JeK9bDoPNlq+LgvMq1EYfO
 fuEG3o4GxXUcSk88tZMO9C7mtBcJjwglPFBYkFreQ6m79CGDROnRSTzhIXLaHATFJwSwTCSave8
 cY4YL7ns4s1KtNg==
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
 drivers/mfd/ls2k-bmc-core.c | 30 +++++++++++++++++++++++++-----
 1 file changed, 25 insertions(+), 5 deletions(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 408056bfb2fe757a5bde43775a483a48352e706d..27f6e096404d67459038a0607378057ec7ef69ab 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -427,34 +427,54 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
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
 
 	/* The resolution field starts with the flag "video=". */
 	if (!strncmp(mode, "video=", 6))
 		mode = mode + 6;
+	else
+		goto invalid_mode;
 
-	ret = kstrtoint(strsep(&mode, "x"), 10, &pd->width);
+	ret = kstrtouint(strsep(&mode, "x"), 10, &pd->width);
 	if (ret)
 		return ret;
+	if (mode == NULL)
+		goto invalid_mode;
 
-	ret = kstrtoint(strsep(&mode, "-"), 10, &pd->height);
+	ret = kstrtouint(strsep(&mode, "-"), 10, &pd->height);
 	if (ret)
 		return ret;
+	if (mode == NULL)
+		goto invalid_mode;
 
 	ret = kstrtoint(strsep(&mode, "@"), 10, &depth);
 	if (ret)
 		return ret;
+	if (mode == NULL)
+		goto invalid_mode;
 
 	pd->stride = pd->width * depth / 8;
 	pd->format = depth == 32 ? "a8r8g8b8" : "r5g6b5";
 
 	return 0;
+
+invalid_mode:
+	dev_err(&pdev->dev, "Invalid resolution string: %s\n", mode_buf_orig);
+	return -EINVAL;
 }
 
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)

-- 
2.49.0

