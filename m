From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v2 0/2] phy: add basic support for NXPs TJA1145 CAN
 transceiver
Date: Fri, 29 Aug 2025 11:19:57 +0200
Message-Id: <20250829-tja1145-support-v2-0-60997f328979@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL1wsWgC/2WNQQ6CMBBFr0JmbQ2tLaIr72FYQGeUMUrJtBIN4
 e5WElcu30v++zNEEqYIx2IGoYkjhyGD2RTg+3a4kmLMDKY0rtybSqVbq7V1Kj7HMUhSWHmP3qL
 Bdgd5NQpd+LUWz03mnmMK8l4PJv21v1b915q0KhV1WNuDRWedP92Zup5Etj48oFmW5QN8iP0Js
 QAAAA==
X-Change-ID: 20250726-tja1145-support-d6ccdc4d2da3
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Marc Kleine-Budde <mkl@pengutronix.de>, linux-can@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756459207; l=1179;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=XKpDXSN+sByAS9cR9W+5ZzKQ3tc8PFlTmx1lTt++ZzA=;
 b=uF/G+Ymv8uMPZbfuVrFQ+2Se6z+fKUghr5aAI/7wQ2Jqvwy8CMPBxyHMXi7V8Ws6++kwLMbOL
 JyyXS6qtkYxBJMIeLmWXXO0RgsJxbDJeb2yhKs4Xvij1jn3UavaWpbM
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic driver support for NXPs TJA1145 CAN transceiver which brings the
PHY up/down by switching to normal/standby mode using SPI commands.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- bindings: Change node name in example to can-phy
- bindings: Fix order of properties, reg property is second
- bindings: Change compatible to match filename
- change compatible to nxp,tja1145-can
- Link to v1: https://lore.kernel.org/r/20250728-tja1145-support-v1-0-ebd8494d545c@liebherr.com

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
base-commit: e373c183bc8a4a421f14ea0dd1edf4f8fd79537f
change-id: 20250726-tja1145-support-d6ccdc4d2da3

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

