From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 08 Jul 2026 03:24:02 +0800
Subject: [PATCH RFC 1/5] mfd: ls2kbmc: make a copy when parsing mode string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-ls2kbmc-mod-v1-1-c344bf5defa3@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2387;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=d6uhdZv7x5iOz3ifWFtBF4oUUkQDTINp64mnSnuoNJE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTVJb4QTwB1OpvJ4G88AI6IC3MNIFvGsmIJjKn
 sBXXUXy1bGJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1SWwAKCRCwMePKe/7Z
 br5YD/9+RIERHl2TJwF1ydYg4FhOaUq2+oLu1kDgE7FYsi4GCjXO9tnc8R8tzEMrgNzOfg+WEx4
 DC/WHV933JiFJnH7Rmfwi2YPwwgP3/Tfu558v0QTGI7qsA+Cr4b/SPDmaD8R6GUsHSOXNbnx4dq
 IQC75Z4NauIVQ/royOtrMhDy2wUq3QfmDI7FB4+OgX5GTuNdfNnYtxICLC48H4wWyDsQydXWmrO
 lkCeqGF2545CsOSUC3s1oCaYCLt64ZeX3RY9Z0WDtloX4xqVYrSUYROTs4iMDLmN2fvhgXVewJz
 /hXWrM93uFydUUNZlGzYJ+TS422yWo+YY3rVeCGtKOtTo92HlcUHbgHZrZvDiuxXgB9F+gdTou5
 QoQI3lH5EoJxc55Sn/mO5zWF+9c32CPrjyDszN1R5FBCwwOcnsGqb8QSzq+nIMwe8xjOWZtsmZf
 +Z2nQ5DAiRhR1Fq6rCm3IKWRdcMGD8un1Terq5WCI8l3md9hvitg68eQbboNEKy2EAV3CyfTBAc
 Pkv7roh0BYPQ3e7/UgR5vIGh8a2M3dT1s6Uyu+ASDj9b344aZaM+b2eDPml4peg34w9MKXZljr1
 6wIhuIAuIZ6ZFJ+ivQvMgwCBYH5OXruI1RnOOP4x6N+R9UZNgWJdqYXweHAox4L0kOmYJYZhHNR
 62i+gDzCy23uSzA==
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
 drivers/mfd/ls2k-bmc-core.c | 25 ++++++++++++++++++++++---
 1 file changed, 22 insertions(+), 3 deletions(-)

diff --git a/drivers/mfd/ls2k-bmc-core.c b/drivers/mfd/ls2k-bmc-core.c
index 408056bfb2fe757a5bde43775a483a48352e706d..30b275bc48794a22249aeb8ba805ef78772d3466 100644
--- a/drivers/mfd/ls2k-bmc-core.c
+++ b/drivers/mfd/ls2k-bmc-core.c
@@ -427,34 +427,53 @@ static int ls2k_bmc_init(struct ls2k_bmc_ddata *ddata)
  */
 static int ls2k_bmc_parse_mode(struct pci_dev *pdev, struct simplefb_platform_data *pd)
 {
-	char *mode;
+	/* Assume 1024 bytes is enough for the resolution string */
+	char mode_buf[1024];
+	char *mode = mode_buf;
+	const void __iomem *mode_base;
 	int depth, ret;
 
 	/* The last 16M of PCI BAR0 is used to store the resolution string. */
-	mode = devm_ioremap(&pdev->dev, pci_resource_start(pdev, 0) + SZ_16M, SZ_16M);
-	if (!mode)
+	mode_base = devm_ioremap(&pdev->dev, pci_resource_start(pdev, 0) + SZ_16M,
+				 sizeof(mode_buf));
+	if (!mode_base)
 		return -ENOMEM;
+	memcpy(mode_buf, mode_base, sizeof(mode_buf) - 1);
+	mode_buf[sizeof(mode_buf) - 1] = '\0';
+	devm_iounmap(&pdev->dev, (void __iomem *)mode_base);
 
 	/* The resolution field starts with the flag "video=". */
 	if (!strncmp(mode, "video=", 6))
 		mode = mode + 6;
+	else
+		goto invalid_mode;
 
 	ret = kstrtoint(strsep(&mode, "x"), 10, &pd->width);
 	if (ret)
 		return ret;
+	if (mode == NULL)
+		goto invalid_mode;
 
 	ret = kstrtoint(strsep(&mode, "-"), 10, &pd->height);
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
+	dev_err(&pdev->dev, "Invalid resolution string: %s\n", mode_buf);
+	return -EINVAL;
 }
 
 static int ls2k_bmc_probe(struct pci_dev *dev, const struct pci_device_id *id)

-- 
2.49.0

