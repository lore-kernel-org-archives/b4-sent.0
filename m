From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 12 May 2026 08:18:16 +0300
Subject: [PATCH v2 02/16] dt-bindings: iio: adc: mt6359: add mt6323 PMIC
 AUXADC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-mt6323-v2-2-3efcba579e88@protonmail.com>
References: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
In-Reply-To: <20260512-mt6323-v2-0-3efcba579e88@protonmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sen Chu <sen.chu@mediatek.com>, Sean Wang <sean.wang@mediatek.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Lee Jones <lee@kernel.org>, 
 Roman Vivchar <rva333@protonmail.com>, 
 Srinivas Kandagatla <srini@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, linux-pm@vger.kernel.org, 
 Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778563297; l=2076;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=c+cho/PX2cVaRg83PkB7K4s9HbnpwnddIKtcnK+QK9k=;
 b=W7KS0FHZxgzCrz3uoUR4XNBLsEDNUbCPF9yCBrCkA6/sQUCqk5mobEFYHMenvIGL1QQYOBSqf
 ftGX9yLmp7bD0duUSPjiUK2UC95xLJR11EZkRen5tQbZ1DTrigd7T99
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MediaTek mt6323 PMIC includes an AUXADC used for battery voltage,
temperature, and other internal measurements.

Add the devicetree binding documentation and the associated header file
defining the ADC channel constants.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 .../bindings/iio/adc/mediatek,mt6359-auxadc.yaml   |  1 +
 .../dt-bindings/iio/adc/mediatek,mt6323-auxadc.h   | 24 ++++++++++++++++++++++
 2 files changed, 25 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/mediatek,mt6359-auxadc.yaml b/Documentation/devicetree/bindings/iio/adc/mediatek,mt6359-auxadc.yaml
index 2e8857e104f5..1cafc314b8ab 100644
--- a/Documentation/devicetree/bindings/iio/adc/mediatek,mt6359-auxadc.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/mediatek,mt6359-auxadc.yaml
@@ -19,6 +19,7 @@ description:
 properties:
   compatible:
     enum:
+      - mediatek,mt6323-auxadc
       - mediatek,mt6357-auxadc
       - mediatek,mt6358-auxadc
       - mediatek,mt6359-auxadc
diff --git a/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h b/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h
new file mode 100644
index 000000000000..6ee9a9ecffc1
--- /dev/null
+++ b/include/dt-bindings/iio/adc/mediatek,mt6323-auxadc.h
@@ -0,0 +1,24 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause) */
+
+#ifndef _DT_BINDINGS_MEDIATEK_MT6323_AUXADC_H
+#define _DT_BINDINGS_MEDIATEK_MT6323_AUXADC_H
+
+#define MT6323_AUXADC_BATON2		0
+#define MT6323_AUXADC_CH6		1
+#define MT6323_AUXADC_BAT_TEMP		2
+#define MT6323_AUXADC_CHIP_TEMP		3
+#define MT6323_AUXADC_VCDT		4
+#define MT6323_AUXADC_BATON1		5
+#define MT6323_AUXADC_ISENSE		6
+#define MT6323_AUXADC_BATSNS		7
+#define MT6323_AUXADC_ACCDET		8
+#define MT6323_AUXADC_AUDIO0		9
+#define MT6323_AUXADC_AUDIO1		10
+#define MT6323_AUXADC_AUDIO2		11
+#define MT6323_AUXADC_AUDIO3		12
+#define MT6323_AUXADC_AUDIO4		13
+#define MT6323_AUXADC_AUDIO5		14
+#define MT6323_AUXADC_AUDIO6		15
+#define MT6323_AUXADC_AUDIO7		16
+
+#endif

-- 
2.54.0

