From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:49 +0100
Subject: [PATCH 04/21] dt-bindings: arm64: adi,sc598: Add ADSP-SC598 SoC
 bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-4-458fa57c8ccf@analog.com>
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
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=1623;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=J/EuJUpRixtiC/Xhn+9Y770N03I2X4hm7a/3wJC2XVg=;
 b=R9KdkvfGVHCd5bCvdZq8qKxmeajLuKI+hlHTFb+pbWAQDWDoXhfEOnOZ5i5NTWG/+O7XX5yRE
 y6kVkSWYiyfBVn1snKVwFxUZTDwNmRMmpVlpC0KLbcw86AkHCFcMMrz
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

add  SoC ADSP-SC5xx

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Signed-off-by: Utsav Agarwal <Utsav.Agarwal@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 .../devicetree/bindings/arm/analog/adi,sc5xx.yaml  | 24 ++++++++++++++++++++++
 1 file changed, 24 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/analog/adi,sc5xx.yaml b/Documentation/devicetree/bindings/arm/analog/adi,sc5xx.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..fc37242b32b9ca9b82fd5b3e0288642e8c4fd9f0
--- /dev/null
+++ b/Documentation/devicetree/bindings/arm/analog/adi,sc5xx.yaml
@@ -0,0 +1,24 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/arm/analog/adi,sc5xx.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices SC59X 64-Bit ARM-based Processor Families
+
+maintainers:
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+  - Utsav Agarwal <Utsav.Agarwal@analog.com>
+
+properties:
+  $nodename:
+    const: '/'
+  compatible:
+    description: SC59X 64-Bit Boards
+    items:
+      - enum:
+          - adi,sc598-som-ezkit                # Analog Devices SC598 EZKit
+          - adi,sc598-som-ezlite               # Analog Devices SC598 EZLite
+      - const: adi,sc59x-64
+
+additionalProperties: true

-- 
2.25.1

