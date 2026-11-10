From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 10 Nov 2026 21:22:21 +0200
Subject: [PATCH 1/3] dt-bindings: watchdog: mediatek,mtk-wdt: fix mt6797
 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-6797-wdt-v1-1-7f07755b6074@protonmail.com>
References: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
In-Reply-To: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
To: Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Ben Grisdale <bengris32@protonmail.ch>, linux-watchdog@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794338551; l=3012;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Zw97QWbf++CwhqrLj51/69tH/MLwpOaRQogdPi+R4S0=;
 b=8oQIrY9yvADvaSdBrJfYTzEmQNP0HQ2PwbUUgck0/rybLTdtwhNV/ylo/EN0MVnBLhBV8kfDk
 E+Y/Bjfg6pmAyPrlVhtEc8ce93ohgTTUQcCvAc/MxK0gwLDy9p+MfZU
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TOPRGU reset bits on the mt6797 SoC do not match that of mt6589,
therefore they are not compatible [1].

Deprecate the mt6589 fallback for mt6797 and add its own compatible
string. Also add a new binding header for the actual watchdog resets on
the SoC.

Link: https://www.96boards.org/documentation/consumer/mediatekx20/additional-docs/docs/MT6797_Register_Table_Part_1.pdf [1]
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |  6 +++++-
 include/dt-bindings/reset/mediatek,mt6797-wdt.h    | 25 ++++++++++++++++++++++
 2 files changed, 30 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index 8e8991ac95ea..d9b5675794cc 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -24,6 +24,7 @@ properties:
           - mediatek,mt6589-wdt
           - mediatek,mt6735-wdt
           - mediatek,mt6795-wdt
+          - mediatek,mt6797-wdt
           - mediatek,mt7986-wdt
           - mediatek,mt7988-wdt
           - mediatek,mt8163-wdt
@@ -38,7 +39,6 @@ properties:
               - mediatek,mt2701-wdt
               - mediatek,mt6572-wdt
               - mediatek,mt6582-wdt
-              - mediatek,mt6797-wdt
               - mediatek,mt7622-wdt
               - mediatek,mt7623-wdt
               - mediatek,mt7629-wdt
@@ -49,6 +49,10 @@ properties:
               - mediatek,mt8365-wdt
               - mediatek,mt8516-wdt
           - const: mediatek,mt6589-wdt
+      - items:
+          - const: mediatek,mt6797-wdt
+          - const: mediatek,mt6589-wdt
+        deprecated: true
 
   reg:
     maxItems: 1
diff --git a/include/dt-bindings/reset/mediatek,mt6797-wdt.h b/include/dt-bindings/reset/mediatek,mt6797-wdt.h
new file mode 100644
index 000000000000..32a2bdaf47c7
--- /dev/null
+++ b/include/dt-bindings/reset/mediatek,mt6797-wdt.h
@@ -0,0 +1,25 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_RESET_MEDIATEK_MT6797_WDT_H_
+#define _DT_BINDINGS_RESET_MEDIATEK_MT6797_WDT_H_
+
+/* TOPRGU resets */
+#define MT6797_TOPRGU_INFRA_RST		0
+#define MT6797_TOPRGU_MM_RST		1
+#define MT6797_TOPRGU_MFG_RST		2
+#define MT6797_TOPRGU_VENC_RST		3
+#define MT6797_TOPRGU_VDEC_RST		4
+#define MT6797_TOPRGU_IMG_RST		5
+#define MT6797_TOPRGU_DDRPHY_RST	6
+#define MT6797_TOPRGU_MD_RST		7
+#define MT6797_TOPRGU_INFRA_AO_RST	8
+#define MT6797_TOPRGU_CONN_RST		9
+#define MT6797_TOPRGU_APMIXED_RST	10
+#define MT6797_TOPRGU_PWRAP_SPICTL_RST	11
+#define MT6797_TOPRGU_CONN_MCU_RST	12
+#define MT6797_TOPRGU_MJC_RST		13
+#define MT6797_TOPRGU_AUDIO_RST		14
+#define MT6797_TOPRGU_C2K_SYS_RST	15
+#define MT6797_TOPRGU_C2K_WDT_RST	16
+
+#endif /* _DT_BINDINGS_RESET_MEDIATEK_MT6797_WDT_H_ */

-- 
2.56.0

