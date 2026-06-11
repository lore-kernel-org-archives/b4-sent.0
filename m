From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH RFC 0/2] pinctrl: Add support gpiod_to_irq
Date: Thu, 11 Jun 2026 07:54:32 +0000
Message-Id: <20260611-gpio-to-irq-v1-0-12201716f23f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALhpKmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDUyMD3fSCzHzdknzdzKJC3aRUE3NL8xSjRCPjNCWgjoKi1LTMCrBp0Up
 Bbs5KsbW1AGyHvH9iAAAA
X-Change-ID: 20260520-gpio-to-irq-be4797d2a23f
To: Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781164479; l=854;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=1uthSd7P8y9Oi8VLveA0Sb1tQ9DUs9/arzzCInD1jhE=;
 b=O2aJsO0189X2Plisl9JKDVw2g1wop4vl4VFW7vG/5bm5/wT28vxWm+u1n5eBG3/Auq/FeOjBW
 +w8IlUp0RAuCLvt5u4/zoQm689DXFrd+NhcCLNEm11fxJAq2bfhM/yg
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some users need to obtain an IRQ directly from a GPIO descriptor through gpiod_to_irq().
Add the required DT binding and implementation to support this use case.
Since this introduces a new DT property, the property is kept optional to
maintain compatibility with existing SoCs and DTS files.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add gpio irq property
      pinctrl: meson: amlogic-a4: support gpiod_to_irq

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  5 ++
 drivers/pinctrl/meson/pinctrl-amlogic-a4.c         | 54 ++++++++++++++++++++++
 2 files changed, 59 insertions(+)
---
base-commit: 4ca496f6285e16d91751e5c84c6010e03285528c
change-id: 20260520-gpio-to-irq-be4797d2a23f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

