From: Miao Wang <shankerwangmiao@gmail.com>
Date: Tue, 30 Jun 2026 05:05:28 +0800
Subject: [PATCH RFC] gpio: loongson-64bit: Add back the support for
 gsi_idx_map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-loongson-gpio-v1-1-576908831fa0@gmail.com>
X-B4-Tracking: v=1; b=H4sIABfeQmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM2MD3Zz8/Lz04vw83fSCzHxdA0uDpCRDU8sUg1QTJaCegqLUtMwKsHn
 RSkFuzkqxtbUAIIfJuGQAAAA=
X-Change-ID: 20260630-loongson-gpio-090bb159d0e4
To: Yinbo Zhu <zhuyinbo@loongson.cn>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Hongchen Zhang <zhanghongchen@loongson.cn>, 
 Liu Peibao <liupeibao@loongson.cn>, Juxin Gao <gaojuxin@loongson.cn>
Cc: Huacai Chen <chenhuacai@kernel.org>, Jianmin Lv <lvjianmin@loongson.cn>, 
 WANG Xuerui <kernel@xen0n.name>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 linux-gpio@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3795;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=BhI6w+XNK6JQEt3uJcG82aV3eTG42V7G0R8z4wU74xU=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqQt4eD0ePio5j4B0x4KdoRtgFJPVvP5IqAGZeQ
 ExQB/17HZmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakLeHgAKCRCwMePKe/7Z
 blfUD/wM97+pH5K7X/5ezOgWWCFgnljEl2Nbt2LFczm+QruBFDgV2SWzKisaa6KOeN/sxeZVCWr
 8/Lg4PyhSJkZYwD46GOElPiHha5orzcAks/lUxiup6oh/aVJuvsgn5v0lWq7Mj/nE0YaDONfTA7
 5TziKjvHn/CidqtydDL5apjkKMAqFnqPEqXt89D/TLSB1HREQizEEgQD9JB+1T3r8p8/b79RWW4
 4UYv1JLToHLPa3HsuBw07Ba5zXQxnDf4Sk2GJGlhATRac5fjXjQ2lWIc+Ud7cotPSJtvdQyeutH
 1+CIhm2yfjtV21q8YJXN4Bge26BYc9+OCC5Eu2yOSn7GEp99BfIwINpKvdXWGnQCMaTNxLZOVxR
 OSEscqVNmiVjP3suVIQEJWeKvx9zHZFFdaGI4QPicNTQyWQs2TJ1kqK2A1Q2eqzdPx+MmgpmVYC
 PMmTTNxYoMoZ8g8F254UvluHOaoIVIvqiF10WWfrN24OBRTnHTkRAoai4p8hF/ScWrMCqgLx9TM
 fTB2ki8fidfTAG1JwzaiHW4zlVaEB3LttVdbBiZBrZ+f3hGqkq9u5mhenfXJFd5NCjEVykOnaLk
 dVxewNqkK4rxF+I5AVSKIFUJ8iPfdntrqdNtbTPEBcQDDFoPxx2YNha2euUYOe2UL1Jn3PzwrEl
 4ojrTw5zCAngxzw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds back the support for gsi_idx_map, which is used in the
ACPI DSDT table to describe the mapping between the GPIO line number to
the index of the interrupt number in the declared interrupt resources.

This property was removed in Loongson CPU Universal Specification for
Interface Between PC/Server System Firmware and Kernel v4.1 in November,
2023, but still in use in firmwares released this year. A sample of
an affected DSDT entry from a 3C6000 board I'm currently using is:

Device (GPO1) {
  Name (_HID, "LOON000F")
  Name (_CRS, ResourceTemplate () {
    QWordMemory ( // Omitted, not related
    )
    Interrupt (ResourceConsumer, Level, ActiveHigh, Exclusive, ,, ) {
      0x00000010, 0x00000011, 0x00000012, 0x00000013,
      0x00000014, 0x00000015, 0x00000016, 0x00000017,
    }
  Name (_DSD, Package (0x02) {
    ToUUID ("daffd814-6eba-4d8c-8a91-bc9bbf4aa301")
    Package (0x03) {
      Package (0x02) { "gpio_base", 0x50 } // Ignored by the driver
      Package (0x02) { "ngpios", 0x20 }
      Package (0x02) { "gsi_idx_map", Package (0x20) {
        0, 1, 2, 3, 4, 5, 6, 7,
        0, 1, 2, 3, 4, 5, 6, 7,
        0, 1, 2, 3, 4, 5, 6, 7,
        0, 1, 2, 3, 4, 5, 6, 7,
      }}
    }
  }
}

As can be seen in the DSDT entry, the mapping is essential for obtaining
the IRQ number from a GPIO line number. Otherwise, when IRQ is requested
for the line numbers largers than 7, it will fail with -ENXIO.

The code in this patch is mostly picked from the version 5 of Yinbo's
original patch.

Fixes: 7944d3b7fe86 ("gpio: loongson: add gpio driver support")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 drivers/gpio/gpio-loongson-64bit.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/drivers/gpio/gpio-loongson-64bit.c b/drivers/gpio/gpio-loongson-64bit.c
index 0fdf15faa344d2db0a1cf52dc52c3f58aabef49c..bff7d70e7470ea930ba29504533f11fa92e17620 100644
--- a/drivers/gpio/gpio-loongson-64bit.c
+++ b/drivers/gpio/gpio-loongson-64bit.c
@@ -46,6 +46,8 @@ struct loongson_gpio_chip {
 	spinlock_t		lock;
 	void __iomem		*reg_base;
 	const struct loongson_gpio_chip_data *chip_data;
+	u16			*gsi_idx_map;
+	int			mapsize;
 };
 
 static inline struct loongson_gpio_chip *to_loongson_gpio_chip(struct gpio_chip *chip)
@@ -145,6 +147,12 @@ static int loongson_gpio_to_irq(struct gpio_chip *chip, unsigned int offset)
 		writeb(1, lgpio->reg_base + lgpio->chip_data->inten_offset + offset);
 	}
 
+	if (lgpio->gsi_idx_map != NULL) {
+		if (offset >= lgpio->mapsize)
+			return -EINVAL;
+		offset = lgpio->gsi_idx_map[offset];
+	}
+
 	return platform_get_irq(pdev, offset);
 }
 
@@ -326,6 +334,23 @@ static int loongson_gpio_init(struct platform_device *pdev, struct loongson_gpio
 		lgpio->chip.gc.to_irq = loongson_gpio_to_irq;
 	}
 
+	lgpio->mapsize = device_property_read_u16_array(&pdev->dev, "gsi_idx_map", NULL, 0);
+	if (lgpio->mapsize > 0) {
+		lgpio->gsi_idx_map = devm_kcalloc(&pdev->dev, lgpio->mapsize,
+						  sizeof(*lgpio->gsi_idx_map), GFP_KERNEL);
+		if (!lgpio->gsi_idx_map)
+			return -ENOMEM;
+
+		ret = device_property_read_u16_array(&pdev->dev, "gsi_idx_map",
+						     lgpio->gsi_idx_map, lgpio->mapsize);
+		if (ret != 0)
+			return dev_err_probe(&pdev->dev, ret, "failed to read gsi_idx_map\n");
+		dev_warn(&pdev->dev, "gsi_idx_map property is deprecated, consider upgrading your firmware\n");
+	} else {
+		lgpio->gsi_idx_map = NULL;
+		lgpio->mapsize = 0;
+	}
+
 	return devm_gpiochip_add_data(&pdev->dev, &lgpio->chip.gc, lgpio);
 }
 

---
base-commit: 4edcdefd4083ae04b1a5656f4be6cd83ae919ef4
change-id: 20260630-loongson-gpio-090bb159d0e4

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

