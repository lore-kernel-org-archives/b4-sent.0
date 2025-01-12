From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sun, 12 Jan 2025 21:43:52 +0100
Subject: [PATCH v3 5/5] MAINTAINERS: Add entries for touchbar display
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250112-adpdrm-v3-5-c674dc19fa7f@gmail.com>
References: <20250112-adpdrm-v3-0-c674dc19fa7f@gmail.com>
In-Reply-To: <20250112-adpdrm-v3-0-c674dc19fa7f@gmail.com>
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
 Alyssa Ross <hi@alyssa.is>, Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736714637; l=1377;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=KEf80SVHicxgRXKAdu52Cd2dNEz+kgXSg0wZwqOZ7j0=;
 b=Z6vQ9xWGPgienAp28uq2+kCpuQpCu6k/45FtO0pxfnHFT/eJDa83aXt0knen4AeoNyHpA9yia
 2wsfvQYhsnIDUSugsd+fcOv8bNSbL4PRa7zUR7LIMw6YpEH98MoN04o
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the MAINTAINERS entries for the driver

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 MAINTAINERS | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index a87ddad78e26f28ffd0f3433560d6db1518f9f95..4ce0d3bcf67910d909ba41261535dcb14a24a7b7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2189,6 +2189,9 @@ F:	Documentation/devicetree/bindings/arm/apple.yaml
 F:	Documentation/devicetree/bindings/arm/apple/*
 F:	Documentation/devicetree/bindings/clock/apple,nco.yaml
 F:	Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
+F:	Documentation/devicetree/bindings/display/apple,h7-display-pipe-mipi.yaml
+F:	Documentation/devicetree/bindings/display/apple,h7-display-pipe.yaml
+F:	Documentation/devicetree/bindings/display/panel/apple,summit.yaml
 F:	Documentation/devicetree/bindings/dma/apple,admac.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*
@@ -2208,6 +2211,8 @@ F:	drivers/bluetooth/hci_bcm4377.c
 F:	drivers/clk/clk-apple-nco.c
 F:	drivers/cpufreq/apple-soc-cpufreq.c
 F:	drivers/dma/apple-admac.c
+F:	drivers/gpu/drm/adp/
+F:	drivers/gpu/drm/panel/panel-summit.c
 F:	drivers/pmdomain/apple/
 F:	drivers/i2c/busses/i2c-pasemi-core.c
 F:	drivers/i2c/busses/i2c-pasemi-platform.c

-- 
2.48.0

