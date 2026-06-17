From: Zakariya Hadrami <zkh1@proton.me>
Subject: [PATCH 0/5] ARM: Basic support for Amazon ford tablet (MT8127)
Date: Wed, 17 Jun 2026 11:20:09 +0900
Message-Id: <20260617-mt8127-amazon-ford-basic-v1-0-d02ad15ac359@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtQIa2uEi0sx5pFGhoRRXdPW
 r7F/w9kSkwZ+uqBRCdnjqFA1hXMqw0LIbtiUEJpoaXG7WilMmg3e8eAPiaHk808o2xE54xolDc
 EJd8Teb7+9TC+7wekhZpNagAAAA==
X-Change-ID: 20260616-mt8127-amazon-ford-basic-1509d7052f7e
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-watchdog@vger.kernel.org, Zakariya Hadrami <zkh1@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781662870; l=1062;
 i=zkh1@proton.me; s=20260616; h=from:subject:message-id;
 bh=GFQoPV3WSoQdmzXdEnr9RQpM8gwotYzPgFgNyL8Njlg=;
 b=Lnn0C+XMaDV70G3zD+InDGE4e36gL4nUCacmUuRTqeWQ759q9hdycCmbbi/Bn4/ihasRdRfq/
 H/uL66rDQj8D8WO1ljPLaBjdd5oU40qoLdSsUmCuPD1JLcNh22QZ0zf
X-Developer-Key: i=zkh1@proton.me; a=ed25519;
 pk=9DiJwhINAERP95fbFofXSP77GEnvfO/rMIRRRFDhaoc=
X-Endpoint-Received: by B4 Relay for zkh1@proton.me/20260616 with auth_id=824
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series of patches adds basic support for MT8127 SoC based Amazon ford
tablet and fixes a small indentation error in the dtsi file.

Signed-off-by: Zakariya Hadrami <zkh1@proton.me>
---
Zakariya Hadrami (5):
      ARM: dts: mediatek: mt8127: Fix indentation error
      ARM: dts: mediatek: mt8127: Add watchdog support
      ARM: dts: mediatek: Add basic support for Amazon ford board
      dt-bindings: arm: mediatek: Add MT8127 Amazon ford
      dt-bindings: watchdog: mediatek: Add MT8127

 .../devicetree/bindings/arm/mediatek.yaml          |  4 ++
 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |  1 +
 arch/arm/boot/dts/mediatek/Makefile                |  1 +
 arch/arm/boot/dts/mediatek/mt8127-amazon-ford.dts  | 46 ++++++++++++++++++++++
 arch/arm/boot/dts/mediatek/mt8127.dtsi             |  9 ++++-
 5 files changed, 60 insertions(+), 1 deletion(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260616-mt8127-amazon-ford-basic-1509d7052f7e

Best regards,
-- 
Zakariya Hadrami <zkh1@proton.me>

