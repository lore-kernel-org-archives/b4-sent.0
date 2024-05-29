From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v6 0/2] Add support for Amlogic S4 PWM
Date: Wed, 29 May 2024 18:00:55 +0800
Message-Id: <20240529-s4-pwm-v6-0-270f63049f20@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANf8VmYC/2WMQQrCMBBFr1JmbSQdk2pdeQ9xEZJJO2BNSSQqp
 Xc37UIRl+/z35sgUWRKcKwmiJQ5cbgVaDYV2N7cOhLsCgNKVFKhEkmJ8TEIdHvZtofGGiIo5zG
 S5+caOl8K95zuIb7WblbL+pfISkhBhEjeOyWdPJnhGjq2WxsGWCJZf0WN9UfURZS2rb32ZofW/
 YrzPL8BBSOvPdcAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716976876; l=1140;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=a91FxspxlRCfgSu57AGk4ebkLMPvGl9K4zWKW9UVBnU=;
 b=/SM+S10/vNZX/3yq/Vv/gVtGFkhrqyd951SBAMUefxD4hriwDQ+A5PQW7I5uW3k6gprCPivv7
 CWOHQUlXHkZC6nYGzPJpAW4cp/lPI3y3ZfKAHt+qBWl+g5u6TG/gmuG
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S4 PWM, including the driver and DTS.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
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

 arch/arm64/boot/dts/amlogic/meson-s4.dtsi | 207 ++++++++++++++++++++++++++++++
 drivers/pwm/pwm-meson.c                   |  49 +++++++
 2 files changed, 256 insertions(+)
---
base-commit: 124cfbcd6d185d4f50be02d5f5afe61578916773
change-id: 20240424-s4-pwm-2d709986caee

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

