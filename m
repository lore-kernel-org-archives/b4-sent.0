From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v2 0/3] gpio: 74HC595 / 74x164 shift register improvements
Date: Tue, 24 Dec 2024 09:02:09 +0100
Message-Id: <20241224-gpio74-v2-0-bbcf14183191@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIFqamcC/2XMSwrDIBSF4a2EO67FF/Yxyj5KBqLX5E40qEhLc
 O+1mXb4Hw7fAQUzYYHndEDGRoVSHCEvE7jNxhUZ+dEgudRCCsXWndJNM2PQKuWt1sbDOO8ZA71
 P6LWM3qjUlD+n28Rv/SOaYJwFKx2/P5wNWsx7KhXTNWKFpff+BUXVbeKdAAAA
X-Change-ID: 20241213-gpio74-66ea33da446d
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735027364; l=1093;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=X2HxQhOFO42ryLga7t3u+bd9WRooGQb2H92J31Mv7xw=;
 b=DIOx5rgvxf6Qyxf8eEYfltlCxDu7Su4IYEfpxMT6fFLDTdQEw+rnTYYJZuytHAamYW+BKNKkc
 tYh22Hu5wy7DNJBE+myBPL0HwuEOATs02IYSvUzt0KgXfKt+IlqWOuY
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a compatible string for another part, and clarifies
the role of the latch clock pin on 74x164-compatible shift registers.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v2:
- Remove patches 2 and 4 (latch GPIO support) in favor of a new patch 3,
  which explains that the latch GPIO acts as a chip select
- Add missing spi_device_id entry in the driver
- Add Linus Walleij's R-b tags
- Link to v1: https://lore.kernel.org/r/20241213-gpio74-v1-0-fa2c089caf41@posteo.net

---
J. Neuschäfer (3):
      dt-bindings: gpio: fairchild,74hc595: Add On Semi MC74HC595A compat
      gpio: 74x164: Add On Semi MC74HC595A compat
      dt-bindings: gpio: fairchild,74hc595: Document chip select vs. latch clock

 .../devicetree/bindings/gpio/fairchild,74hc595.yaml    | 18 ++++++++++++++++++
 drivers/gpio/gpio-74x164.c                             |  2 ++
 2 files changed, 20 insertions(+)
---
base-commit: 4bbf9020becbfd8fc2c3da790855b7042fad455b
change-id: 20241213-gpio74-66ea33da446d

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

