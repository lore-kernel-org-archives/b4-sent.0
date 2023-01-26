From: Niall Leonard <nl250060@ncr.com>
Date: Thu, 26 Jan 2023 10:17:24 +0000
Subject: [PATCH 3/3] gpio: mmio: Use new flag BGPIOF_NO_INPUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230126-gpio-mmio-fix-v1-3-8a20ce0e8275@ncr.com>
References: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
In-Reply-To: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1964; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=IQwtrgDKf2QgNZYU9DD7LFbObPBPz/lwtIwlOPLwcgM=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj0lNb1kkol71okHDULBf/ympbkNCY51FLhZrC3D+p
 /4DXpGiJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9JTWwAKCRBRoiK2BQ9j/9qRD/
 0YdRZAqSpG3MI+yJpsuDqitYC+N/uNu/v5oKauNCl5ffRzn7xP9x0j64U3Ay2fj5KpSAfvprbpAZ17
 4P0I27QVxSXsnMsrfW+Zk9Krt9U+hgDx4vHPfFk7urdkRom4VLl1K4mUsntZezSHwaJ+2Y0MD0icSl
 nvuGUs4OcStu3AGHZOXb1jhZUH69rq3pajhat/jdUwThy6RnMBm2KXFbh06nHBEmqSlHN4k3qRj2Mw
 vswbTQoljF4WwTFtHjMGvpRDV5/5wqsHoDRS5SPVN52fr91c0VkloXgXCeBODh6xfEyqSSaJx05B8b
 3H8BYQa1EzbmnzmmKY4zGpjgmCCCl80Byxa8xHQsC1hXCWRSISA5v5JILarfCPmsiUIi7WrlsEAxr+
 hCIzt0MHm8Uf/hapQsWk4Px5XfxahR8LwhYuNer/HyCZZci4nwH5Nnji6nXGghHl69lbqhFC13Qe3D
 DGPEy19G8cerxkPG0o7fKVPHOoWWm4NN14lTIkok0n6mVvGlxnftghzeRlfryy+NnTZFXNLbvWPO3S
 ERWMg1XsUC+luqyVg8RNcOmBs+21PYwnH6jlY++pgWivj7m7yAnwEDapHpMpB+9AQRdmZvBPADbZbS
 2tbR+WI3rWcJSs0DjceTnocqXhnsJxqDES5FEQoCX8+tu8OEzSQWXARhQGCQ==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Use the existing shadow data register 'bgpio_data' to allow
the last written value to be returned by the read operation
when BGPIOF_NO_INPUT flag is set.

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
 drivers/gpio/gpio-mmio.c | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)

diff --git a/drivers/gpio/gpio-mmio.c b/drivers/gpio/gpio-mmio.c
index d9dff3dc92ae..7125bd8caaa4 100644
--- a/drivers/gpio/gpio-mmio.c
+++ b/drivers/gpio/gpio-mmio.c
@@ -164,6 +164,11 @@ static int bgpio_get_set_multiple(struct gpio_chip *gc, unsigned long *mask,
 	return 0;
 }
 
+static int bgpio_get_shadow(struct gpio_chip *gc, unsigned int gpio)
+{
+	return !!(gc->bgpio_data & bgpio_line2mask(gc, gpio));
+}
+
 static int bgpio_get(struct gpio_chip *gc, unsigned int gpio)
 {
 	return !!(gc->read_reg(gc->reg_dat) & bgpio_line2mask(gc, gpio));
@@ -526,7 +531,10 @@ static int bgpio_setup_io(struct gpio_chip *gc,
 		 * reading each line individually in that fringe case.
 		 */
 	} else {
-		gc->get = bgpio_get;
+		if (flags & BGPIOF_NO_INPUT)
+			gc->get = bgpio_get_shadow;
+		else
+			gc->get = bgpio_get;
 		if (gc->be_bits)
 			gc->get_multiple = bgpio_get_multiple_be;
 		else
@@ -630,7 +638,11 @@ int bgpio_init(struct gpio_chip *gc, struct device *dev,
 	if (ret)
 		return ret;
 
-	gc->bgpio_data = gc->read_reg(gc->reg_dat);
+	if (flags & BGPIOF_NO_INPUT)
+		gc->bgpio_data = 0;
+	else
+		gc->bgpio_data = gc->read_reg(gc->reg_dat);
+
 	if (gc->set == bgpio_set_set &&
 			!(flags & BGPIOF_UNREADABLE_REG_SET))
 		gc->bgpio_data = gc->read_reg(gc->reg_set);
@@ -711,6 +723,9 @@ static struct bgpio_pdata *bgpio_parse_dt(struct platform_device *pdev,
 	if (of_property_read_bool(pdev->dev.of_node, "no-output"))
 		*flags |= BGPIOF_NO_OUTPUT;
 
+	if (of_property_read_bool(pdev->dev.of_node, "no-input"))
+		*flags |= BGPIOF_NO_INPUT;
+
 	return pdata;
 }
 #else

-- 
2.34.1

