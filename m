From: Niall Leonard <nl250060@ncr.com>
Date: Thu, 26 Jan 2023 10:17:23 +0000
Subject: [PATCH 2/3] gpio: Add new flag BGPIOF_NO_INPUT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230126-gpio-mmio-fix-v1-2-8a20ce0e8275@ncr.com>
References: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
In-Reply-To: <20230126-gpio-mmio-fix-v1-0-8a20ce0e8275@ncr.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Niall Leonard <nl250060@ncr.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=725; i=nl250060@ncr.com;
 h=from:subject:message-id; bh=TggMaJeCcpeNdUyuVzDRaxsQqKzgRTR7wrZ7HE9dDhg=;
 b=owEBbQKS/ZANAwAKAVGiIrYFD2P/AcsmYgBj0lNal1QTJQw+z/cl0dkuF4eBMGFEgzNxPwt88RAJ
 yEncf7CJAjMEAAEKAB0WIQSha1EPjh6hUqdtwZNRoiK2BQ9j/wUCY9JTWgAKCRBRoiK2BQ9j/2wzEA
 CMVU+Aqyd/S4fxzF9epmJOp+NTI0QKcCM6A45WtIHkfL24d6XnOrzA2WFb7Q1vaVC3rQp4+8RfvBMv
 sAziC5leMO2WOG9GdYmi/if320+fJ607I4yILRKqDhS5MDm4UHSc2m8LTrIpz1XkxpUTOeLQPNiof6
 3nXXDMFPv0fekhtnODoKjU0Phjug+zP4mG8pN6eaGSmlLSrMTCrcdX8CPWxOS35eeE7dLmqDpafFzP
 v+wurMIZ2e82Wr2e+RYw3d/66R95x6ydrRY9V/x4eFFQ5bDGeHSinITtfnt2Dbmjwp7vMzKwOWFEtE
 Ja1luHGeJXr7Ohj4zK6/GTBqf2Ok12BlSbAkKZqtLXXCR8QQ1WBuG7TAYLStl40iYLRakboE7mF11X
 7V+AdaEeJmAuDt/3xVTqeq4h8xaEx9/ve4saAexZd8BBOnTzusBNLg3/mlJu7pGK5hpaAePb164wpz
 3vnCzYB2fQSt9gI5jEUPtBbflj2SbU97YRXMhq2du1x28HBoXWn540z/1LNtlcxm4VfDkZkKGJ/bZs
 4V8Z35PJUWbdcMbiYmnxI4Av4J4wxwb5isvVMpd5txE4xXCIv1C4vIQs1blJ9HWbHs87pQZliGoyIN
 LPjBqKZaMKmtP4STpIsEqABTWONFeEbzXv5LfkPTxKCSQWuh5ye426xXsUdQ==
X-Developer-Key: i=nl250060@ncr.com; a=openpgp;
 fpr=A16B510F8E1EA152A76DC19351A222B6050F63FF
X-Endpoint-Received: by B4 Submission Endpoint for nl250060@ncr.com/default with auth_id=26
List-Id: B4 Web Endpoint Patches <b4-sent.feeds.kernel.org>

Signed-off-by: Niall Leonard <nl250060@ncr.com>
---
 include/linux/gpio/driver.h | 1 +
 1 file changed, 1 insertion(+)

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

