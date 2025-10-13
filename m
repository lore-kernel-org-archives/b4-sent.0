From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH v3 0/2] phy: add basic support for NXPs TJA1145 CAN
 transceiver
Date: Mon, 13 Oct 2025 11:19:17 +0200
Message-Id: <20251013-tja1145-support-v3-0-4a9d245fe067@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABXE7GgC/2XN0Q6CIBTG8VdpXEeDIyh01Xu0LhSOSStxYKzmf
 PfQrbXl5f/bzu9MJGJwGMlxN5GAyUXn+xzFfkdMV/dXpM7mJsBAsgpKOt5qzoWk8TkMPozUlsZ
 YIyzYuiD5agjYutcqni+5OxdHH97rg8SX9WupjZU4ZRQbq4QWVgppTneHTYchHIx/kIVL8CMU6
 C0BmSiZ1lVbgNKV/iPmef4ABCgwJvQAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760347168; l=1548;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=DD7IBJHeQ8o/jhi5QgFhDQOe2dxMtOoT5L78yQPxeMk=;
 b=ZRnpk9YG8ASHR8WG5ZA1i3FsQK8yIJ+Z0JZ6GRA9tzyJsw0vYU+L4prkFIu5L82Ix4T8JroDF
 CS7U3JPWslFAMp38rAdVv6bKFM9b4lHy3sYfGpBc14fVXGf18D9xNOh
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic driver support for NXPs TJA1145 CAN transceiver which brings the
PHY up/down by switching to normal/standby mode using SPI commands.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- bindings: fix SPI bus unit address format error
- bindings: added resolution of discussion into commit msg
- Checked binding with:
  make dt_binding_check DT_SCHEMA_FILES=nxp,tja1145-can.yaml
  Missed it for V2, didn't do it intentionally. Sorry.
- Link to v2: https://lore.kernel.org/r/20250829-tja1145-support-v2-0-60997f328979@liebherr.com

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
base-commit: 920852baf6bdffb2818c0de8ff3437d8f6570dc2
change-id: 20250726-tja1145-support-d6ccdc4d2da3

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

