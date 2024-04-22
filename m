From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v2 0/3] Add support for Amlogic T7 reset controller
Date: Mon, 22 Apr 2024 19:11:42 +0800
Message-Id: <20240422-t7-reset-v2-0-cb82271d3296@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO5FJmYC/23MQQ7CIBCF4as0sxZDASl15T1MF0iHdhJbDDRE0
 3B3sWuX/8vLt0PCSJjg2uwQMVOisNYQpwbcbNcJGY21QXChuBQ92zoWMeHGvOnQSKW9HR9Q76+
 Int4HdR9qz5S2ED+HnNvf+gfJLeNMOY0CtZGXHm92eYaJ3NmFBYZSyhdgXGSeogAAAA==
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713784331; l=1114;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=60Nj6Eui0n3N0tnpm8vqfyc7ou3dQzK95LfY94ljJ2Q=;
 b=/gYjYSk1vpwpkjfjMUbBti+TUQEAmVkAzsRF+ybxSZczfGfjPre9hMD1+0lbyMdq48VlAUv76
 e1nzmYjH+6PBDZqJxUF9CDf4k45OZe3hoGe/2cujuahY92nBy7spKPX
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new compatible and device node for Amlogic T7 reset controller.
And modify the driver accordingly.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Changes in v2:
- Drop the compatible comment in dt-binding.
- Move t7-reset.h to arch/arm64/boot/dts/amlogic.
- Link to v1: https://lore.kernel.org/r/20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com

---
Zelong Dong (3):
      dt-bindings: reset: Add Amlogic T7 reset controller
      reset: reset-meson: Add support for Amlogic T7 SoC reset controller
      arm64: dts: amlogic: Add Amlogic T7 reset controller

 .../bindings/reset/amlogic,meson-reset.yaml        |   1 +
 arch/arm64/boot/dts/amlogic/amlogic-t7-reset.h     | 197 +++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |   7 +
 drivers/reset/reset-meson.c                        |   6 +
 4 files changed, 211 insertions(+)
---
base-commit: f529a6d274b3b8c75899e949649d231298f30a32
change-id: 20240329-t7-reset-f87e8346fadb

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

