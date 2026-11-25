From: Kyle Hendry <khendry@reliablecontrols.com>
Date: Wed, 25 Nov 2026 07:53:43 -0800
Subject: [PATCH v3 1/3] dt-bindings: clock: r9a06g032-sysctrl: Document
 reset cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-rzn1-miic-resets-v3-1-f25a4b656d71@reliablecontrols.com>
References: <20261125-rzn1-miic-resets-v3-0-f25a4b656d71@reliablecontrols.com>
In-Reply-To: <20261125-rzn1-miic-resets-v3-0-f25a4b656d71@reliablecontrols.com>
To: Geert Uytterhoeven <geert+renesas@glider.be>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Magnus Damm <magnus.damm@gmail.com>, 
 Fabrizio Castro <fabrizio.castro.jz@renesas.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-renesas-soc@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Kyle Hendry <khendry@reliablecontrols.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795622048; l=1778;
 i=khendry@reliablecontrols.com; s=20260813; h=from:subject:message-id;
 bh=b/QqGL4gpzDc/pZlATaU8inxdTKev9TR0QMXaAdJ4ms=;
 b=254cvQmnEJOj02SCmniiQdTBKPZ/CJ3q1NtE46KOUfh6xu+00xPR+a/iKJGK9Cpf8Sjo1H54H
 +Ymo/2xFz27Dn/ZylqIbimTuxkA85VTb/jdopJu5GXu/wrrUaq57xnx
X-Developer-Key: i=khendry@reliablecontrols.com; a=ed25519;
 pk=gbK6oghz3qBlBiaGCsEzALLOtj5VklmsuolHQNhDV5M=
X-Endpoint-Received: by B4 Relay for khendry@reliablecontrols.com/20260813 with auth_id=946
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the rzn1 system controller to indicate it can be a reset controller
and add defines for miic resets

Signed-off-by: Kyle Hendry <khendry@reliablecontrols.com>
---
 .../devicetree/bindings/clock/renesas,r9a06g032-sysctrl.yaml         | 5 +++++
 include/dt-bindings/clock/r9a06g032-sysctrl.h                        | 3 +++
 2 files changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/renesas,r9a06g032-sysctrl.yaml b/Documentation/devicetree/bindings/clock/renesas,r9a06g032-sysctrl.yaml
index 26d94cedc871..70ccc315a10c 100644
--- a/Documentation/devicetree/bindings/clock/renesas,r9a06g032-sysctrl.yaml
+++ b/Documentation/devicetree/bindings/clock/renesas,r9a06g032-sysctrl.yaml
@@ -36,6 +36,9 @@ properties:
   '#clock-cells':
     const: 1
 
+  '#reset-cells':
+    const: 1
+
   '#power-domain-cells':
     const: 0
 
@@ -56,6 +59,7 @@ required:
   - clocks
   - clock-names
   - '#clock-cells'
+  - '#reset-cells'
   - '#power-domain-cells'
 
 additionalProperties: false
@@ -69,5 +73,6 @@ examples:
                      <&ext_rgmii_ref>;
             clock-names = "mclk", "rtc", "jtag", "rgmii_ref_ext";
             #clock-cells = <1>;
+            #reset-cells = <1>;
             #power-domain-cells = <0>;
     };
diff --git a/include/dt-bindings/clock/r9a06g032-sysctrl.h b/include/dt-bindings/clock/r9a06g032-sysctrl.h
index d9d7b8b4f426..244f5b221642 100644
--- a/include/dt-bindings/clock/r9a06g032-sysctrl.h
+++ b/include/dt-bindings/clock/r9a06g032-sysctrl.h
@@ -146,4 +146,7 @@
 #define R9A06G032_CLK_UART6		152
 #define R9A06G032_CLK_UART7		153
 
+#define R9A06G032_RST_TS		0
+#define R9A06G032_RST_MIIC		1
+
 #endif /* __DT_BINDINGS_R9A06G032_SYSCTRL_H__ */

-- 
2.53.0

