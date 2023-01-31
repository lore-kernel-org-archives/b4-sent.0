From: Niall Leonard <nl250060@ncr.com>
Date: Tue, 31 Jan 2023 13:49:38 +0000
Subject: [PATCH v2 2/2] gpio: mmio: Use new flag BGPIOF_NO_INPUT.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230126-gpio-mmio-fix-v2-2-38397aace340@ncr.com>
References: <20230126-gpio-mmio-fix-v2-0-38397aace340@ncr.com>
In-Reply-To: <20230126-gpio-mmio-fix-v2-0-38397aace340@ncr.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3171; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=qw+ukSOOr1LL8jakS9qqqS7Ifx1mSYww3yijW1VYn/c=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj2RxzG8Rs4mvsqSBm+6z29boecXRRXeqa8Uuy4anQ
 ehqbzcSJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9kccwAKCRBRoiK2BQ9j/9FKEA
 DNju1HJb+AUeRe9LgvDDLjnqhfbAV0+NsnUco9AgeNNsZ87CaMOIThcNTLH6kLkwxeeMb7XuWieLMe
 x6CDnp9Gj2PUsvqJZBSuNw9oX2DnxytOxXB8je/3fzhDvDTUAo4caKnXA7pna8rQbeY7NxbsItkBqy
 vpRYD3LoKFXsIrVPsvUbn7/wkW4flcjhuY5AcwCGHIzOUsiAxKqYRVhAl8oX+g7PT6xH0BeLg6xX9x
 Fldqj93K4zJXEFypyYcrwVzzWEpHE3sWPPazVYBv+0D2TJIFWaVIwgCDlnoNgbvCB7grUaeskAmrCS
 Gr6val+X4RZmUcv7iQua+13bzeLWeZ9Q1yYffKpdWBB7vJnYQIDHqQ3nkNC6Azgx8msVcSPdTDsF8Q
 EvqPLSB8RvkQ73JKHwfx0R/ROdSfqNGS9Znzbr9Qh4pLvq4OLz1F8Ao1dLlQ4XTNTBNAczNk+MOw3x
 8e2LAmLv0x6CYMnPHC3VWZ3KKOepEKneoLJ3ec0PykAkMt1GVhAskcopvCUXaWKik2dogK0nZd0aAh
 RX1R42naQaNEK0fE/tw6iZLlJz0t/UU1ZiMb87edPInPTW+wYjSsmRij1JGaoPNEskwjZ1qgNRWcqm
 5VdwCAqUsIc/ocBhTdEjer4JBiYr01gvxrJginHJNWG8OcrfN+IIfg6UPiAw==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Add new flag BGPIOF_NO_INPUT to header file.
Use the existing shadow data register 'bgpio_data' to allow
the last written value to be returned by the read operation
when BGPIOF_NO_INPUT flag is set.
Ensure this change only applies to the specific binding "wd,mbl-gpio".

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
 drivers/gpio/gpio-mmio.c    | 24 +++++++++++++++++++++---
 include/linux/gpio/driver.h |  1 +
 2 files changed, 22 insertions(+), 3 deletions(-)

diff --git a/drivers/gpio/gpio-mmio.c b/drivers/gpio/gpio-mmio.c
index d9dff3dc92ae..9939fdbf6345 100644
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
@@ -694,8 +706,9 @@ static struct bgpio_pdata *bgpio_parse_dt(struct platform_device *pdev,
 					  unsigned long *flags)
 {
 	struct bgpio_pdata *pdata;
+	const struct of_device_id *of_id;
 
-	if (!of_match_device(bgpio_of_match, &pdev->dev))
+	if (!(of_id = of_match_device(bgpio_of_match, &pdev->dev)))
 		return NULL;
 
 	pdata = devm_kzalloc(&pdev->dev, sizeof(struct bgpio_pdata),
@@ -711,6 +724,11 @@ static struct bgpio_pdata *bgpio_parse_dt(struct platform_device *pdev,
 	if (of_property_read_bool(pdev->dev.of_node, "no-output"))
 		*flags |= BGPIOF_NO_OUTPUT;
 
+	if (!strcmp(of_id->compatible, "wd,mbl-gpio")) {
+		if (of_property_read_bool(pdev->dev.of_node, "no-input"))
+			*flags |= BGPIOF_NO_INPUT;
+	}
+
 	return pdata;
 }
 #else
diff --git a/include/linux/gpio/driver.h b/include/linux/gpio/driver.h
index 44783fc16125..e8e57310e3b8 100644
--- a/include/linux/gpio/driver.h
+++ b/include/linux/gpio/driver.h
@@ -682,6 +682,7 @@ int bgpio_init(struct gpio_chip *gc, struct device *dev,
 #define BGPIOF_READ_OUTPUT_REG_SET	BIT(4) /* reg_set stores output value */
 #define BGPIOF_NO_OUTPUT		BIT(5) /* only input */
 #define BGPIOF_NO_SET_ON_INPUT		BIT(6)
+#define BGPIOF_NO_INPUT				BIT(7)	/* only output */
 
 int gpiochip_irq_map(struct irq_domain *d, unsigned int irq,
 		     irq_hw_number_t hwirq);

-- 
2.34.1

