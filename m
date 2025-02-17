From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Subject: [PATCH 0/2] Add support for the PCF8574T I/O expander.
Date: Mon, 17 Feb 2025 14:07:50 +0100
Message-Id: <20250217-gpio-pcf8574t-v1-0-137e140df5fc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKY0s2cC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDI0Nz3fSCzHzdguQ0C1NzkxJdU0vzJEtDSzMzY8tEJaCegqLUtMwKsHn
 RsbW1ADoLLbFfAAAA
To: Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Laurent Pinchart <laurent.pinchart+renesas@ideasonboard.com>
Cc: linux-gpio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739797690; l=688;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=50LXAdQ5iCgOH6wLijxYspU9uZxYNQjnh5u8g8wSwJI=;
 b=GNuwei57M4SHpZgsMdxN2IXvdgxcY6iaK+hI0/kedLn39n/2hueWxNDkFXyWwWyrnnapYX93K
 HqHANwueWJjDuVZE5Wo86nA7FxxTWSxyKS6ilvcibW3pj9BtMSYrTBB
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series adds the driver support and the documentation for the
PCF8574T I2C I/O expander.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
Tóth János (2):
      drivers: gpio: Add support for PCF8574T.
      dt-bindings: gpio: Add support for PCF8574T.

 Documentation/devicetree/bindings/gpio/nxp,pcf8575.yaml | 1 +
 drivers/gpio/Kconfig                                    | 2 +-
 drivers/gpio/gpio-pcf857x.c                             | 2 ++
 3 files changed, 4 insertions(+), 1 deletion(-)
---
base-commit: 0ad2507d5d93f39619fc42372c347d6006b64319
change-id: 20250217-gpio-pcf8574t-597b9196639a

Best regards,
-- 
Tóth János <gomba007@gmail.com>

