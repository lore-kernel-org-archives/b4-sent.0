From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:51 +1000
Subject: [PATCH RESEND 10/16] pinctrl: qcom: configurable GPIO
 offset/stride
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-10-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=2547;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=6bPzR204m6EqF0qblxuJserSk3E5YIYcDCv48l6t78E=;
 b=2ocu89xIu6mXSy4gfcnBJi+ui2u9sF9ai0pClDff+dMGP0/me3Oe6QVYtMD3mwfjIuR0dQDsj
 CM103NGau3dDTmu4zWDPY0tyjkQ6ZxMLr6vjFa8Kgi9InJbAnc10gAM
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The infra currently assumes that each GPIO register block is 0x1000
wide. This is not the case on older TLMM versions.

For example, the GPIOs on MSM8960's TLMM hav an *offset* of 0x1000,
and each register block is only 0x10 wide.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/mach-snapdragon/include/mach/gpio.h | 12 ++++++++----
 drivers/gpio/msm_gpio.c                      |  2 +-
 drivers/pinctrl/qcom/pinctrl-qcom.c          |  2 +-
 3 files changed, 10 insertions(+), 6 deletions(-)

diff --git a/arch/arm/mach-snapdragon/include/mach/gpio.h b/arch/arm/mach-snapdragon/include/mach/gpio.h
index 11e8104baf2..49bf480c903 100644
--- a/arch/arm/mach-snapdragon/include/mach/gpio.h
+++ b/arch/arm/mach-snapdragon/include/mach/gpio.h
@@ -27,16 +27,20 @@ struct msm_special_pin_data {
 struct msm_pin_data {
 	int pin_count;
 	const unsigned int *pin_offsets;
+	u32 gpio_base;
+	/* defaults to 0x1000 */
+	u32 gpio_stride;
 	unsigned int special_pins_start;
 	const struct msm_special_pin_data *special_pins_data;
 };
 
-static inline u32 qcom_pin_offset(const unsigned int *offs, unsigned int selector)
+static inline u32 qcom_pin_offset(const struct msm_pin_data *pindata, unsigned int selector)
 {
-	u32 out = (selector * 0x1000);
+	u32 stride = pindata->gpio_stride ? pindata->gpio_stride : 0x1000;
+	u32 out = pindata->gpio_base + selector * stride;
 
-	if (offs)
-		return out + offs[selector];
+	if (pindata->pin_offsets)
+		return out + pindata->pin_offsets[selector];
 
 	return out;
 }
diff --git a/drivers/gpio/msm_gpio.c b/drivers/gpio/msm_gpio.c
index 7de332c66ae..a24d0f03398 100644
--- a/drivers/gpio/msm_gpio.c
+++ b/drivers/gpio/msm_gpio.c
@@ -29,7 +29,7 @@ struct msm_gpio_bank {
 };
 
 #define GPIO_CONFIG_REG(dev, x) \
-	(qcom_pin_offset(((struct msm_gpio_bank *)dev_get_priv(dev))->pin_data->pin_offsets, x))
+	(qcom_pin_offset(((struct msm_gpio_bank *)dev_get_priv(dev))->pin_data, x))
 
 #define GPIO_IN_OUT_REG(dev, x) \
 	(GPIO_CONFIG_REG(dev, x) + 0x4)
diff --git a/drivers/pinctrl/qcom/pinctrl-qcom.c b/drivers/pinctrl/qcom/pinctrl-qcom.c
index c95db56bc47..82817c2316f 100644
--- a/drivers/pinctrl/qcom/pinctrl-qcom.c
+++ b/drivers/pinctrl/qcom/pinctrl-qcom.c
@@ -30,7 +30,7 @@ struct msm_pinctrl_priv {
 };
 
 #define GPIO_CONFIG_REG(priv, x) \
-	(qcom_pin_offset((priv)->data->pin_data.pin_offsets, x))
+	(qcom_pin_offset(&(priv)->data->pin_data, x))
 
 #define GPIO_IN_OUT_REG(priv, x) \
 	(GPIO_CONFIG_REG(priv, x) + 0x4)

-- 
2.54.0

