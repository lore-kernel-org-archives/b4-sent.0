From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] Initial Amediatech X96Q support based on Allwinner
 H313
Date: Fri, 12 Sep 2025 01:52:08 +0200
Message-Id: <20250912-x96q-v1-0-8471daaf39db@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKhgw2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDS0ND3QpLs0JdU/NUM2NjCwMLA5NUJaDSgqLUtMwKsDHRsbW1ABhukK1
 WAAAA
X-Change-ID: 20250911-x96q-57e63380804e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757634731; l=937;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=rXQlLipzuO460hLM6yk6F8xNPGedj1EQygxLedmpBzk=;
 b=M0EgaUBY/bR66z8j4+11q/JqRm4pXPtp1UZ7NvBJPd6gL5yfBzHzCDkiWsBp+AaLirOtDR1Dr
 DGry5a6MTTIATIpQgaOccON/kpyi2do+5HKGBE9ZynXJ1z/i4K7Kkk6
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds an initial devicetree for the X96Q set-top box.
WiFi, Ethernet, and HDMI depend on drivers that are currently not
available in mainline Linux, and I didn't enable them in the devicetree.
The builtin infrared receiver produces IRQs when a nearby remote sends
events, but I have not checked whether the events are decoded correctly.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      dt-bindings: arm: sunxi: Add Amediatech X96Q
      arm64: dts: allwinner: h313: Add Amediatech X96Q

 Documentation/devicetree/bindings/arm/sunxi.yaml   |   5 +
 arch/arm64/boot/dts/allwinner/Makefile             |   1 +
 arch/arm64/boot/dts/allwinner/sun50i-h313-x96q.dts | 235 +++++++++++++++++++++
 3 files changed, 241 insertions(+)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250911-x96q-57e63380804e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

