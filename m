From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] spi: add support for Amlogic A9
Date: Fri, 17 Jul 2026 07:49:32 +0000
Message-Id: <20260717-a9-spisg-v1-0-2eeea77be19f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIzeWWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0NT3URL3eKCzOJ03TRDy+RUAxMD40RTAyWg8oKi1LTMCrBR0bG1tQA
 yW0scWgAAAA==
X-Change-ID: 20260715-a9-spisg-f19ce0403a50
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784274574; l=813;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=hl4y02I9tA4u+DQHQqqO/xk7mXY4kQUgmqTa/x0JXaE=;
 b=ya0yNDSjGaGqYZuUAwyX5QW7AKAbiK0wPvRNHxKiKnT5Tfk7qIdIVPww5XU87USkzsRsxrvkx
 HEhWy/wo1iQAgAXRoUww+8OAHhTjukbMZm+eJ9Ia0HW6R74Ze6bU6uO
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for A9 with some features, and driver for A9 base on A4.

Fix the incorrect keep_ss of the last descriptor.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Sunny Luo (1):
      spi: amlogic: spisg: Fix the incorrect keep_ss of the last descriptor

Xianwei Zhao (2):
      spi: dt-bindings: amlogic: spisg: Document A9-specific properties
      spi: amlogic: spisg: Add support for A9 controller features

 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  | 36 ++++++++--
 drivers/spi/spi-amlogic-spisg.c                    | 78 ++++++++++++++++++++--
 2 files changed, 103 insertions(+), 11 deletions(-)
---
base-commit: d0b5dd16226814e5c73ba8daf88d3d91c990a38f
change-id: 20260715-a9-spisg-f19ce0403a50

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

