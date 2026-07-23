From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/4] spi: add support for Amlogic A9
Date: Thu, 23 Jul 2026 06:43:41 +0000
Message-Id: <20260723-a9-spisg-v2-0-9fc39106b7e2@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB24YWoC/0XMQQrCMBCF4auUWRtJojXElfeQLmKcpAO2KRkJS
 sndjQVx+T8e3wqMmZDh3K2QsRBTmlvoXQd+dHNEQffWoKU+SaN64azghTiKoKxHeZQH10to9yV
 joNdGXYfWI/Ez5fcmF/Vdf4j5I0UJKTQiOmNuqGy4uOmRIvm9TxMMtdYPMCEY6qIAAAA=
X-Change-ID: 20260715-a9-spisg-f19ce0403a50
To: Sunny Luo <sunny.luo@amlogic.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-spi@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784789030; l=1229;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=DGj8+OBGUddq6591+eaVQwRebOdg449UgOkQcJ5AB2g=;
 b=sb8FB2uWLZMo8CYLxZi5hPTuZCrISN1HZmzteGPAmYDm8drwF8LzXqRtDclIL7L1HQhOUqU0y
 iUJt2D/nfiLB8NTYUzpQ2/y+SVU9xkm6SpoQZf8TKhpg/eqCdRlI8KQ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for A9 with some features, and driver for A9 base on A4.

Fix the incorrect keep_ss of the last descriptor.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Move the added properties defined to top-level and then reestrict them  in bindings.
- Fix some pre-exiting bug reported by Sashiko AI review that as a separate submission.
- Limit the value that will be writed to CFG_CS_HOLD.
- Link to v1: https://lore.kernel.org/r/20260717-a9-spisg-v1-0-2eeea77be19f@amlogic.com

---
Sunny Luo (1):
      spi: amlogic: spisg: Fix the incorrect keep_ss of the last descriptor

Xianwei Zhao (3):
      spi: dt-bindings: amlogic: spisg: Document A9-specific properties
      spi: amlogic: spisg: Fix transfer size limit and timeout handling
      spi: amlogic: spisg: Add support for A9 controller features

 .../devicetree/bindings/spi/amlogic,a4-spisg.yaml  | 38 ++++++++-
 drivers/spi/spi-amlogic-spisg.c                    | 90 +++++++++++++++++++---
 2 files changed, 113 insertions(+), 15 deletions(-)
---
base-commit: d0b5dd16226814e5c73ba8daf88d3d91c990a38f
change-id: 20260715-a9-spisg-f19ce0403a50

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

