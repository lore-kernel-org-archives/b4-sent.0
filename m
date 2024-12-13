From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 0/4] gpio: 74HC595 / 74x164 shift register improvements
Date: Fri, 13 Dec 2024 18:32:46 +0100
Message-Id: <20241213-gpio74-v1-0-fa2c089caf41@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL5vXGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDI0Nj3fSCzHxzE10zs9REY+OURBMTsxQloOKCotS0zAqwQdGxtbUA7th
 OyVgAAAA=
X-Change-ID: 20241213-gpio74-66ea33da446d
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Maxime Ripard <mripard@kernel.org>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734111175; l=830;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=lJEKgDelnzJ/bRVH+G+3ZU4n1kpliDSjZnLzDu3+33A=;
 b=nCylNQ9tjXA6uUAwnCBq5dw+48WODp8/N7kS8h/0jbZgk5k5HJTueBtpi5Od4mgQCuuApSund
 CIZ4mxGAhW5BsZv0355VczPRgi/Saf3+MfRulcTSzWL9kST1Gp3ZOUK
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a compatible string for another part, and adds the
ability to specify and use the latch clock pin on 74x164-compatible
shift registers.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (4):
      dt-bindings: gpio: fairchild,74hc595: Add On Semi MC74HC595A compat
      dt-bindings: gpio: fairchild,74hc595: Add latch-gpios property
      gpio: 74x164: Add On Semi MC74HC595A compat
      gpio: 74x164: Add latch GPIO support

 .../bindings/gpio/fairchild,74hc595.yaml           |  5 +++++
 drivers/gpio/gpio-74x164.c                         | 22 +++++++++++++++++++++-
 2 files changed, 26 insertions(+), 1 deletion(-)
---
base-commit: fac04efc5c793dccbd07e2d59af9f90b7fc0dca4
change-id: 20241213-gpio74-66ea33da446d

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

