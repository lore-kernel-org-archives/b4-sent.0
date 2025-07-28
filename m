From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] phy: add basic support for NXPs TJA1145 CAN
 transceiver
Date: Mon, 28 Jul 2025 17:39:28 +0200
Message-Id: <20250728-tja1145-support-v1-0-ebd8494d545c@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALCZh2gC/x3MTQqAIBBA4avErBPU/qCrRAtxppoWKmoRhHdPW
 n6L915IFJkSzM0LkW5O7F2Fahuwh3E7CcZq0FIPctKjyKdRqh9EukLwMQscrUXbo0bTQa1CpI2
 f/7ispXz1AfMuYQAAAA==
X-Change-ID: 20250726-tja1145-support-d6ccdc4d2da3
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753717177; l=857;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=fJ8DxG6HN180rt/dWpJklk55wcUF3JkaqyPkKVekboM=;
 b=lUufaxZwR/txAdEzEBxXstUfbsDo1v0MhaMCRNENmFqiHgP4C4kqWYcjIFxM6//LzhIrfYy1a
 dbSDpBq/+0jAhwiJo/rbku+lz+BlwLiZQ5bm+vEvXssgvAZOw+6tPL9
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic driver support for NXPs TJA1145 CAN transceiver which brings the
PHY up/down by switching to normal/standby mode using SPI commands.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      dt-bindings: phy: add support for NXPs TJA1145 CAN transceiver
      phy: add basic support for NXPs TJA1145 CAN transceiver

 .../devicetree/bindings/phy/nxp,tja1145-can.yaml   |  79 +++++++++
 drivers/phy/Kconfig                                |  10 ++
 drivers/phy/Makefile                               |   1 +
 drivers/phy/phy-nxp-tja1145.c                      | 185 +++++++++++++++++++++
 4 files changed, 275 insertions(+)
---
base-commit: 4a3556b81b99f0c8c0358f7cc6801a62b4538fe2
change-id: 20250726-tja1145-support-d6ccdc4d2da3

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

