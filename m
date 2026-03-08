From: Cristian Cozzolino <cristian_ci@protonmail.com>
Subject: [PATCH 0/6] Enable new features for flipkart-rimob
Date: Sun, 08 Mar 2026 16:52:40 +0100
Message-Id: <20260308-rimob-new-features-v1-0-aa2c330572c0@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQ5AMBBA4avIrE0yWiFcRSyKwSyUTP0l4u4ay
 2/x3gOBVThAnTygfEqQ1UdkaQL97PzEKEM0GDIFWbKosqwder5wZLcfygHJllWed9YVhiCGm/I
 o9z9t2vf9AGG4EOFkAAAA
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
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772985180; l=2259;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=wQ7u13m0ex1l7LW2+VlBPd+UnM7kt74ULo4GFRhXDqE=;
 b=DyAla0iz3gxfGuxFSxXh9oTIG5bqNawVTwKQWHjPRBDnN70k+mt1r1WrfmpW56H6yHoRF9Sc/
 cpB1HrLoTviCcxxzcWC7AdMP0pSqiuXo4WgbtvyRPE5zOpvtB5Rn2kK
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
Cristian Cozzolino (6):
      dt-bindings: display: panel: Add Novatek NT35532 LCD DSI
      drm/panel: Add driver for Novatek NT35532
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable display and GPU
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable WiFi/Bluetooth
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable touchscreen
      arm64: dts: qcom: msm8953-flipkart-rimob: Enable Hall sensor

 .../bindings/display/panel/novatek,nt35532.yaml    |  66 ++
 MAINTAINERS                                        |   6 +
 .../arm64/boot/dts/qcom/msm8953-flipkart-rimob.dts | 152 ++++
 drivers/gpu/drm/panel/Kconfig                      |  11 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-novatek-nt35532.c      | 767 +++++++++++++++++++++
 6 files changed, 1003 insertions(+)
---
base-commit: 11439c4635edd669ae435eec308f4ab8a0804808
change-id: 20260303-rimob-new-features-037944b3a620

Best regards,
-- 
Cristian Cozzolino <cristian_ci@protonmail.com>

