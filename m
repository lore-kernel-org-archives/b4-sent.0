From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] baisc devicetree support for Amlogic A9
Date: Thu, 05 Feb 2026 06:04:01 +0000
Message-Id: <20260205-a9-baisc-dts-v1-0-1212b46f95a7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANEyhGkC/x3MMQqAMAxA0atIZgNpQVGvIg5tTTVLlUZEKN7d4
 viG/wsoZ2GFqSmQ+RaVI1WYtoGwu7QxyloNlmxPljp0I3onGnC9FIP3ni2TiQNBTc7MUZ5/Ny/
 v+wGIh2F0XgAAAA==
X-Change-ID: 20260205-a9-baisc-dts-cbbbe2e01f80
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770271444; l=870;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=ps7j2+Z67QCIPw991CX7xaz/DhDRBR1m3knxUYmHUEk=;
 b=a/G09XieespzzJlySSaPDZ0TgKEJThWA1puCkS6knfHGGWUWbLvYbDZKpVmF0Xd1NCxulbqAx
 R4kjdoSHiYDDIqCUmlxkhluqDOhCAktxMfVEDPOTxXOnDV/GDsFK54a
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the new A9 SoC/board device tree and related bindings.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: arm: amlogic: add A311Y3 support
      dt-bindings: serial: amlogic,meson-uart: Add compatible string for A9
      arm64: dts: add support for A9 based Amlogic BY401

 Documentation/devicetree/bindings/arm/amlogic.yaml |   6 +
 .../bindings/serial/amlogic,meson-uart.yaml        |   1 +
 arch/arm64/boot/dts/amlogic/Makefile               |   1 +
 .../boot/dts/amlogic/amlogic-a9-a311y3-by401.dts   |  41 +++++++
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        | 127 +++++++++++++++++++++
 5 files changed, 176 insertions(+)
---
base-commit: e3194dfb772304a1b7ca3bcfccacefec3468b7bf
change-id: 20260205-a9-baisc-dts-cbbbe2e01f80

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

