From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Sat, 11 Mar 2023 06:11:13 +0100
Subject: [PATCH v9 5/5] MAINTAINERS: Add entries for Apple PWM driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230214-fpwm-v9-5-dbe26bccabd6@gmail.com>
References: <20230214-fpwm-v9-0-dbe26bccabd6@gmail.com>
In-Reply-To: <20230214-fpwm-v9-0-dbe26bccabd6@gmail.com>
To: Thierry Reding <thierry.reding@gmail.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@pengutronix.de>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 - <asahi@lists.linux.dev>, Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Hector Martin <marcan@marcan.st>, Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678511469; l=1109;
 i=fnkl.kernel@gmail.com; s=20230213; h=from:subject:message-id;
 bh=H0yqy74irk0iRnaCY9EguySiHLNBuNpFanSkZMAqDr0=;
 b=XwoGQYfCG0nhebSIi6bZqylI139vfZRnNb5i3ffwsoD6hC3VPSnJR7/CCGK2csjgK4K8JKrs+
 JkUOEjeyKU4Agrc6a+IceoLTgo8Y+zHDvlWdJixf2xENShxDXGBnZc1
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=7LFSAJtxIWAs9LzCIyX0sSvCZy2wQTyEIu1zch6o804=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20230213 with auth_id=28
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the MAINTAINERS entries for the driver

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
Acked-by: Sven Peter <sven@svenpeter.dev>
---
 MAINTAINERS | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 8d5bc223f305..7c0b7c2bb55f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1955,6 +1955,7 @@ F:	Documentation/devicetree/bindings/nvmem/apple,efuses.yaml
 F:	Documentation/devicetree/bindings/pci/apple,pcie.yaml
 F:	Documentation/devicetree/bindings/pinctrl/apple,pinctrl.yaml
 F:	Documentation/devicetree/bindings/power/apple*
+F:	Documentation/devicetree/bindings/pwm/pwm-apple.yaml
 F:	Documentation/devicetree/bindings/watchdog/apple,wdt.yaml
 F:	arch/arm64/boot/dts/apple/
 F:	drivers/bluetooth/hci_bcm4377.c
@@ -1970,6 +1971,7 @@ F:	drivers/mailbox/apple-mailbox.c
 F:	drivers/nvme/host/apple.c
 F:	drivers/nvmem/apple-efuses.c
 F:	drivers/pinctrl/pinctrl-apple-gpio.c
+F:	drivers/pwm/pwm-apple.c
 F:	drivers/soc/apple/*
 F:	drivers/watchdog/apple_wdt.c
 F:	include/dt-bindings/interrupt-controller/apple-aic.h

-- 
Git-137.1)

