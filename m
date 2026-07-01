From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH v6 0/4] Enable new features for flipkart-rimob
Date: Wed, 01 Jul 2026 23:55:53 +0200
Message-Id: <20260701-rimob-new-features-v6-0-be7d5d1e007f@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23OzWrDMAzA8VcpPs9Dlr/invYeYwfHkVfDEhc7y
 zZK3n1uYRCYj3+BftKNVSqJKjufbqzQlmrKSwvzdGLh4pd34mlqzRDQgATJS5rzyBf64pH8+lm
 ocpDWKTVKbxBYW7wWiun7gb6+tb6kuuby87ixifv0jxt63CY4cO8xSAnaYoCXa8lrXmafPp5Dn
 tnd3PDgiL6DzQlijIMTVilHXUceHBRdRzZnUuNANBg7ke066ujYrqOaA4amGF1QGlzX0QdH9v/
 RzdExRIUeXRD4z9n3/RczdNSv2QEAAA==
X-Change-ID: 20260303-rimob-new-features-037944b3a620
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782942968; l=4333;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=zoGOulQF1M2h8Q01GsubA1RgVWr6kNLn78527WuVvX4=;
 b=U//qRAjidfOu+8iCd75GDvniNljYnibrSMFyl6RvvelelrWzvAq7r9W9O0irwJ3ebV06ez4zS
 4icm3O99nKUAq6Ob9ApVdPOYTvUyjT2xGdMmLPk2hA2GUisl8cfXTwN
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables a set of miscellaneous features for Billion Capture+ 
(a handset using the MSM8953 SoC released in 2017):
- Panel and GPU
- Touchscreen
- WiFi + Bluetooth
- Hall sensor 

To: Neil Armstrong <neil.armstrong@linaro.org>
To: Jessica Zhang <jesszhan0024@gmail.com>
To: David Airlie <airlied@gmail.com>
To: Simona Vetter <simona@ffwll.ch>
To: Maarten Lankhorst <maarten.lankhorst@linux.intel.com>
To: Maxime Ripard <mripard@kernel.org>
To: Thomas Zimmermann <tzimmermann@suse.de>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Bjorn Andersson <andersson@kernel.org>
To: Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-arm-msm@vger.kernel.org
Cc: ~postmarketos/upstreaming@lists.sr.ht
Cc: phone-devel@vger.kernel.org 

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
Changes in v6:
- Drop applied patches;
- Pick up tag;
- Link to v5: https://lore.kernel.org/r/20260331-rimob-new-features-v5-0-5fcf42a29c12@protonmail.com

Changes in v5:
- Based on dts-coding-style.html ("Nodes without unit addresses shall be
  ordered alpha-numerically by the node name. For a few node types, they 
  can be ordered by the main property, e.g. pin configuration states
  ordered by value of “pins” property."), sort pinctrl states by GPIO 
  index (Konrad);
- Pick up tags;
- Link to v4: https://lore.kernel.org/r/20260327-rimob-new-features-v4-0-06edff9c4509@protonmail.com

Changes in v4:
- (patch 1/6): added a new compatible (since it's not possible to
  identify panel vendor/id), matching user of this device and leaving
  novatek,nt35532 as fallback (Dmitry);
- (patch 2/6):
  - according to bindings changes, make panel driver handling multiple
    panels paired with NT35532 and use specific compatible/data;
  - due to changes applied to panel code, remove tag received previously
    by Dmitry.
- (patch 3/6): 
  - use a specific panel compatible, according to bindings changes;
  - remove 'output-high' property from panel pinctrl, since panel is not
    reset.
- Link to v3: https://lore.kernel.org/r/20260321-rimob-new-features-v3-0-d4b8ee867de7@protonmail.com

Changes in v3:
- (patch 1/6): removed avdd, avee and vci supplies from 'required' properties;
- (patch 2/6):
  - removed "select VIDEOMODE_HELPERS" from nt35532 Kconfig entry, since 
    its functions are not used (but this option is enabled and its code 
    compiled anyway) by nt35532 panel driver;
  - pick up tags (Dmitry).
- (patch 3/6): replaced a506_zap.mdt with a506_zap.mbn firmware name
  in gpu_zap_shader (Dmitry); 
- (patch 5/6): pick up tags (Konrad);
- (patch 6/6): pick up tags (Konrad);
- Link to v2: https://lore.kernel.org/r/20260318-rimob-new-features-v2-0-c1bf8917449e@protonmail.com

Changes in v2:
- (patch 1/6): define power supplies in the bindings as per datasheet  
  and update example;
- (patch 2/6): add blank lines where required between mipi dsi write
  sequences in nt35532_on() function and make use of names for mipi dcs
  commands, instead of hex numbers, to improve readibility (Dmitry); 
- (patch 3/6): move pinctrl lines ibto panel node and get rid of
  sleep/reset state, since panel just uses one pinctrl state for
  default/sleep (Dmitry). Also, update power supplies according to
  bindings; 
- (patch 4/6): pick up tags (Konrad,Dmitry);
- (patch 6/6): squash hall sensor node into gpio-keys (Dmitry);
- Link to v1: https://lore.kernel.org/r/20260308-rimob-new-features-v1-0-aa2c330572c0@protonmail.com

---
Cristian Cozzolino (4):
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable display and GPU
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable WiFi/Bluetooth
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable touchscreen
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable Hall sensor

 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 138 ++++++++++++++++++++-
 1 file changed, 137 insertions(+), 1 deletion(-)
---
base-commit: be5c93fa674f0fc3c8f359c2143abce6bbb422e6
change-id: 20260303-rimob-new-features-037944b3a620

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

