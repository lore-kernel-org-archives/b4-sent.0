From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/2] arm64: Device Tree for Ugoos AM3 board
Date: Sun, 09 Mar 2025 14:16:19 +0100
Message-Id: <20250309-ugoos-am3-v1-0-38cab5a4725b@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKOUzWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIyMj3dL0/Pxi3cRcY900M3MTQ2MLMwMTYxMloPqCotS0zAqwWdGxtbU
 AG099b1sAAAA=
X-Change-ID: 20250222-ugoos-am3-f67413860434
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741526184; l=789;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=sXGqpc3WKcfHqTQx4M6yghIZTgooBtjzDEElH3FLBmo=;
 b=KFqgJkbT9NIujlHGhFm/rVdGXRHTo5NcLMkJr6gLnbrM7M1MDwvekKDXH18GNow11O+DpCkYj
 KQdztzgUsbIC5N0WLj5HCSQuZdReN4kdb5XFmeI1g1pTIBmbYrG4Hfk
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a device tree for Ugoos AM3, an Android TV box from
2018. Most hardware functionality has been tested, as noted in patch 2/2.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (2):
      dt-bindings: arm: amlogic: Add Ogoos AM3
      arm64: dts: amlogic: Add Ogoos AM3

 Documentation/devicetree/bindings/arm/amlogic.yaml |  1 +
 arch/arm64/boot/dts/amlogic/Makefile               |  1 +
 .../arm64/boot/dts/amlogic/meson-gx-p23x-q20x.dtsi |  2 +-
 .../arm64/boot/dts/amlogic/meson-gxm-ugoos-am3.dts | 95 ++++++++++++++++++++++
 4 files changed, 98 insertions(+), 1 deletion(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250222-ugoos-am3-f67413860434

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

