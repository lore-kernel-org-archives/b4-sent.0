From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 12 May 2026 08:18:30 +0300
Subject: [PATCH v2 16/16] MAINTAINERS: add MediaTek mt6323 PMIC thermal
 driver maintainer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-mt6323-v2-16-3efcba579e88@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778563297; l=692;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=8NVcmhjcZUhwoicnOrm6owXnni+d+cpxkUFwQ33c1Hk=;
 b=WuN6e8eFt0NDrjantucW+k4aytcYOhKb5NQLI+Q1K4YIL4RECU79bvOV8PH7sNGpbJyeE4bU4
 iSn4SKfdH5aBINvQ7Sxh1OHbZdW6DFMOJXAR0+SgjlrMcnNwh/x96mn
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add myself as MediaTek mt6323 thermal driver maintainer.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 MAINTAINERS | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index bf2e066f377d..3001a713b083 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16355,6 +16355,11 @@ S:	Maintained
 F:	Documentation/devicetree/bindings/mfd/mediatek,mt6397.yaml
 F:	drivers/leds/leds-mt6323.c
 
+MEDIATEK PMIC THERMAL DRIVER
+M:	Roman Vivchar <rva333@protonmail.com>
+S:	Odd Fixes
+F:	drivers/thermal/mediatek/mtk_pmic_thermal.c
+
 MEDIATEK RANDOM NUMBER GENERATOR SUPPORT
 M:	Sean Wang <sean.wang@mediatek.com>
 S:	Maintained

-- 
2.54.0

