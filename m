From: Ben Grisdale <bengris32@protonmail.ch>
Subject: [PATCH 0/2] pinctrl: mediatek: Add MT8163 support
Date: Tue, 17 Nov 2026 21:00:40 +0000
Message-Id: <20261117-mt8163-pinctrl-v1-0-2cfd12206b17@protonmail.ch>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Nz3dwSC0MzY92CzLzkkqIc3SSDFAND0zQjYxOzJCWgpoKi1LTMCrC
 B0bEQfnFpUlZqcgnIFKXaWgB9SlqVcgAAAA==
X-Change-ID: 20261117-mt8163-pinctrl-b0d015f2346b
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794949947; l=902;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=1RUSaNQaX406sgZc8R8mxzN7Q315rl1SptZhofKDiBA=;
 b=iXMhQXmjmJwcA72ZEb9q/p7LA5/PVRKlDSXyJRUfsA8uP1/qdR69WaGrMAPELn1Axas5Tdwri
 /VtuCOgZJ+WDk3PnzY6T9ITFfXzfbdpPKHKftPL4mwiXxG/1sxny5Nk
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds device tree bindings and a pinctrl driver for the
MediaTek MT8163 SoC.

Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
Ben Grisdale (2):
      dt-bindings: pinctrl: mediatek: Add MT8163
      pinctrl: mediatek: Add support for MT8163 pinctrl

 .../bindings/pinctrl/mediatek,mt8163-pinctrl.yaml  |  208 ++++
 drivers/pinctrl/mediatek/Kconfig                   |   12 +
 drivers/pinctrl/mediatek/Makefile                  |    1 +
 drivers/pinctrl/mediatek/pinctrl-mt8163.c          |  478 +++++++
 drivers/pinctrl/mediatek/pinctrl-mtk-mt8163.h      | 1299 ++++++++++++++++++++
 .../dt-bindings/pinctrl/mediatek,mt8163-pinfunc.h  |  821 +++++++++++++
 6 files changed, 2819 insertions(+)
---
base-commit: 749a4de370409464cf8501ec5b2451df45c84eb4
change-id: 20261117-mt8163-pinctrl-b0d015f2346b

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

