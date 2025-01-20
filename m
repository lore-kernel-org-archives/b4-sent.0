From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v2 0/3] net: phy: dp83822: Add support for
 changing the transmit amplitude voltage
Date: Mon, 20 Jan 2025 14:50:20 +0100
Message-Id: <20250120-dp83822-tx-swing-v2-0-07c99dc42627@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJxUjmcC/22NQQ6CMBBFr0Jm7ZhpsQiuvIdhAXSESbQlbYMYw
 t1tWLt8efnvbxA5CEe4FRsEXiSKdxn0qYBh6tzIKDYzaNIXpVWJdq7LWmtMK8aPuBFN31WD4qa
 nykCezYGfsh7JBzhO6HhN0GYzSUw+fI+vRR0+Zw2pf9lFIeGVrekaWxMpur+E+4lDOA/+De2+7
 z/oBY0wvQAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737381028; l=1257;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=tgzpuPTlk55PqGR4hzKBitiv5FYSx8q9JuFUVygLiZU=;
 b=dPLIo5u0zT2/jV5kb4jkzAGVdakwVyp3mtlz9U3opi/THSQPsrot3icWRVzpytUmDEe1NtLo4
 DlVAJf7A1wdA66zxl4S/GHwUc03AMqxHPwOrh1r0oZ/E0d/YVdb9K2o
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Add support for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Remove binding ti,tx-amplitude-100base-tx-millivolt from ti,dp83822.yaml
- Add binding tx-amplitude-100base-tx-gain-milli to ethernet-phy.yaml
- Add helper to get tx amplitude gain from DT
- Link to v1: https://lore.kernel.org/r/20250113-dp83822-tx-swing-v1-0-7ed5a9d80010@liebherr.com

---
Dimitri Fedrau (3):
      dt-bindings: net: ethernet-phy: add property tx-amplitude-100base-tx-gain-milli
      net: phy: Add helper for getting tx amplitude gain
      net: phy: dp83822: Add support for changing the transmit amplitude voltage

 .../devicetree/bindings/net/ethernet-phy.yaml      |  8 +++++
 drivers/net/phy/dp83822.c                          | 37 ++++++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 20 +++++++++---
 include/linux/phy.h                                |  3 ++
 4 files changed, 64 insertions(+), 4 deletions(-)
---
base-commit: 64ff63aeefb03139ae27454bd4208244579ae88e
change-id: 20241213-dp83822-tx-swing-5ba6c1e9b065

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

