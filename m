From: Arturs Artamonovs <arturs.artamonovs@analog.com>
Date: Thu, 12 Sep 2024 19:24:53 +0100
Subject: [PATCH 08/21] dt-bindings: clock: adi,sc5xx-clocks: add bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-test-v1-8-458fa57c8ccf@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726165513; l=2454;
 i=arturs.artamonovs@analog.com; s=20240909; h=from:subject:message-id;
 bh=FK1wS84c2c1JDb4uWuVca0i/beOgHv9nSZqxSxH0SWg=;
 b=w9Z7BRtwc4qeUvwgaNEz4dzqKZcH31enCAS4yvArHHPswdjADO8AxrRW0gyDV2QCF3wcyNrPw
 j4K3L4sgrtNCmK2g91XXJ+PsJqO7i2uu1EE2pvYlXMzGPgxvJ1TDhsJ
X-Developer-Key: i=arturs.artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for arturs.artamonovs@analog.com/20240909 with auth_id=206
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ADSP-SC5xx clock bindings.

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Co-developed-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Signed-off-by: Nathan Barrett-Morrison <nathan.morrison@timesys.com>
Co-developed-by: Greg Malysa <greg.malysa@timesys.com>
Signed-off-by: Greg Malysa <greg.malysa@timesys.com>
---
 .../bindings/clock/adi,sc5xx-clocks.yaml           | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/adi,sc5xx-clocks.yaml b/Documentation/devicetree/bindings/clock/adi,sc5xx-clocks.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..a092ebdefdcf89a635cdcf1073921efd28a38386
--- /dev/null
+++ b/Documentation/devicetree/bindings/clock/adi,sc5xx-clocks.yaml
@@ -0,0 +1,65 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/clock/adi,sc5xx-clocks.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Clock Tree Drivers for Analog Devices ADSP-SC5XX Processors
+
+maintainers:
+  - Arturs Artamonovs <arturs.artamonovs@analog.com>
+  - Utsav Agarwal <Utsav.Agarwal@analog.com>
+
+description: |
+  These drivers read in the processors CDU (clock distribution unit)
+  and CGU (clock generation unit) values to determine various clock
+  rates
+
+properties:
+  compatible:
+    enum:
+      - adi,sc598-clocks # 64-Bit SC598 processor
+
+  '#clock-cells':
+    const: 1
+
+  reg:
+    minItems: 3
+    maxItems: 4
+
+  clocks:
+    description:
+      Specifies the CLKIN0 and CLKIN1 reference clock(s) from which the
+      output frequencies are derived via CDU+CGU
+    minItems: 2
+    maxItems: 2
+
+  clock-names:
+    description:
+      String reference names for CLKIN0 and CLKIN1
+    minItems: 2
+    maxItems: 2
+
+required:
+  - compatible
+  - reg
+  - clocks
+  - '#clock-cells'
+  - clock-names
+
+additionalProperties: false
+
+examples:
+  - |
+    clk3: clocks@3108d000 {
+        compatible = "adi,sc598-clocks";
+        reg = <0x3108d000 0x1000>,
+              <0x3108e000 0x1000>,
+              <0x3108f000 0x1000>,
+              <0x310a9000 0x1000>;
+        #clock-cells = <1>;
+        clocks = <&sys_clkin0>, <&sys_clkin1>;
+        clock-names = "sys_clkin0", "sys_clkin1";
+        status = "okay";
+    };
+

-- 
2.25.1

