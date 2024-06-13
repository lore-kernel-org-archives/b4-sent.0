From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v8 0/2] Add support for Amlogic S4 PWM
Date: Thu, 13 Jun 2024 19:46:34 +0800
Message-Id: <20240613-s4-pwm-v8-0-b5bd0a768282@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABrcamYC/23OTQ6CMBAF4KuYrq0Zxv5QV97DuIB2Kk0EDDWoI
 dzdwgKMunyT+d7MwCJ1gSI7bAbWUR9iaJsU8u2G2apoLsSDS5khoACBgkfBb4+ao9NgTK5sQcT
 S8q0jH55z0emcchXive1ec28vpulPRS84cCJE8t4JcHAs6mt7CXZn25pNJb1cocRsgTJBsCbz0
 hd7tO4Xqk9oFqgSRA1e7UEYj38u6hUqkAvU06s5Yok6c7r8guM4vgEt6maCSQEAAA==
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pwm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>, 
 George Stark <gnstark@salutedevices.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718279231; l=1661;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=T7TWzD+8vHETS7BWE/0HH/nm2zj59fwupPU7gNji60w=;
 b=6BkebCfy1cxhNBjMU7JUMIjFTx2FvQuZKQkcIZQSSMDT80mg963Ob1A//ow23qj58oSLHsmf4
 4axa/XhAwEwAR6gyhqR5rrIc3duQr8O38mflObgm8Gn/ViG+Gsj4h1M
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic S4 PWM, including the driver and DTS.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Changes in v8:
- Return dev_err_probe() in meson_pwm_init_channels_s4().
- Check the result of devm_add_action_or_reset().
- Link to v7: https://lore.kernel.org/r/20240605-s4-pwm-v7-0-e822b271d7b0@amlogic.com

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
 drivers/pwm/pwm-meson.c                   |  39 ++++++
 2 files changed, 238 insertions(+)
---
base-commit: 9d99040b1bc8dbf385a8aa535e9efcdf94466e19
change-id: 20240424-s4-pwm-2d709986caee

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

