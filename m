From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Tue, 26 Nov 2024 17:34:24 +0100
Subject: [PATCH v2 5/5] MAINTAINERS: Add entries for touchbar display
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-adpdrm-v2-5-c90485336c09@gmail.com>
References: <20241126-adpdrm-v2-0-c90485336c09@gmail.com>
In-Reply-To: <20241126-adpdrm-v2-0-c90485336c09@gmail.com>
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
 Sasha Finkelstein <fnkl.kernel@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732638864; l=1377;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=057O2QJ+HomyrdJxEs81SKNbrttf8RRSnPZG4/DJono=;
 b=fsafhQ9T/0iPVL1f2ug/lulQ4LAEiGM8pEMFL6tskRpMzrAEhThtjvm5FUNrO8cFEn+v+D617
 5KX46QgKejRCPaXEtpWa/PGqCGL9lCoVMHsJYdwzjBkEw2HKJsS1CvH
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
index e7f0170977013889ca7c39b17727ba36d32e92dc..9a2fb7cd80e09f24932b91cd33d0cd2b3514b31c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2164,6 +2164,9 @@ F:	Documentation/devicetree/bindings/arm/apple.yaml
 F:	Documentation/devicetree/bindings/arm/apple/*
 F:	Documentation/devicetree/bindings/clock/apple,nco.yaml
 F:	Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
+F:	Documentation/devicetree/bindings/display/apple,h7-display-pipe-mipi.yaml
+F:	Documentation/devicetree/bindings/display/apple,h7-display-pipe.yaml
+F:	Documentation/devicetree/bindings/display/panel/apple,summit.yaml
 F:	Documentation/devicetree/bindings/dma/apple,admac.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*
@@ -2183,6 +2186,8 @@ F:	drivers/bluetooth/hci_bcm4377.c
 F:	drivers/clk/clk-apple-nco.c
 F:	drivers/cpufreq/apple-soc-cpufreq.c
 F:	drivers/dma/apple-admac.c
+F:	drivers/gpu/drm/adp/
+F:	drivers/gpu/drm/panel/panel-summit.c
 F:	drivers/pmdomain/apple/
 F:	drivers/i2c/busses/i2c-pasemi-core.c
 F:	drivers/i2c/busses/i2c-pasemi-platform.c

-- 
2.47.1

