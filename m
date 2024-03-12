From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/4] Baisc devicetree support for Amlogic A4 and A5
Date: Tue, 12 Mar 2024 17:18:56 +0800
Message-Id: <20240312-basic_dt-v1-0-7f11df3a0896@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAe8GUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDY0Mj3aTE4szk+JQSXUPTVBNzUyPTRBNDYyWg8oKi1LTMCrBR0bG1tQD
 9l7CDWgAAAA==
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710235139; l=1498;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=ONSKZevXZXWm3KM1dZDImJLLhqOmgtyms2pTuZbvaa4=;
 b=NtWxuy6gf1pgFYthLf35jwwWmhxqf3Rc0BnrsfAJOvKu/qcXl2lPXRnWSoHgfOP4hVqqZLIwJ
 orWfLOsqpzKC9niMb7l9jtB6dB6XMBEZMH1dA7m6nxhmeTZ78cpXxDF
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A4 and A5 are application processors designed for smart audio
and IoT applications.

Add the new A4 SoC/board device tree bindings.

Add the new A5 SoC/board device tree bindings.

Add basic support for the A4 based Amlogic AV400 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Add basic support for the A5 based Amlogic AV400 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (4):
      dt-bindings: arm: amlogic: add A4 support
      dt-bindings: arm: amlogic: add A5 support
      arm64: dts: add support for A4 based Amlogic BA400
      arm64: dts: add support for A5 based Amlogic AV400

 Documentation/devicetree/bindings/arm/amlogic.yaml | 15 ++++
 arch/arm64/boot/dts/amlogic/Makefile               |  2 +
 .../boot/dts/amlogic/amlogic-a4-a113l2-ba400.dts   | 43 ++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 99 ++++++++++++++++++++++
 .../boot/dts/amlogic/amlogic-a5-a113x2-av400.dts   | 43 ++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 94 ++++++++++++++++++++
 6 files changed, 296 insertions(+)
---
base-commit: 7092cfae086f0bc235baca413d0bd904f182670c
change-id: 20240312-basic_dt-15e47525a413

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

