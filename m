From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 05 Jun 2026 17:09:07 +0200
Subject: [PATCH v2] gpio: qcom_spmi_gpio: move PM8998 GPIO from legacy pmic
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qcom-gpio-v2-1-c34093041c66@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAJLmImoC/22NSw6CMBQAr0Le2ppSAdGV9zAs+nnCM0KxrY2G9
 O4W3LqcZDKzgEdH6OFcLOAwkic7ZRC7AvQgpx4ZmcwguGh4w0v21HZk/UyWnVpsa6mEaKojZH9
 2eKP31rp2P/YvdUcd1sBqDOSDdZ9tFsvV+9eNJeMMRaW0UYfaSH6ZnQ12GiU99tmCLqX0BRMxw
 NK5AAAA
X-Change-ID: 20260601-qcom-gpio-98e85ab22647
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Rui Miguel Silva <rui.silva@linaro.org>, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Jens Reidel <adrian@mainlining.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780672157; l=2955;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=f1sNnGIfocv/L5Gx2f4Rimv78qhXAQcS9qTF8ZwCfwA=;
 b=ROFiNlQ48fEd7xr/1wgsG6is9rlRXOcx+sP3Vjf2g9P5XF+s5BNIUloDn6Pwit+cCzMZRvrf0
 D4GxUPEvHi8CjoD9/PU03B0rS0jgZvwDfESBF/KOUu0a7EABlnPyqIf
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the "qcom,pm8998-gpio" compatible from the legacy driver
qcom_pmic_gpio.c to qcom_spmi_gpio.c. Enables on PM8998-based boards
(sdm845: SHIFT 6mq, Pixel 3, OnePlus 6, Poco F1, Sony Xperia Akatsuki)
the Volume UP gpio-key.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Move the "qcom,pm8998-gpio" compatible from the legacy driver
qcom_pmic_gpio.c to qcom_spmi_gpio.c. Enables on PM8998-based boards
(sdm845: SHIFT 6mq, Pixel 3, OnePlus 6, Poco F1, Sony Xperia Akatsuki)
the Volume UP gpio-key.

Suggested-by: Neil Armstrong <neil.armstrong@linaro.org>
---
Changes in v2:
- Reworked per Neil Armstrong's suggestion on v1: migrate PM8998 to the
  modern qcom_spmi_gpio driver instead of extending the legacy
  qcom_pmic_gpio.c.
- Dropped "gpio: qcom_pmic_gpio: implement standard pinconf parameters".
- Dropped "gpio: qcom_pmic_gpio: don't reset pull on direction change".
- Replaced with a single qcom_spmi_gpio.c patch that claims the
  qcom,pm8998-gpio compatible.
- Link to v1: https://patch.msgid.link/20260601-qcom-gpio-v1-0-e24bcdb35da0@protonmail.com

To: Sumit Garg <sumit.garg@kernel.org>
To: u-boot-qcom@groups.io
To: u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>
Cc: Tom Rini <trini@konsulko.com>
Cc: Rui Miguel Silva <rui.silva@linaro.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>
Cc: Luca Weiss <luca.weiss@fairphone.com>
Cc: David Wronek <david.wronek@mainlining.org>
Cc: Jens Reidel <adrian@mainlining.org>
---
 drivers/gpio/qcom_pmic_gpio.c | 1 -
 drivers/gpio/qcom_spmi_gpio.c | 1 +
 2 files changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpio/qcom_pmic_gpio.c b/drivers/gpio/qcom_pmic_gpio.c
index 4458c55cd3d..6215f794e09 100644
--- a/drivers/gpio/qcom_pmic_gpio.c
+++ b/drivers/gpio/qcom_pmic_gpio.c
@@ -344,7 +344,6 @@ static int qcom_gpio_probe(struct udevice *dev)
 static const struct udevice_id qcom_gpio_ids[] = {
 	{ .compatible = "qcom,pm8916-gpio" },
 	{ .compatible = "qcom,pm8994-gpio" },	/* 22 GPIO's */
-	{ .compatible = "qcom,pm8998-gpio" },
 	{ .compatible = "qcom,pms405-gpio" },
 	{ .compatible = "qcom,pm6125-gpio" },
 	{ .compatible = "qcom,pm8150-gpio" },
diff --git a/drivers/gpio/qcom_spmi_gpio.c b/drivers/gpio/qcom_spmi_gpio.c
index 1a7c7c48dfc..8c3323b23b7 100644
--- a/drivers/gpio/qcom_spmi_gpio.c
+++ b/drivers/gpio/qcom_spmi_gpio.c
@@ -751,6 +751,7 @@ static const struct udevice_id qcom_spmi_pmic_gpio_ids[] = {
 	{ .compatible = "qcom,pm8550b-gpio" },
 	{ .compatible = "qcom,pm8550ve-gpio" },
 	{ .compatible = "qcom,pm8550vs-gpio" },
+	{ .compatible = "qcom,pm8998-gpio" },
 	{ .compatible = "qcom,pmk8550-gpio" },
 	{ .compatible = "qcom,pmr735d-gpio" },
 	{ }

---
base-commit: 1f89ddd61cd8c27a3dc1fc7edbeccb55d424eb72
change-id: 20260601-qcom-gpio-98e85ab22647

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

