From: Nickolay Goppen <setotau@yandex.ru>
Date: Mon, 25 Aug 2025 15:32:28 +0300
Subject: [PATCH v3 1/3] pinctrl: qcom: lpass-lpi: Introduce pin_offset
 callback
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250825-sdm660-lpass-lpi-v3-1-65d4a4db298e@yandex.ru>
References: <20250825-sdm660-lpass-lpi-v3-0-65d4a4db298e@yandex.ru>
In-Reply-To: <20250825-sdm660-lpass-lpi-v3-0-65d4a4db298e@yandex.ru>
To: Bjorn Andersson <andersson@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, Nickolay Goppen <setotau@yandex.ru>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756125160; l=2711;
 i=setotau@yandex.ru; s=20250815; h=from:subject:message-id;
 bh=JXoM3miyeg5XfaW9RV8i7oWQ6FTIiwpKlwfmyKxAlDw=;
 b=FYawZWsVh/I4+POXMh4WtPpuOBsqAOadAxCDc7xg66BNRj8/zgcbhRtuW/jkUoznfI8gihU28
 4EWLH8v3AIQCdcaNVEu5huCywip/atLGEDQpkPXJwB1sHx0OUS/dQWF
X-Developer-Key: i=setotau@yandex.ru; a=ed25519;
 pk=Og7YO6LfW+M2QfcJfjaUaXc8oOr5zoK8+4AtX5ICr4o=
X-Endpoint-Received: by B4 Relay for setotau@yandex.ru/20250815 with auth_id=492
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

By default pin_offset is calculated by formula: LPI_TLMM_REG_OFFSET * pin_id.
However not all platforms are using this pin_offset formula (e.g. SDM660 LPASS
LPI uses a predefined array of offsets [1]), so add a callback to the default
pin_offset function to add an ability for some platforms to use their own quirky
pin_offset functions and add callbacks to pin_offset_default function for other
platforms.

[1] https://git.codelinaro.org/clo/la/kernel/msm-4.4/-/blob/LA.UM.7.2.c27-07400-sdm660.0/drivers/pinctrl/qcom/pinctrl-lpi.c#L107

Signed-off-by: Nickolay Goppen <setotau@yandex.ru>
---
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.c | 18 ++++++++++++++++--
 drivers/pinctrl/qcom/pinctrl-lpass-lpi.h |  7 +++++++
 2 files changed, 23 insertions(+), 2 deletions(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-lpass-lpi.c b/drivers/pinctrl/qcom/pinctrl-lpass-lpi.c
index 57fefeb603f0e2502fccd14ba3982ae3cb591978..aa307088b0eedd3f2fe86045c1d71ab8a855858f 100644
--- a/drivers/pinctrl/qcom/pinctrl-lpass-lpi.c
+++ b/drivers/pinctrl/qcom/pinctrl-lpass-lpi.c
@@ -41,13 +41,27 @@ struct lpi_pinctrl {
 static int lpi_gpio_read(struct lpi_pinctrl *state, unsigned int pin,
 			 unsigned int addr)
 {
-	return ioread32(state->tlmm_base + LPI_TLMM_REG_OFFSET * pin + addr);
+	u32 pin_offset;
+
+	if (!state->data->pin_offset)
+		pin_offset = lpi_pinctrl_pin_offset_default(pin);
+	else
+		pin_offset = state->data->pin_offset(pin);
+
+	return ioread32(state->tlmm_base + pin_offset + addr);
 }
 
 static int lpi_gpio_write(struct lpi_pinctrl *state, unsigned int pin,
 			  unsigned int addr, unsigned int val)
 {
-	iowrite32(val, state->tlmm_base + LPI_TLMM_REG_OFFSET * pin + addr);
+	u32 pin_offset;
+
+	if (!state->data->pin_offset)
+		pin_offset = lpi_pinctrl_pin_offset_default(pin);
+	else
+		pin_offset = state->data->pin_offset(pin);
+
+	iowrite32(val, state->tlmm_base + pin_offset + addr);
 
 	return 0;
 }
diff --git a/drivers/pinctrl/qcom/pinctrl-lpass-lpi.h b/drivers/pinctrl/qcom/pinctrl-lpass-lpi.h
index a9b2f65c1ebe0f8fb5d7814f8ef8b723c617c85b..bfb85d438a02a5041c4d0218fd64bb68324b5881 100644
--- a/drivers/pinctrl/qcom/pinctrl-lpass-lpi.h
+++ b/drivers/pinctrl/qcom/pinctrl-lpass-lpi.h
@@ -85,9 +85,16 @@ struct lpi_pinctrl_variant_data {
 	const struct lpi_function *functions;
 	int nfunctions;
 	unsigned int flags;
+	u32 (*pin_offset)(int pin_id);
 };
 
 int lpi_pinctrl_probe(struct platform_device *pdev);
 void lpi_pinctrl_remove(struct platform_device *pdev);
 
+static inline u32 lpi_pinctrl_pin_offset_default(int pin_id)
+{
+	return LPI_TLMM_REG_OFFSET * pin_id;
+}
+
+
 #endif /*__PINCTRL_LPASS_LPI_H__*/

-- 
2.51.0

