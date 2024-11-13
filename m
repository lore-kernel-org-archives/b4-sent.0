From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 13 Nov 2024 15:29:41 +0800
Subject: [PATCH v6 3/5] pinctrl: meson: add interface of of_xlate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241113-a4_pinctrl-v6-3-35ba2401ee35@amlogic.com>
References: <20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com>
In-Reply-To: <20241113-a4_pinctrl-v6-0-35ba2401ee35@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731482979; l=1754;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=kZkfTxXyUa/bUEnikqRrRpqnocDlXw3ORsFp/T0SNwU=;
 b=3PeJkCu/mERXBOEPe0kwA68C9B29lxXDsLkZNI/NHnkgbug00+MVamJFxMg0gFzBpfNsu045c
 nhl6XxbpWEuBUECuNbdKEaGVM6i1h5S0pE8kNlbQh34oV1+/YzwJPQp
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic pinctrl software framework use system API of_gpio_simple_xlate
which only support linear one-to-one correspondence to translate gpiospec
to the GPIO number and flags before. It can not meet the non-linear needs.
Add the interface satisfies the underlying driver to implement the
transformation to meet the needs of various scenarios.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/pinctrl/meson/pinctrl-meson.c | 4 ++++
 drivers/pinctrl/meson/pinctrl-meson.h | 4 ++++
 2 files changed, 8 insertions(+)

diff --git a/drivers/pinctrl/meson/pinctrl-meson.c b/drivers/pinctrl/meson/pinctrl-meson.c
index 253a0cc57e39..fc0c0bef38c0 100644
--- a/drivers/pinctrl/meson/pinctrl-meson.c
+++ b/drivers/pinctrl/meson/pinctrl-meson.c
@@ -620,6 +620,10 @@ static int meson_gpiolib_register(struct meson_pinctrl *pc)
 	pc->chip.base = -1;
 	pc->chip.ngpio = pc->data->num_pins;
 	pc->chip.can_sleep = false;
+	if (pc->data->of_xlate) {
+		pc->chip.of_gpio_n_cells = pc->data->of_gpio_n_cells;
+		pc->chip.of_xlate = pc->data->of_xlate;
+	}
 
 	ret = gpiochip_add_data(&pc->chip, pc);
 	if (ret) {
diff --git a/drivers/pinctrl/meson/pinctrl-meson.h b/drivers/pinctrl/meson/pinctrl-meson.h
index 7883ea31a001..cbb3f22552b9 100644
--- a/drivers/pinctrl/meson/pinctrl-meson.h
+++ b/drivers/pinctrl/meson/pinctrl-meson.h
@@ -120,6 +120,10 @@ struct meson_pinctrl_data {
 	const struct pinmux_ops *pmx_ops;
 	const void *pmx_data;
 	int (*parse_dt)(struct meson_pinctrl *pc);
+	int (*of_xlate)(struct gpio_chip *gc,
+			const struct of_phandle_args *gpiospec,
+			u32 *flags);
+	int of_gpio_n_cells;
 };
 
 struct meson_pinctrl {

-- 
2.37.1

