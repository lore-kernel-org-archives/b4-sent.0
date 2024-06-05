From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v7 0/2] Add support for Amlogic S4 PWM
Date: Wed, 05 Jun 2024 10:44:54 +0800
Message-Id: <20240605-s4-pwm-v7-0-e822b271d7b0@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACfRX2YC/2XNTQ7CIBCG4as0rMVMp5SKK+9hXBAYWhL7EzBV0
 /Tu0i6qsctvwvMysUjBU2TnbGKBRh9936VRHTJmGt3VxL1NmyGgAIGCR8GHZ8vRVqDUSRpNxNL
 jIZDzrzV0vaXd+Pjow3vtjmK57hKj4MCJEMk5K8DCRbf3vvbmaPqWLZGx/MIS8w2WCYJRuSudL
 tDYPZS/UG1QJogVOFmAUA7/fpzn+QNi2SjkEAEAAA==
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717555496; l=1446;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=cLv+hU1PT81IObLXKDBLkjzJCQUWh86T/crgT79hhdQ=;
 b=wMU0AqOpojggxkgYVyGOUVH5wqws3gXc/InRdro0/5QWNYeapYskxyO7vDK8TdYFIDz8lxoLx
 /y4sXyNIrCXA+75/yXMzNRFBFodb0WC5XuzjZj7sbi+ABfEtmyLxcxL
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S4 PWM, including the driver and DTS.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Changes in v7:
- Put devm_add_action_or_reset() into the for loop.
- Remove the error handling of meson_pwm_init_channels_s4().
- Remove the repeated device node 'pwm-a-pins'.
- Some minor fixes and improvements.
- Link to v6: https://lore.kernel.org/r/20240529-s4-pwm-v6-0-270f63049f20@amlogic.com

Changes in v6:
- Rename 'pwm_meson_s4_data' to 'pwm_s4_data'.
- Rename 'meson_pwm_init_channels_meson_s4' to 'meson_pwm_init_channels_s4'.
- Adjust the order of the device nodes according to their unit addresses.
- Some minor improvements.
- Link to v5: https://lore.kernel.org/r/20240521-s4-pwm-v5-0-0c91f5fa32cd@amlogic.com

Changes in v5:
- Add devm_add_action_or_reset for free clk when unloading.
- Replace the underscores of node name with dashes.
- Link to v4: https://lore.kernel.org/r/20240424-s4-pwm-v4-0-ee22effd40d0@amlogic.com

---
Junyi Zhao (2):
      pwm: meson: Add support for Amlogic S4 PWM
      arm64: dts: amlogic: Add Amlogic S4 PWM

 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 199 ++++++++++++++++++++++++++++++
 drivers/pwm/pwm-meson.c                   |  36 ++++++
 2 files changed, 235 insertions(+)
---
base-commit: 9d99040b1bc8dbf385a8aa535e9efcdf94466e19
change-id: 20240424-s4-pwm-2d709986caee

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

