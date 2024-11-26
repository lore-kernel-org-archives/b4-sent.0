From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v2 0/5] Driver for pre-DCP apple display controller.
Date: Tue, 26 Nov 2024 17:34:19 +0100
Message-Id: <20241126-adpdrm-v2-0-c90485336c09@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIv4RWcC/2XMQQ6CMBCF4auQWVvDlKrAynsYFk1ngEkskNY0G
 tK7W9m6/F9evh0iB+EIfbVD4CRR1qWEPlXgZrtMrIRKg661QdRGWdooeKUvo+OGqLU3hHLeAo/
 yPqDHUHqW+FrD53AT/tY/IqGqVYMdUstXNp29T97K8+xWD0PO+QtOmwltnAAAAA==
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
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Janne Grunau <j@jannau.net>, 
 Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732638864; l=2009;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=/LDcePj0XDKsYma0zK+FP7xyH1ASdKtuEO+PZnGEDFc=;
 b=OZR7bklMcaizua9kd4TjpLz0AjqB1X+Vunzk81NYY7+bDd6YxbJUoKnvBPvak/Wdfbw4r/1u6
 ivWR35297jmCQnjxOTmbOKHjfiKdJI/RzDIBL6aOxGv6AdRQodof9IX
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
Changes in v2:
- Addressing the review feedback.
- Split out the mipi part of the display controller into a separate device
- Link to v1: https://lore.kernel.org/r/20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com

---
Sasha Finkelstein (5):
      dt-bindings: display: Add Apple pre-DCP display controller bindings
      drm: adp: Add Apple Display Pipe driver
      drm: panel: Add a panel driver for the Summit display
      arm64: dts: apple: Add touchbar screen nodes
      MAINTAINERS: Add entries for touchbar display driver

 .../display/apple,h7-display-pipe-mipi.yaml        |  89 +++
 .../bindings/display/apple,h7-display-pipe.yaml    |  77 +++
 .../bindings/display/panel/apple,summit.yaml       |  58 ++
 MAINTAINERS                                        |   5 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |  31 ++
 arch/arm64/boot/dts/apple/t8103.dtsi               |  61 +++
 arch/arm64/boot/dts/apple/t8112-j493.dts           |  31 ++
 arch/arm64/boot/dts/apple/t8112.dtsi               |  62 +++
 drivers/gpu/drm/Kconfig                            |   2 +
 drivers/gpu/drm/Makefile                           |   1 +
 drivers/gpu/drm/adp/Kconfig                        |  16 +
 drivers/gpu/drm/adp/Makefile                       |   4 +
 drivers/gpu/drm/adp/adp-mipi.c                     | 251 +++++++++
 drivers/gpu/drm/adp/adp_drv.c                      | 594 +++++++++++++++++++++
 drivers/gpu/drm/panel/Kconfig                      |   9 +
 drivers/gpu/drm/panel/Makefile                     |   1 +
 drivers/gpu/drm/panel/panel-summit.c               | 143 +++++
 17 files changed, 1435 insertions(+)
---
base-commit: 9f16d5e6f220661f73b36a4be1b21575651d8833
change-id: 20241124-adpdrm-25fce3dd8a71

