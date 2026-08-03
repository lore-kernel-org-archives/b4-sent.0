From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 04 Aug 2026 00:55:49 +0800
Subject: [PATCH RFC v5 1/7] mfd: ls2kbmc: Make a copy when parsing mode
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-ls2kbmc-mod-v5-1-e6bc5cdd9a93@gmail.com>
References: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
In-Reply-To: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2609;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=U6cr9tgtHDx0WKodEY4FvK4JRMLlLLDCHMpw0TehXDs=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcMhKI8yWfAOidTLPqzOGA8PA9CkgvMDA2n2Rl
 1cfvBzkERGJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanDISgAKCRCwMePKe/7Z
 bt9mEAC7giJ3sZf0D0yS6L8QLrl7uWy1J7eCaPg92jdlM22hi7UfbXJYQxa8EK1fzHypR1piiOo
 fH5KIjmEhIJJ4bPdXt894GfCFWWygal9PlH9Yn89V1utIX9c8GLlYXpq1I5Ih3846w63yfbx9nB
 vuWN1HEs97eWQbwAc8qXjr+xvbNz/dVcKo+CuW1AKbYh+VCA6A1ZC5oI23Y96rlCdyYLiADDzp/
 4a3Z44GJvBkfhXy2eMw7Azq006rs+KuI2DcuoEV7449s7WIbBkm+CV8E+IkwBziyO9MszjcoM46
 vxwAApZvLx/gTxI5+r9hZHck8rqFRABJb2wzH/mCdGbaW42eF03J7rcktAQHfQ8B3V7B4sUSxDF
 8fDoc9l1Vsb9BHu0C7QXiFl4a29bx2XYy7JgzdQp8AxzfhBR3cjfPIla3ZbJiwTyY4OnBp8/nuy
 RxYVvGipb3RamdX30kIMxgxFCDU8iyYKvkycMSZHa0ycNktwzIUKIwfpVQcvFNOIedEtpsG5GZq
 L5YsFs/F4D68cuOKuOsI57zawn/x+QV6/WYyKocykK/glxiec4/ViiJVWwNtnAgCNFhuoEwWWkV
 wKYzeJjycWCuFdA4FRMb0MwIwAkoLHVsNYi9qxX/QbiQ1ywRxYaeMpRfGlWNYHoHGR8RcBzOI9d
 Xw2GRhJp/x5LMNw==
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
 drivers/mfd/ls2k-bmc-core.c | 36 ++++++++++++++++++++++++++++--------
 1 file changed, 28 insertions(+), 8 deletions(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 408056bfb2fe757a5bde43775a483a48352e706d..fc9695eedd3662ac92ff116811bb07bff1c994ea 100644
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
 
 	pd->stride = pd->width * depth / 8;
 	pd->format = depth == 32 ? "a8r8g8b8" : "r5g6b5";
 
 	return 0;
+
+invalid_mode:
+	dev_err(&pdev->dev, "Invalid resolution string: %s\n", mode_buf_orig);
+	return ret;
 }
 
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)

-- 
2.49.0

