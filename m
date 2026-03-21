From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH v3 0/6] Enable new features for flipkart-rimob
Date: Sat, 21 Mar 2026 17:23:19 +0100
Message-Id: <20260321-rimob-new-features-v3-0-d4b8ee867de7@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23NywrCMBCF4VcpWRuZXOzFle8hLtI4tQO2KUmNS
 um7mxYEwS7/A/PNxAJ6wsCO2cQ8Rgrk+hRqlzHbmv6GnK6pmQSZgwLFPXWu5j0+eYNmfHgMHFR
 RaV0rk0tg6XDw2NBrRc+X1C2F0fn3+iOKZf1y5RYXBQdujLRKwaGQFk6Dd6PrO0P3vXUdW8wof
 xyx7cjkWFE3ZSUKrSv8c+Z5/gD1TsPDAQEAAA==
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
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774110230; l=3654;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=81We+ZTdhjczoWNJRNXTTTn2mWFEUmdrREF45LZk9uU=;
 b=41y3BurYAQZELv0HUn9KUIUZyM+lmVMS+bdUxwz+7YtdH8iDxxurK1uUTg8mlbil8wv4OrzrW
 9J/VThIG09NChf4xF6kMOUrkOemvDDNEW9INOjVnDUYoiSVwh0y7X8G
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

 .../bindings/display/panel/novatek,nt35532.yaml    |  77 ++
 MAINTAINERS                                        |   6 +
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 139 +++-
 drivers/gpu/drm/panel/Kconfig                      |  10 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-novatek-nt35532.c      | 779 +++++++++++++++++++++
 6 files changed, 1011 insertions(+), 1 deletion(-)
---
base-commit: 785f0eb2f85decbe7c1ef9ae922931f0194ffc2e
change-id: 20260303-rimob-new-features-037944b3a620

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

