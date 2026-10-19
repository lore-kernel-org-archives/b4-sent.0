From: Ben Grisdale <bengris32@protonmail.ch>
Date: Mon, 19 Oct 2026 01:40:01 +0100
Subject: [PATCH 5/8] dt-bindings: watchdog: mediatek,mtk-wdt: Add MT8163
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-5-f2462b2d2437@protonmail.ch>
References: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
In-Reply-To: <20261019-arm64-initial-support-for-mediatek-mt8163-soc-v1-0-f2462b2d2437@protonmail.ch>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, Thomas Gleixner <tglx@kernel.org>, 
 Radu Rendec <radu@rendec.net>, Daniel Lezcano <daniel.lezcano@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-serial@vger.kernel.org, linux-watchdog@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792370441; l=2097;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=Vulm21NvWmavPeagurzk/kzAQkRmOdO7M6nqGQtWAlM=;
 b=GVu4gT99GFaTJ/F/Oke2/vOoYoNcqwzj/sP4S54j3BL0yNla+HRzsTkjX4BSOY8+11cfZic1H
 /SoNNOWwGP2AHpfZTYtLPOlNvzIOAD+gaa3Y1WtvjoihU+2PT9Kz8Dc
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the Top Reset Generation Unit (TOPRGU) and
watchdog timer on the MediaTek MT8163 SoC, along with a header defining
the reset IDs it provides.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |  1 +
 include/dt-bindings/reset/mediatek,mt8163-wdt.h    | 23 ++++++++++++++++++++++
 2 files changed, 24 insertions(+)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index f9b725592c27..8e8991ac95ea 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -26,6 +26,7 @@ properties:
           - mediatek,mt6795-wdt
           - mediatek,mt7986-wdt
           - mediatek,mt7988-wdt
+          - mediatek,mt8163-wdt
           - mediatek,mt8167-wdt
           - mediatek,mt8183-wdt
           - mediatek,mt8186-wdt
diff --git a/include/dt-bindings/reset/mediatek,mt8163-wdt.h b/include/dt-bindings/reset/mediatek,mt8163-wdt.h
new file mode 100644
index 000000000000..e6add5281e65
--- /dev/null
+++ b/include/dt-bindings/reset/mediatek,mt8163-wdt.h
@@ -0,0 +1,23 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_RESET_MEDIATEK_MT8163_WDT_H_
+#define _DT_BINDINGS_RESET_MEDIATEK_MT8163_WDT_H_
+
+/* TOPRGU resets */
+#define MT8163_TOPRGU_INFRA_RST		0
+#define MT8163_TOPRGU_MM_RST		1
+#define MT8163_TOPRGU_MFG_RST		2
+#define MT8163_TOPRGU_VENC_RST		3
+#define MT8163_TOPRGU_VDEC_RST		4
+#define MT8163_TOPRGU_IMG_RST		5
+#define MT8163_TOPRGU_DDRPHY_RST	6
+#define MT8163_TOPRGU_MD_RST		7
+#define MT8163_TOPRGU_INFRA_AO_RST	8
+#define MT8163_TOPRGU_CONN_RST		9
+#define MT8163_TOPRGU_APMIXED_RST	10
+#define MT8163_TOPRGU_PWRAP_SPICTL_RST	11
+#define MT8163_TOPRGU_CONN_MCU_RST	12
+#define MT8163_TOPRGU_MJC_RST		13
+#define MT8163_TOPRGU_MDLITE_RST	14
+
+#endif /* _DT_BINDINGS_RESET_MEDIATEK_MT8163_WDT_H_ */

-- 
2.56.0

