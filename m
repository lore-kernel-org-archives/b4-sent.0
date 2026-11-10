From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH 0/3] watchdog: mediatek: fix mt6797
Date: Tue, 10 Nov 2026 21:22:20 +0200
Message-Id: <20261110-6797-wdt-v1-0-7f07755b6074@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MDXTNzS3Pd8pQS3dREAxNTCzOzZEtjMyWg8oKi1LTMCrBR0bEQfnF
 pUlZqcglIv1JtLQA5GQiZbAAAAA==
X-Change-ID: 20261110-6797-wdt-ea045866c936
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794338551; l=979;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=YuCtHZXtAm427+WUFBsF2fwoSMRhW21Cd4n+6tsctgU=;
 b=X9izG8476fidywRoRhvuRH/2/lNsb1YV3dppMtAdUa7unbApAM95ag7j0PgxItcT54aiKLXln
 qDG8auL6RscAMxy95MMQx0tVRM9dMuUrrZQ9x4RfTPdUV61Y30HVmbB
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes improper mt6797 watchdog compatible, since it's
actually different from the mt6589. It also adds own reset header for
the SoC and reset table in the driver to mapping IDs to bits.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Roman Vivchar (3):
      dt-bindings: watchdog: mediatek,mtk-wdt: fix mt6797 compatible
      watchdog: mediatek: add mt6797 support
      arm64: dts: mediatek: mt6797: fix wdt compatible and add reset-cells

 .../bindings/watchdog/mediatek,mtk-wdt.yaml        |  6 ++++-
 arch/arm64/boot/dts/mediatek/mt6797.dtsi           |  3 ++-
 drivers/watchdog/mtk_wdt.c                         | 27 ++++++++++++++++++++++
 include/dt-bindings/reset/mediatek,mt6797-wdt.h    | 25 ++++++++++++++++++++
 4 files changed, 59 insertions(+), 2 deletions(-)
---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261110-6797-wdt-ea045866c936

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

