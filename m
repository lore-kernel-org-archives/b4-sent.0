From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH 0/5] Driver for pre-DCP apple display controller.
Date: Sun, 24 Nov 2024 23:29:23 +0100
Message-Id: <20241124-adpdrm-v1-0-3191d8e6e49a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMOoQ2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDQyMT3cSUgpSiXF0j07TkVOOUFItEc0MloOKCotS0zAqwQdGxtbUAW3O
 zcFgAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732487379; l=1534;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=c79EAnCWulfs6GRWWUruMhPsTaQlP4sqW+UN5ZBM3qQ=;
 b=s7QBvkr2M/7LlXCH7u4T7kGhNjKD+UEGgYObKwAiPkwJOUb/YCf5XOLGMPqL2P9zWjtZeWozU
 1YTYqOqXFULA3D4XrCefQz7WnGtLwUgiixx7AL+ou4ofz0QXoOYNVGG
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
Sasha Finkelstein (5):
      dt-bindgins: display: Add Apple pre-DCP display controller bindings
      gpu: drm: adp: Add Apple Display Pipe driver
      gpu: drm: adp: Add a backlight driver for the Summit LCD
      arm64: dts: apple: Add touchbar screen nodes
      MAINTAINERS: Add entries for touchbar display driver

 .../bindings/display/apple,display-pipe.yaml       |  59 ++
 .../bindings/display/panel/apple,summit.yaml       |  24 +
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t8103-j293.dts           |   8 +
 arch/arm64/boot/dts/apple/t8103.dtsi               |  26 +
 arch/arm64/boot/dts/apple/t8112-j493.dts           |  15 +
 arch/arm64/boot/dts/apple/t8112.dtsi               |  25 +
 drivers/gpu/drm/Kconfig                            |   2 +
 drivers/gpu/drm/Makefile                           |   1 +
 drivers/gpu/drm/adp/Kconfig                        |  14 +
 drivers/gpu/drm/adp/Makefile                       |   5 +
 drivers/gpu/drm/adp/adp_drv.c                      | 814 +++++++++++++++++++++
 drivers/gpu/drm/adp/panel-summit.c                 | 108 +++
 13 files changed, 1103 insertions(+)
---
base-commit: 9f16d5e6f220661f73b36a4be1b21575651d8833
change-id: 20241124-adpdrm-25fce3dd8a71

