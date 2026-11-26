From: Roman Vivchar <rva333@protonmail.com>
Date: Thu, 26 Nov 2026 14:39:56 +0200
Subject: [PATCH 3/8] dt-bindings: watchdog: mediatek,mtk-wdt: add mt6768
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-6768-init-v1-3-abc364a2447e@protonmail.com>
References: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
In-Reply-To: <20261126-6768-init-v1-0-abc364a2447e@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Radu Rendec <radu@rendec.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795696875; l=1885;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=aH0siMLM19GbpIna6FTZmhfIkS4nKiHnuKEgLlr6TYI=;
 b=bApZzV91JzAk9Q5+fVhxb13HvL6/TMxJR8PEtOAHRZiqj9drOyY4gngo9qfX/7d18Ip6QK2+O
 ANBx5cq1zoQBiCjdzBKOqPQwsVW3aN40hoesqPYsu0m1HztotDyNajp
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the MT6768 watchdog and a binding header
with its reset IDs.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/watchdog/mediatek,mtk-wdt.yaml           |  1 +
 include/dt-bindings/reset/mediatek,mt6768-wdt.h       | 19 +++++++++++++++++++
 2 files changed, 20 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index 72abc9cdc007..55e687b4a6fa 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -23,6 +23,7 @@ properties:
           - mediatek,mt2712-wdt
           - mediatek,mt6589-wdt
           - mediatek,mt6735-wdt
+          - mediatek,mt6768-wdt
           - mediatek,mt6795-wdt
           - mediatek,mt6797-wdt
           - mediatek,mt6833-wdt
diff --git a/include/dt-bindings/reset/mediatek,mt6768-wdt.h b/include/dt-bindings/reset/mediatek,mt6768-wdt.h
new file mode 100644
index 000000000000..d5af8f106ad4
--- /dev/null
+++ b/include/dt-bindings/reset/mediatek,mt6768-wdt.h
@@ -0,0 +1,19 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_RESET_MEDIATEK_MT6768_WDT_H_
+#define _DT_BINDINGS_RESET_MEDIATEK_MT6768_WDT_H_
+
+#define MT6768_TOPRGU_MM_RST			0
+#define MT6768_TOPRGU_MFG_RST			1
+#define MT6768_TOPRGU_VENC_RST			2
+#define MT6768_TOPRGU_VDEC_RST			3
+#define MT6768_TOPRGU_IMG_RST			4
+#define MT6768_TOPRGU_MD_RST			5
+#define MT6768_TOPRGU_CONN_RST			6
+#define MT6768_TOPRGU_APMIXED_RST		7
+#define MT6768_TOPRGU_CONN_MCU_RST		8
+#define MT6768_TOPRGU_C2K_RST			9
+#define MT6768_TOPRGU_AUDIO_RST			10
+#define MT6768_TOPRGU_CAMSYS_RST		11
+
+#endif /* _DT_BINDINGS_RESET_MEDIATEK_MT6768_WDT_H_ */

-- 
2.56.1

