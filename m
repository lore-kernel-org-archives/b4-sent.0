From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v3 0/4] net: phy: dp83822: Add support for
 changing the MAC series termination
Date: Wed, 16 Apr 2025 19:14:46 +0200
Message-Id: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIbl/2cC/3XNywqDMBQE0F+RrHtLzKPGrvofpYs8rjVQoyQSL
 OK/N0ihUHA5DHNmJQmjx0Su1UoiZp/8GErgp4rYXocngnclE0aZpJxKcJPiijEYtAU/TOh0sAh
 KUMGlobbFCynbKWLnl929k4AzBFxm8ihN79M8xvd+mOu9/9rNgZ1roGCcU1I3sjVC3l4eTY8xn
 u047GhmP0hQdQSxAnXYodFCt4qKP2jbtg89BHbNEAEAAA==
X-Change-ID: 20250305-dp83822-mac-impedance-840435b0c9e6
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, Andrew Davis <afd@ti.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744823698; l=1944;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=rrCB5OTUZE7hdVNRyzzj/bm/DBwSH2wkplB+PM4ecfU=;
 b=PiRAcgqLqN2FBIxZgGgm9aXyDZvYEBE0SzKfRcaEYVP68Q+KngzXZApdwAClkyrzpOiRr+6tI
 ecsWZSK1OK5CNzUvHt1c1C2ZaDajaCH7/Wcz7ezalLnHSxmJmJCQyDQ
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dp83822 provides the possibility to set the resistance value of the
the MAC series termination. Modifying the resistance to an appropriate
value can reduce signal reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- Add maximum to mac-termination-ohms in ethernet-phy.yaml
- Add allowed values for mac-termination-ohms in ti,dp83822.yaml
- Added mac-termination-ohms in sample in ti,dp83822.yaml
- Link to v2: https://lore.kernel.org/r/20250408-dp83822-mac-impedance-v2-0-fefeba4a9804@liebherr.com

Changes in v2:
- Renamed "mac-series-termination-ohms" to "mac-termination-ohms"
- Added description for "mac-termination-ohms"
- Renamed "phy_get_mac_series_termination" to "phy_get_mac_termination"
- Dropped "mac_series_termination_modify" from dp83822_private
- Init mac_termination_index in dp8382x_probe
- Renamed "mac_series_termination" to "mac_termination"
- Link to v1: https://lore.kernel.org/r/20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com

---
Dimitri Fedrau (4):
      dt-bindings: net: ethernet-phy: add property mac-termination-ohms
      dt-bindings: net: dp83822: add constraints for mac-termination-ohms
      net: phy: Add helper for getting MAC termination resistance
      net: phy: dp83822: Add support for changing the MAC termination

 .../devicetree/bindings/net/ethernet-phy.yaml      | 10 +++++++
 .../devicetree/bindings/net/ti,dp83822.yaml        |  4 +++
 drivers/net/phy/dp83822.c                          | 33 ++++++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 15 ++++++++++
 include/linux/phy.h                                |  3 ++
 5 files changed, 65 insertions(+)
---
base-commit: ac1df712442c64b50cfdbe01da0e5aca8319b559
change-id: 20250305-dp83822-mac-impedance-840435b0c9e6

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

