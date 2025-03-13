From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/2] arm64: Device Tree for Ugoos AM3 board
Date: Fri, 14 Mar 2025 00:10:58 +0100
Message-Id: <20250314-ugoos-am3-v2-0-422104b0cec5@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAJm02cC/03MQQ6DIBCF4auYWZcGBlDrqvdoXKAdlUXBADVtD
 HcvtZsu/5eXb4dIwVKErtoh0Gaj9a4EnioYF+NmYvZeGpCj5ojInrP3kZmHZFPdKCHbmiupoPz
 XQJN9HdatL73YmHx4H/QmvutPkfzyp2yCcSbb0QzaqAb1cF19TOTPjhL0OecPNrVgyKMAAAA=
X-Change-ID: 20250222-ugoos-am3-f67413860434
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741907460; l=1015;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=cXVyoRypaze7f+Lz1yx3qPNU5d4wDrkDtX8Re+XtxgY=;
 b=EMJcVnU8xlRkgiTfuaF1TgDC/Cipw+ftS76kCrZ0lMvFf5GpTyGf5oOolGy6r7AhJM4pXhZCI
 yQvY8GnkHuzBGf7CLT58q9JRTOPS6BKhzJVs76y6QepwJkvBXX3UV/L
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a device tree for Ugoos AM3, an Android TV box from
2018. Most hardware functionality has been tested, as noted in patch 2/2.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- fix vendor name in patch subjects
- fix mistake that made wifi not work
- apply Krzysztof's ACK to patch 1/2
- Link to v1: https://lore.kernel.org/r/20250309-ugoos-am3-v1-0-38cab5a4725b@posteo.net

---
J. Neuschäfer (2):
      dt-bindings: arm: amlogic: Add Ugoos AM3
      arm64: dts: amlogic: Add Ugoos AM3

 Documentation/devicetree/bindings/arm/amlogic.yaml |  1 +
 arch/arm64/boot/dts/amlogic/Makefile               |  1 +
 .../arm64/boot/dts/amlogic/meson-gx-p23x-q20x.dtsi |  2 +-
 .../arm64/boot/dts/amlogic/meson-gxm-ugoos-am3.dts | 91 ++++++++++++++++++++++
 4 files changed, 94 insertions(+), 1 deletion(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250222-ugoos-am3-f67413860434

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

