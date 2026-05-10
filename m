From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/2] regulator: add support for SGMicro SGM3804
Date: Sun, 10 May 2026 23:45:25 +0700
Message-Id: <20260510-sgm3804-v1-0-e5e8799e0aa0@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU0MD3eL0XGMLAxPdZGPzRIPEVLMU8zRjJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tAJ9MDt9rAAAA
X-Change-ID: 20260510-sgm3804-c37a0ae6d7f3
To: Philippe Simons <simons.philippe@gmail.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778431530; l=1363;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=/WuZUeZCMZrnceyX7+bS1/qqA7M8L6zQXpaUctGOv1U=;
 b=GHTf8dI7l6dDpUncMLK2xLs1wfa08vt/n8RslM9p+yYSOk2hB/5tFRvrxlu9Q8Eer0wm1HF3W
 af0qFx78JSrBpVK/3QrNebK13uYSZctpCgyPJZGb8bfM77Qthz1YDnE
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the SGMicro SGM3804, an I2C-controlled
positive/negative output charge-pump regulator. The chip is used to
generate the AVDD/AVEE rails for display panels and is present on the
Ayaneo Pocket DS handheld, where it powers the panel and is required
before any panel driver can light up the display.

The Ayaneo Pocket DS device tree, posted as a separate series, depends
on the binding introduced here to describe its panel power supply, so
this series is a prerequisite for that work and for any subsequent
panel-related patches targeting the same board.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Alexandre Hamamdjian (2):
      dt-bindings: regulator: add SGMicro SGM3804
      regulator: sgm3804: add SGMicro SGM3804 charge-pump regulator driver

 .../bindings/regulator/sgmicro,sgm3804.yaml        |  60 ++++++++
 MAINTAINERS                                        |   7 +
 drivers/regulator/Kconfig                          |  11 ++
 drivers/regulator/Makefile                         |   1 +
 drivers/regulator/sgm3804-regulator.c              | 164 +++++++++++++++++++++
 5 files changed, 243 insertions(+)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260510-sgm3804-c37a0ae6d7f3

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

