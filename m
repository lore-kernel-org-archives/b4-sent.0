From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/2] Initial Amediatech X96Q support based on Allwinner
 H313
Date: Thu, 18 Sep 2025 12:58:42 +0200
Message-Id: <20250918-x96q-v2-0-51bd39928806@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOLly2gC/zXMSw7CIBSF4a00dyyGRx/gyH2YDtDe2juBCoTUN
 OxdrHH4n5x8O0QMhBEuzQ4BM0XyroY8NfBYrHsio6k2SC47boRgm+lfrBuwV0pzzVuEel0DzrQ
 dzG2svVBMPrwPNYvv+gfkD8iCcabbQUzWzspM9+vqY0J/dphgLKV8ABL5JE+ZAAAA
X-Change-ID: 20250911-x96q-57e63380804e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758193136; l=1208;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=LL/Uw6VE1EBTQfjT9hHDOnQ6gjK5F3ud8EjZ7zF1IIY=;
 b=b8FZND3HZqDv0aMwfb+6qib/2eYbxutllyTSOaHscNvnojhJl4jYWwTmXgAGP3vddNoNTaqKs
 JjrhlLVOWdXCExdZ5LQB51ANHIyoWqR/qMs616ntY3FzhUaJ/sRWzHQ
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds an initial devicetree for the X96Q set-top box.
WiFi, Ethernet, and HDMI depend on drivers that are currently not
available in mainline Linux, and I didn't even get the SDIO WiFi chip to
enumerate, so I left these peripherals out of the in the devicetree.

The builtin infrared receiver produces IRQs when a nearby remote sends
events, but they somehow don't end up in /dev/input/event0.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Several dts improvements thanks to Andre Przywara's review
- Andre's Reviewed-by tag for the binding
- Link to v1: https://lore.kernel.org/r/20250912-x96q-v1-0-8471daaf39db@posteo.net

---
J. Neuschäfer (2):
      dt-bindings: arm: sunxi: Add Amediatech X96Q
      arm64: dts: allwinner: h313: Add Amediatech X96Q

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 arch/arm64/boot/dts/allwinner/sun50i-h313-x96q.dts | 230 +++++++++++++++++++++
 3 files changed, 236 insertions(+)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250911-x96q-57e63380804e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

