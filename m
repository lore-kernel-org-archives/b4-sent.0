From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/7] Baisc devicetree support for Amlogic S6 S7 and S7D
Date: Mon, 17 Mar 2025 15:16:51 +0800
Message-Id: <20250317-s6-s7-basic-v1-0-d653384e41f3@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGPM12cC/x3MMQqAMAxA0atIZgNpi1a8ijjUGjVLlQZEKN7d4
 viG/wsoZ2GFsSmQ+RaVM1WYtoF4hLQzyloNlmxH1hrUHtXjElQibo4oOhq85x5qcWXe5Plv0/y
 +Hxwrow1dAAAA
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
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742195812; l=2174;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=wL9gUnrlsPQNAWa/Td3yrEb1Mzg5Mf+QmQXD9OzX72w=;
 b=DudI+EZbNWKj/cExJWHpLtrhBZq5G0gH1aBEaWY7T5W6Q5fTXxZpYlb0lsmNgLYJ4ScXYKMYM
 63/vxuVARWeAv3IcZip6ckG3PmaVmkDFz9zOOBC3vVCunosibV9eRy9
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic S6 S7 and S7D are application processors designed for
hybrid OTT/IP Set Top Box and high-end media box applications.

Add the new S6 SoC/board device tree bindings.
Add the new S7 SoC/board device tree bindings.
Add the new S7D SoC/board device tree bindings.

Add basic support for the S6 based Amlogic BL209 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Add basic support for the S7 based Amlogic BP201 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Add basic support for the S7D based Amlogic BM202 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (7):
      dt-bindings: arm: amlogic: add S6 support
      dt-bindings: arm: amlogic: add S7 support
      dt-bindings: arm: amlogic: add S7D support
      dt-bindings: serial: amlogic,meson-uart: Add compatible string for S6/S7/S7D
      arm64: dts: add support for S6 based Amlogic BL209
      arm64: dts: add support for S7 based Amlogic BP201
      arm64: dts: add support for S7D based Amlogic BM202

 Documentation/devicetree/bindings/arm/amlogic.yaml | 18 ++++
 .../bindings/serial/amlogic,meson-uart.yaml        |  3 +
 arch/arm64/boot/dts/amlogic/Makefile               |  3 +
 .../boot/dts/amlogic/amlogic-s6-s905x5-bl209.dts   | 42 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        | 97 +++++++++++++++++++++
 .../boot/dts/amlogic/amlogic-s7-s805x3-bp201.dts   | 41 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        | 99 ++++++++++++++++++++++
 .../boot/dts/amlogic/amlogic-s7d-s905x5m-bm202.dts | 41 +++++++++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       | 99 ++++++++++++++++++++++
 9 files changed, 443 insertions(+)
---
base-commit: 73e4ffb27bb8a093d557bb2dac1a271474cca99c
change-id: 20250221-s6-s7-basic-f300c30877e6

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

