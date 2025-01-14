From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v4 0/5] Driver for pre-DCP apple display controller.
Date: Tue, 14 Jan 2025 22:38:51 +0100
Message-Id: <20250114-adpdrm-v4-0-e9b5260a39f1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGvZhmcC/2XMywrDIBCF4VcJrmtx1Fzsqu9RuhAdE6G5oEVaQ
 t69JtAQ2uUZ5vtnEjF4jORSzCRg8tGPQx7yVBDT6aFF6m3ehDMuAbik2k429JSXzqCwttE1kPw
 8BXT+tYVu97w7H59jeG/dBOv1L5GAMipAgW2wQqn0te21f5zN2JM1kfiRVTvjmRnFZFMKURmmf
 pn4spJltzOxsqqW1oByunZHtizLBwoVYPgKAQAA
X-Change-ID: 20241124-adpdrm-25fce3dd8a71
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <quic_jesszhan@quicinc.com>, asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Alyssa Ross <hi@alyssa.is>, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Janne Grunau <j@jannau.net>, Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736890736; l=2322;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=ZqXJD3Ty0hy3p1Rn2AjYRjEtykGB6SyBFMldnyqM0Bw=;
 b=ePZzGayCIflzxCQOZEHfmM1ZpjGRm9Jv16/Y3XbsjvMGeFINB091HBgC1w099s9OC9FGCFAft
 x8UzvWrCUAMDV/wkZihuT2i8JeN1u00hdCxZrYLVleU311MFq5t2lAY
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds support for a secondary display controller
present on Apple M1/M2 chips and used to drive the display of the
"touchbar" touch panel present on those. 

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v4:
- Fixed dt bindings.
- Link to v3: https://lore.kernel.org/r/20250112-adpdrm-v3-0-c674dc19fa7f@gmail.com

Changes in v3:
- Fixed building as module after splitting out mipi block
- Addressing the review feedback.
- Link to v2: https://lore.kernel.org/r/20241126-adpdrm-v2-0-c90485336c09@gmail.com

Changes in v2:
- Addressing the review feedback.
- Split out the mipi part of the display controller into a separate device
- Link to v1: https://lore.kernel.org/r/20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com

---
Sasha Finkelstein (5):
      dt-bindings: display: Add Apple pre-DCP display controller
      drm: adp: Add Apple Display Pipe driver
      drm: panel: Add a panel driver for the Summit display
      arm64: dts: apple: Add touchbar screen nodes
      MAINTAINERS: Add entries for touchbar display driver

 .../display/apple,h7-display-pipe-mipi.yaml        |  83 +++
 .../bindings/display/apple,h7-display-pipe.yaml    |  88 +++
 .../bindings/display/panel/apple,summit.yaml       |  58 ++
 MAINTAINERS                                        |   5 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  31 ++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  60 +++
 arch/arm64/boot/dts/apple/t8112-j493.dts           |  31 ++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  61 +++
 drivers/gpu/drm/Kconfig                            |   2 +
 drivers/gpu/drm/Makefile                           |   1 +
 drivers/gpu/drm/adp/Kconfig                        |  16 +
 drivers/gpu/drm/adp/Makefile                       |   5 +
 drivers/gpu/drm/adp/adp-mipi.c                     | 251 +++++++++
 drivers/gpu/drm/adp/adp_drv.c                      | 594 +++++++++++++++++++++
 drivers/gpu/drm/panel/Kconfig                      |   9 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-summit.c               | 132 +++++
 17 files changed, 1428 insertions(+)
---
base-commit: b62cef9a5c673f1b8083159f5dc03c1c5daced2f
change-id: 20241124-adpdrm-25fce3dd8a71

