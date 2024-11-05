From: Janne Grunau <j@jannau.net>
Date: Tue, 05 Nov 2024 09:08:31 +0100
Subject: [PATCH v4 3/3] MAINTAINERS: Add apple-spi driver & binding files
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241105-asahi-spi-v4-3-d9734f089fc9@jannau.net>
References: <20241105-asahi-spi-v4-0-d9734f089fc9@jannau.net>
In-Reply-To: <20241105-asahi-spi-v4-0-d9734f089fc9@jannau.net>
To: Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1316; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=wbyAeXiak8ymhiqSGZePVuZ0IdBpI3guim8H/E8/EiU=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhnTNS108395K5IUrH/g/VV7tzRLHX6bnBC9+Nbq/7JzAu
 X3pJQ3lHaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACYSy8fI8Lv23gIeRveQYJkH
 wa/kZ+YocU3de2RWgcBSdevGhcdKcxgZjqT5Hu6+cPjvHmPbfwZ23+zKTO8VbnjUYCcozq/yaos
 5KwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

This Apple SPI controller is present on Apple ARM SoCs (t8103/t6000).

Splitting this change from the binding/driver commits to avoid merge
conflicts with other things touching this section, as usual.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 MAINTAINERS | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index cc40a9d9b8cd10e2e00caa5a5881381cd40c0d9a..552febcb12a95766ff502960782941d9d016d5e0 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2068,6 +2068,7 @@ F:	Documentation/devicetree/bindings/pci/apple,pcie.yaml
 F:	Documentation/devicetree/bindings/pinctrl/apple,pinctrl.yaml
 F:	Documentation/devicetree/bindings/power/apple*
 F:	Documentation/devicetree/bindings/pwm/apple,s5l-fpwm.yaml
+F:	Documentation/devicetree/bindings/spi/apple,spi.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml
 F:	arch/arm64/boot/dts/apple/
 F:	drivers/bluetooth/hci_bcm4377.c
@@ -2085,6 +2086,7 @@ F:	drivers/nvmem/apple-efuses.c
 F:	drivers/pinctrl/pinctrl-apple-gpio.c
 F:	drivers/pwm/pwm-apple.c
 F:	drivers/soc/apple/*
+F:	drivers/spi/spi-apple.c
 F:	drivers/watchdog/apple_wdt.c
 F:	include/dt-bindings/interrupt-controller/apple-aic.h
 F:	include/dt-bindings/pinctrl/apple.h

-- 
2.47.0

