From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/5] Baisc devicetree support for Amlogic A4 and A5
Date: Mon, 01 Apr 2024 18:10:48 +0800
Message-Id: <20240401-basic_dt-v3-0-cb29ae1c16da@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACmICmYC/22MywqDMBBFf0Wybkpm4quu+h+llBgTHaimJBJax
 H9vdGWhy3O55ywsGE8msCZbmDeRArkpgTxlTA9q6g2nLjFDgbmQgLxVgfSjmzkUJq8KLFQOkqX
 7yxtL7z11uyceKMzOf/ZyhG39E4nABa8sQGelEvWlvKrx6XrSZ+1GtmUiHlQUBxWTWtZgtG1Rt
 sr+quu6fgHmGofN3QAAAA==
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-serial@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711966252; l=2281;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=N5wbw2MnTKS/5RK9ZX2lKvMkhhY+eswYx65v4Ex7yME=;
 b=HJ4Y6rVs3Ko4rtxCb2S3YncOGcj95WtddZ5a28tWO5DhOf4QZsNzBblo93y0AcDmkm0MIG44a
 oizL5JSYrk5ClFUJCFY8afUZbCqUms1epCd5QivqZcogc7AIatuK3iC
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Amlogic A4 and A5 are application processors designed for smart audio
and IoT applications.

Add the new A4 SoC/board device tree bindings.

Add the new A5 SoC/board device tree bindings.

Add A4 UART compatible line for documentation.

Add basic support for the A4 based Amlogic AV400 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Add basic support for the A5 based Amlogic AV400 board, which describes
the following components: CPU, GIC, IRQ, Timer and UART. These are capable of
booting up into the serial console.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Keep alphabetical order.
- Add the necessary spaces.
- Link to v2: https://lore.kernel.org/r/20240320-basic_dt-v2-0-681ecfb23baf@amlogic.com

Changes in v2:
- Delete bindings for uncommitted boards.
- Add A4 UART compatible line for documentation.
- Use common dtsi for a4 and a5.
- Fix psci version 1.0, and fix some formats.
- Modify secmon reserved memory size 10M(actual using).
- Link to v1: https://lore.kernel.org/r/20240312-basic_dt-v1-0-7f11df3a0896@amlogic.com

---
Xianwei Zhao (5):
      dt-bindings: arm: amlogic: add A4 support
      dt-bindings: arm: amlogic: add A5 support
      dt-bindings: serial: amlogic,meson-uart: Add compatible string for A4
      arm64: dts: add support for A4 based Amlogic BA400
      arm64: dts: add support for A5 based Amlogic AV400

 Documentation/devicetree/bindings/arm/amlogic.yaml | 12 ++++
 .../bindings/serial/amlogic,meson-uart.yaml        |  4 +-
 arch/arm64/boot/dts/amlogic/Makefile               |  2 +
 .../boot/dts/amlogic/amlogic-a4-a113l2-ba400.dts   | 42 ++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi | 66 ++++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 40 +++++++++++++
 .../boot/dts/amlogic/amlogic-a5-a113x2-av400.dts   | 42 ++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 40 +++++++++++++
 8 files changed, 247 insertions(+), 1 deletion(-)
---
base-commit: 7092cfae086f0bc235baca413d0bd904f182670c
change-id: 20240312-basic_dt-15e47525a413

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

