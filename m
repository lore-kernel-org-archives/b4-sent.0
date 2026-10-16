From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 16 Oct 2026 23:22:40 +0200
Subject: [PATCH] gpio: qcom_spmi_gpio: add qcom,pm8150l-gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-b4-pm8150l-gpio-v1-1-be7cfbe7e3b7@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0Mz3SQT3YJcC0NTgxzd9ILMfF1Ti2SjZIM0ixRz40QloK6CotS0zAq
 widGxEH5xaVJWanIJyBil2loAsZXVHHMAAAA=
X-Change-ID: 20261016-b4-pm8150l-gpio-58c2c0f8d73a
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.u-boot-project.org
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jens Reidel <adrian@mainlining.org>, 
 David Wronek <david.wronek@mainlining.org>, 
 David Heidelberg <david@ixit.cz>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792185763; l=1178;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=2tV/8TYil6y28jB+wzHKibuaGkO0WDGs0SbuiholmVw=;
 b=uB2xYd67oQKeuMASDCxy7rMO5HiNRbHFj5zQt1WKHENAkUDRCLhB0UGwQzqdJcgk8gqzG4+30
 T/KPe4vrv2JBSiq3J4kpmy75tobOi2GJgp+NhvExePZSV8xG2sCxSgG
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PM8150L has the same GPIO block as the other PMICs of the family.

The Pixel 4a 5G (bramble) wires its Volume Up key to one of its pins.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
The Pixel 4a 5G wires its Volume Up key to a PM8150L GPIO.

Without the compatible the PMIC GPIO block is not bound
so the key cannot be read in U-Boot.
---
 drivers/gpio/qcom_spmi_gpio.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpio/qcom_spmi_gpio.c b/drivers/gpio/qcom_spmi_gpio.c
index ae75a4e151d..f4b614ee1a6 100644
--- a/drivers/gpio/qcom_spmi_gpio.c
+++ b/drivers/gpio/qcom_spmi_gpio.c
@@ -748,6 +748,7 @@ static const struct udevice_id qcom_spmi_pmic_gpio_ids[] = {
 	{ .compatible = "qcom,pm660l-gpio" },
 	{ .compatible = "qcom,pm7325-gpio" },
 	{ .compatible = "qcom,pm7550-gpio" },
+	{ .compatible = "qcom,pm8150l-gpio" },
 	{ .compatible = "qcom,pm8550-gpio" },
 	{ .compatible = "qcom,pm8550b-gpio" },
 	{ .compatible = "qcom,pm8550ve-gpio" },

---
base-commit: 71433ebf2aed1be5fbd2b1d497eae670ab9b9962
change-id: 20261016-b4-pm8150l-gpio-58c2c0f8d73a

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

