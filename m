From: Petr Hodina <petr.hodina@protonmail.com>
Date: Mon, 01 Jun 2026 13:52:36 +0200
Subject: [PATCH 2/2] gpio: qcom_pmic_gpio: don't reset pull on direction
 change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-gpio-v1-2-e24bcdb35da0@protonmail.com>
References: <20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com>
In-Reply-To: <20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Rui Miguel Silva <rui.silva@linaro.org>, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780314756; l=884;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=gfww1vaKc2KBXsBrPUOGZ84bFFgF2PKWqI3AaBSBrPE=;
 b=jHHTaHG0AoqAD11uxsXZ2qXBg7gbZWuiLEJuhvUIu5J3HurRf7TK/1pdnDlixgQxt7DjLdlka
 DXk7gj+VN8LC3etU4cLgl4lWhV7Q1QbUJHsd9+qhRp0giKVqImH4Bb/
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix for pull-up/pull-down/disable as that's independent of the direction.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/gpio/qcom_pmic_gpio.c | 6 ------
 1 file changed, 6 deletions(-)

diff --git a/drivers/gpio/qcom_pmic_gpio.c b/drivers/gpio/qcom_pmic_gpio.c
index 71cc76fef2f..e67e138ede2 100644
--- a/drivers/gpio/qcom_pmic_gpio.c
+++ b/drivers/gpio/qcom_pmic_gpio.c
@@ -129,12 +129,6 @@ static int qcom_gpio_set_direction(struct udevice *dev, unsigned int offset,
 
 	_qcom_gpio_set_direction(dev, offset, input, value);
 
-	/* Set the right pull (no pull) */
-	ret = pmic_reg_write(plat->pmic, gpio_base + REG_DIG_PULL_CTL,
-			     REG_DIG_PULL_NO_PU);
-	if (ret < 0)
-		return ret;
-
 	/* Configure output pin drivers if needed */
 	if (!input) {
 		/* Select the VIN - VIN0, pin is input so it doesn't matter */

-- 
2.53.0

