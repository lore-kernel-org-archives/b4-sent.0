From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH v4 0/6] Enable new features for flipkart-rimob
Date: Fri, 27 Mar 2026 15:30:46 +0100
Message-Id: <20260327-rimob-new-features-v4-0-06edff9c4509@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23N3wqCMBTH8VeRXbfYv9zsqveILuY85iA32cwK8
 d2bQiC0y+8PzufMKEKwENG5mFGAyUbrXQpxKJDptLsDtk1qxAgrCSccB9v7Gjt44Rb0+AwQMeG
 yEqLmumQEpcMhQGvfG3q9pe5sHH34bD8muq4/TuW4iWKCtWaGc3KSzJDLEPzoXa/t42h8j1ZzY
 juH5h2WHEPrVlVUClFB1uE7h9Gsw5PTiFoBqFI2IP+cZVm++ykhikkBAAA=
X-Change-ID: 20260303-rimob-new-features-037944b3a620
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774621871; l=4370;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=h50clFkchxlz1PjbdPsQIzoGz7zeASQJbxZttgo1vUc=;
 b=vITHOrrhN3QyayyzduelM8+d7whmRf/XjXHz92bxi5wZqClsw19TuBh5I9hzbuGx35b5Tz4yy
 4iMSJfsYBqFDP7GaO+B8u1wJ0GgAmkn+aIcnqfTMjuybFRKIlfj+vE9
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

Patches 1 and 2 provide a driver for Novatek NT35532 and its corresponding
devicetree bindings, required for enabling panel in DTS. The remaining 
patches are all DTS changes, aimed to enable the features listed above.

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
Cristian Cozzolino (6):
      dt-bindings: display: panel: Add Novatek NT35532 LCD DSI
      drm/panel: Add driver for Novatek NT35532
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable display and GPU
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable WiFi/Bluetooth
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable touchscreen
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable Hall sensor

 .../bindings/display/panel/novatek,nt35532.yaml    |  80 +++
 MAINTAINERS                                        |   6 +
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 138 +++-
 drivers/gpu/drm/panel/Kconfig                      |  10 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-novatek-nt35532.c      | 796 +++++++++++++++++++++
 6 files changed, 1030 insertions(+), 1 deletion(-)
---
base-commit: e77a5a5cfe43b4c25bd44a3818e487033287517f
change-id: 20260303-rimob-new-features-037944b3a620

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

