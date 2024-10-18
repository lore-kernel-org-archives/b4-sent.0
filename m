From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/3] Pinctrl: A4: Add pinctrl driver
Date: Fri, 18 Oct 2024 16:10:49 +0800
Message-Id: <20241018-a4_pinctrl-v3-0-e76fd1cf01d7@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAkYEmcC/03M0QqCMBTG8VeRc91iO85WXvUeIbHmSQ+ok01GI
 b57Swi6/H/w/VaIFJgi1MUKgRJH9lOO8lCA6+3UkeA2N6BEraRCYfV95sktYRDy0qoHWmVIG8i
 HOdCTXzt2a3L3HBcf3rud8Lv+GP3PJBRSlGS0PVUOzxVd7Tj4jt3R+RGabds+UeMFT6YAAAA=
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729239051; l=1206;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=qam845+M054/HCuxE2Dub4pqx0T6LNs2036Ba2LFmY8=;
 b=iq5sxMdSUIEb/ykt5CpcF6wTUW7k5vVqa1/aARrx4VQWbC7RVa4rVQEkZ2/RvI+s4XmHmW66h
 ZH7b6a8vJc+C4s/evg5ba7t8c9UZRdHkZw1MOWQX+Fz8dW58kTSduDI
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl driver support for Amloigc A4 SoC

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v3:
- Remove head file from binding.
- Move GPIO define to file *.c.
- Link to v2: https://lore.kernel.org/r/20241014-a4_pinctrl-v2-0-3e74a65c285e@amlogic.com

Changes in v2:
- Use one marco instead of all pin define.
- Add unit name for dts node.
- Link to v1: https://lore.kernel.org/all/20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com/

---
Xianwei Zhao (3):
      dt-bindings: pinctrl: Add support for Amlogic A4 SoCs
      pinctrl: meson: Add driver support for Amlogic A4 SoCs
      arm64: dts: amlogic: a4: add pinctrl node

 .../bindings/pinctrl/amlogic,meson-pinctrl-a1.yaml |    2 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |   35 +
 drivers/pinctrl/meson/Kconfig                      |    6 +
 drivers/pinctrl/meson/Makefile                     |    1 +
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 1253 ++++++++++++++++++++
 5 files changed, 1297 insertions(+)
---
base-commit: 58e2d28ed28e5bc8836f8c14df1f94c27c1f9e2f
change-id: 20241012-a4_pinctrl-09d1b2a17e47

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

