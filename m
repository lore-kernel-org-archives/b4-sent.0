From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/4] Board support for Fernsehfee 3.0
Date: Mon, 28 Apr 2025 12:44:27 +0200
Message-Id: <20250428-fernsehfee-v2-0-293b98a43a91@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAtcD2gC/03MTQ7CIBiE4as031oMP2KjK+9husB2EDbQACGah
 ruLjQuX7yTzbJSRPDJdh40Sqs8+hh7yMNDsTHiC+aU3SS41V0IzixQynAXYQxvYi+KzGUH9sCZ
 Y/9qx+9Tb+Vxieu92Fd/1x0j1z1TBOJNnKdRJzIsazW2NuSAeAwpNrbUPE2O1saUAAAA=
X-Change-ID: 20250315-fernsehfee-b5aef930ca7e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745837069; l=1421;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=zoNoOQu9Fld7LEIioJ+wlApw7JJtAWg9ZZxxQWQdkQ0=;
 b=sloiws7PjerztavFOh+WRSwUGtcJ8z57ukYOGobwKBpWoMWMkPQdnhNLJFGvr24RatYRu5di8
 GLTh5fOlEknAphpjgeeMJ/wjmSSrkPR/7ufDGiz/ou72uuoN0GwH3MD
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fernsehfee[1] ("TV fairy") is a family of set-top boxes marketed as
ad-blocking appliances. This patchset adds board support in the form of
a device tree for the third generation, Fernsehfee 3.0.

[1]: https://fernsehfee.de/ (German), https://www.telefairy.com/ (English)

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Apply ACKs from Krzysztof Kozlowski and R-b from Neil Armstrong and Martin Blumenstingl
- New patch 4/4 to describe PMIC regulators, after discussion with Martin Blumenstingl
- Link to v1: https://lore.kernel.org/r/20250323-fernsehfee-v1-0-2621341cd37a@posteo.net

---
J. Neuschäfer (4):
      dt-bindings: vendor-prefixes: Add TC Unterhaltungselektronik AG
      dt-bindings: arm: amlogic: Add TCU Fernsehfee 3.0 board
      ARM: dts: amlogic: Add TCU Fernsehfee 3.0
      ARM: dts: amlogic: meson8-fernsehfee3: Describe regulators

 Documentation/devicetree/bindings/arm/amlogic.yaml |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm/boot/dts/amlogic/Makefile                 |   1 +
 arch/arm/boot/dts/amlogic/meson8-fernsehfee3.dts   | 306 +++++++++++++++++++++
 arch/arm/boot/dts/amlogic/meson8.dtsi              |  18 ++
 5 files changed, 328 insertions(+)
---
base-commit: 9c8bd75378d70cd6087d503eb8317d1eea67164a
change-id: 20250315-fernsehfee-b5aef930ca7e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

