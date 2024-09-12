From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:25:06 +0100
Subject: [PATCH 21/21] MAINTAINERS: add adi sc5xx maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240912-test-v1-21-458fa57c8ccf@analog.com>
References: <20240912-test-v1-0-458fa57c8ccf@analog.com>
In-Reply-To: <20240912-test-v1-0-458fa57c8ccf@analog.com>
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Greg Malysa <greg.malysa@timesys.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Utsav Agarwal <Utsav.Agarwal@analog.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Thomas Gleixner <tglx@linutronix.de>, 
 Andi Shyti <andi.shyti@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Arnd Bergmann <arnd@arndb.de>, 
 Olof Johansson <olof@lixom.net>, soc@kernel.org
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, linux-i2c@vger.kernel.org, 
 linux-serial@vger.kernel.org, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, adsp-linux@analog.com, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=1504;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=ZX6op8Gl0ef751bz5sRIH6+njR4ucuUIQX34HP/CQPA=;
 b=pw/W2wutLhh9kjOUSW6Xi3shvGEIMdgfhziVLJ7XQep5S3spWFWEsh5/dHPurSL35z/aVl4R/
 CbMlfycTJiNBWb3FgLJgU0x5+zMcX0/B+lU1ZvH6q/u84D7efC3RSP0
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ADSP-SC598 maitaniners

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
---
 MAINTAINERS | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 10430778c998b57944c1a6c5f07d676127e47faa..a838a5392321602034755fafed720f68d3798c0b 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1934,6 +1934,28 @@ S:	Odd Fixes
 F:	arch/arm/boot/dts/airoha/
 F:	arch/arm64/boot/dts/airoha/
 
+ARM/ADI SoC Support
+M:	Arturs Artamonovs <arturs.artamonovs@analog.com>
+M:	Greg Malysa <greg.malysa@timesys.com>
+S:	Maintained
+F:	Documentation/devicetree/bindings/arm/analog/adi,sc5xx.yaml
+F:	Documentation/devicetree/bindings/clock/adi,sc5xx-clocks.yaml
+F:	Documentation/devicetree/bindings/gpio/adi,adsp-port-gpio.yaml
+F:	Documentation/devicetree/bindings/i2c/adi,twi.yaml
+F:	Documentation/devicetree/bindings/interrupt-controller/adi,adsp-pint.yaml
+F:	Documentation/devicetree/bindings/pinctrl/adi,adsp-pinctrl.yaml
+F:	Documentation/devicetree/bindings/serial/adi,uart.yaml
+F:	Documentation/devicetree/bindings/serial/adi,uart.yaml
+F:	Documentation/devicetree/bindings/soc/adi/*
+F:	arch/arm64/boot/dts/adi/*
+F:	drivers/clk/adi/*
+F:	drivers/gpio/gpio-adi-adsp-port.c
+F:	drivers/i2c/busses/i2c-adi-twi.c
+F:	drivers/irqchip/irq-adi-adsp.c
+F:	drivers/soc/adi/*
+F:	drivers/tty/serial/adi_uart.c
+
+
 ARM/Allwinner SoC Clock Support
 M:	Emilio López <emilio@elopez.com.ar>
 S:	Maintained

-- 
2.25.1

