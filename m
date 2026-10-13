From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 13 Oct 2026 06:47:09 +0300
Subject: [PATCH v2 11/11] MAINTAINERS: Add Cortina Systems CS75xx interrupt
 controller, GPIO and I2C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-cs75xx-s2-v2-11-94f8c0a90cda@gmail.com>
References: <20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com>
In-Reply-To: <20261013-b4-cs75xx-s2-v2-0-94f8c0a90cda@gmail.com>
To: Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Russell King <linux@armlinux.org.uk>, 
 Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-i2c@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791863218; l=1164;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=8born+lqbJWHHfA9yx4+qhsEyHSP/MdbnsbUcNAg5HU=;
 b=OjNTRpBwm7+styelTVABzZsjoLC2URQ+UUV3d/JL3nx7F2z9ZI0k8C51Yde9/79AFIg6EV2pq
 2x3+2Tx9/XMCw9PV/yIWJDirVgp7ynI2YlO715uYMYpP8rklVOP2sUe
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

List the new Cortina Systems CS75xx interrupt controller, GPIO and I2C
drivers and their bindings in the CS75xx entry.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 MAINTAINERS | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 53f6fa1c5..604993705 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2925,10 +2925,16 @@ M:	Fil Dunsky <filipp.dunsky@gmail.com>
 L:	linux-arm-kernel@lists.infradead.org (moderated for non-subscribers)
 S:	Maintained
 F:	Documentation/devicetree/bindings/arm/cortina.yaml
+F:	Documentation/devicetree/bindings/gpio/cortina,cs7542-gpio.yaml
+F:	Documentation/devicetree/bindings/i2c/cortina,cs7542-i2c.yaml
+F:	Documentation/devicetree/bindings/interrupt-controller/cortina,cs7542-intc.yaml
 F:	Documentation/devicetree/bindings/serial/cortina,cs7542-uart.yaml
 F:	arch/arm/boot/dts/cortina/
 F:	arch/arm/include/debug/cs75xx.S
 F:	arch/arm/mach-goldengate/
+F:	drivers/gpio/gpio-cs75xx.c
+F:	drivers/i2c/busses/i2c-cs75xx.c
+F:	drivers/irqchip/irq-cs75xx.c
 F:	drivers/tty/serial/cortina-uart.c
 
 ARM/CORTINA SYSTEMS GEMINI ARM ARCHITECTURE

-- 
2.53.0

