From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v4 0/3] net: phy: dp83822: Add support for
 changing the transmit amplitude voltage
Date: Tue, 11 Feb 2025 09:33:46 +0100
Message-Id: <20250211-dp83822-tx-swing-v4-0-1e8ebd71ad54@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGoLq2cC/23NQQ6CMBQE0KuYrq35/aVAXXkP4wLaLzTRQlqCG
 MLdbbrRGJaTybxZWaTgKLLzYWWBZhfd4FMojgdm+sZ3xJ1NmSFgIVBIbsda1oh8Wnh8Od9x1Ta
 lEaRbKBVLszHQ3S2ZvDJPE/e0TOyWmt7FaQjv/DWL3CdWgdhjZ8GBV2RVo20NIODycNT2FMLJD
 M/szfhjIOwYmAyojNbWFFhitWPIr4FQ7BgyGbrSNelSAVj9Z2zb9gH4b5SzRQEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739262831; l=1880;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=NX6m3Adayc0vNqxUwfaOwMkKFBcSZx8C8KPimyfNAR8=;
 b=YhgSfLb+zmjwX3GngGcIPF4m91Jxb0cBPhjrgeoaKlLWSN6oMMnbo/y0v7T3CE8Z2dHVNdrmk
 u2jJx+DyLU3BsN9ZKWoayIgUABWGJUo2070thrqmcYcaYiNdMpAMEAg
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Add support for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v4:
- Remove type $ref from binding
- Remove '|' from description in binding
- Change helper function from:
    static int phy_get_int_delay_property(struct device *dev, const char *name)
  to:
    static int phy_get_u32_property(struct device *dev, const char *name, u32 *val)
- Apply helper function to phy_get_internal_delay
- Link to v3: https://lore.kernel.org/r/20250204-dp83822-tx-swing-v3-0-9798e96500d9@liebherr.com

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

 .../devicetree/bindings/net/ethernet-phy.yaml      |  6 +++
 drivers/net/phy/dp83822.c                          | 38 +++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 44 +++++++++++++---------
 include/linux/phy.h                                |  4 ++
 4 files changed, 74 insertions(+), 18 deletions(-)
---
base-commit: c2933b2befe25309f4c5cfbea0ca80909735fd76
change-id: 20241213-dp83822-tx-swing-5ba6c1e9b065

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

