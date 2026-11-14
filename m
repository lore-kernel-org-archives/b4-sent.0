From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:21:59 +0000
Subject: [PATCH 5/9] gpio: qcom_spmi_gpio: add qcom,pm8350-gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-5-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=841;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=ZTR5J5lSqNxrpMNOY94LkhfMSQh5ja0koATMHlss8Sg=;
 b=mtwE7JfwUjKe0Ytau5L0bsKKP66xehDfgsQ8rdEBNv3lOb//Vio/wjIjKstEahDFm8c89d4kz
 iljiDbcHZDLD4DEEoi0eCzKYZZsLkdM0DR00bIPKSsY0EROEEJsAB+Y
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PM8350 has the same GPIO block as the other PMICs of the family.

The Razer Edge 5G wires its Volume Up key to one of its pins.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/gpio/qcom_spmi_gpio.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpio/qcom_spmi_gpio.c b/drivers/gpio/qcom_spmi_gpio.c
index d06b9a4b51..0254d7de78 100644
--- a/drivers/gpio/qcom_spmi_gpio.c
+++ b/drivers/gpio/qcom_spmi_gpio.c
@@ -749,6 +749,7 @@ static const struct udevice_id qcom_spmi_pmic_gpio_ids[] = {
 	{ .compatible = "qcom,pm7325-gpio" },
 	{ .compatible = "qcom,pm7550-gpio" },
 	{ .compatible = "qcom,pm8150l-gpio" },
+	{ .compatible = "qcom,pm8350-gpio" },
 	{ .compatible = "qcom,pm8550-gpio" },
 	{ .compatible = "qcom,pm8550b-gpio" },
 	{ .compatible = "qcom,pm8550ve-gpio" },

-- 
2.53.0

