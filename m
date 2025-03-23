From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/3] Board support for Fernsehfee 3.0
Date: Sun, 23 Mar 2025 13:37:49 +0100
Message-Id: <20250323-fernsehfee-v1-0-2621341cd37a@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJ0A4GcC/x3MQQqAIBRF0a3IHydoIlFbiQZmz/wTC4UIxL0nD
 c/g3koFmVFoEZUyHi58pQ49CPLRpROSj24a1WiV0VYG5FQQAyB36xBmo7ybQD24MwK//2zdWvs
 Ay4jP+1wAAAA=
X-Change-ID: 20250315-fernsehfee-b5aef930ca7e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742733500; l=1063;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=jd9wYHpyu6ZnNxDkrFxMFeP4lePw1I2neHhddWVkDjo=;
 b=AMu+SEgV81icPPkhvIuoyn3r3e/kUZ9XHrbb3+w4UrKlZvVcnjOaV72cWbnRxz1Tq+ff46kXf
 HnZqH8mi1+GCDMiKMW7SNQtuKWKX4QVY/VSCHW+Icx2oN8iNGjFWRtI
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
J. Neuschäfer (3):
      dt-bindings: vendor-prefixes: Add TC Unterhaltungselektronik AG
      dt-bindings: arm: amlogic: Add TCU Fernsehfee 3.0 board
      ARM: dts: amlogic: Add TCU Fernsehfee 3.0

 Documentation/devicetree/bindings/arm/amlogic.yaml |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm/boot/dts/amlogic/Makefile                 |   1 +
 arch/arm/boot/dts/amlogic/meson8-fernsehfee3.dts   | 219 +++++++++++++++++++++
 arch/arm/boot/dts/amlogic/meson8.dtsi              |  18 ++
 5 files changed, 241 insertions(+)
---
base-commit: 4701f33a10702d5fc577c32434eb62adde0a1ae1
change-id: 20250315-fernsehfee-b5aef930ca7e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

