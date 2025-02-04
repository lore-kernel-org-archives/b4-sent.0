From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v3 0/3] net: phy: dp83822: Add support for
 changing the transmit amplitude voltage
Date: Tue, 04 Feb 2025 14:09:14 +0100
Message-Id: <20250204-dp83822-tx-swing-v3-0-9798e96500d9@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHoRomcC/23NzQrDIBAE4FcJnmtZNzE/PfU9Sg+JbhOhNUHFp
 oS8e8VTKTkOw3yzMU/OkGeXYmOOovFmtimUp4KpqbcjcaNTZghYCRQl10tbtog8rNy/jR25HPp
 aCeoGqCVLs8XRw6yZvDFLgVtaA7unZjI+zO6Tv6LIfWIliCM2Cg68IS37TrcAAq5PQ8NEzp3V/
 MpexB8D4cDAZECjuk6rCmts/ox93794UIfCAQEAAA==
X-Change-ID: 20241213-dp83822-tx-swing-5ba6c1e9b065
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738674559; l=1426;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=6gsVmK4T4cIRFpGtGiT/93doyPMbX0pCR2n5z0J7Hx8=;
 b=0kJ29CA2L590d0YONKMhzfT0n2FN1Z2wr1mVYGZ1i2P6OgvaTo54FWZLXiYLbetGJ8HzJdhJo
 wz++O1H95JfDSHCdj56IvMiOrG+C4FX6kUjX+jgZjA4643DOfQ79Zsw
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Add support for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- Switch to tx-amplitude-100base-tx-percent in bindings
- Link to v2: https://lore.kernel.org/r/20250120-dp83822-tx-swing-v2-0-07c99dc42627@liebherr.com

Changes in v2:
- Remove binding ti,tx-amplitude-100base-tx-millivolt from ti,dp83822.yaml
- Add binding tx-amplitude-100base-tx-gain-milli to ethernet-phy.yaml
- Add helper to get tx amplitude gain from DT
- Link to v1: https://lore.kernel.org/r/20250113-dp83822-tx-swing-v1-0-7ed5a9d80010@liebherr.com

---
Dimitri Fedrau (3):
      dt-bindings: net: ethernet-phy: add property tx-amplitude-100base-tx-percent
      net: phy: Add helper for getting tx amplitude gain
      net: phy: dp83822: Add support for changing the transmit amplitude voltage

 .../devicetree/bindings/net/ethernet-phy.yaml      |  7 ++++
 drivers/net/phy/dp83822.c                          | 37 ++++++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 20 +++++++++---
 include/linux/phy.h                                |  3 ++
 4 files changed, 63 insertions(+), 4 deletions(-)
---
base-commit: c2933b2befe25309f4c5cfbea0ca80909735fd76
change-id: 20241213-dp83822-tx-swing-5ba6c1e9b065

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

