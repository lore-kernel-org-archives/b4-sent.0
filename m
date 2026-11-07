From: Hleb Shauchenka <me@marleb.org>
Subject: [PATCH net-next v2 0/3] net: phy: realtek: register hwmon thermal
 zones
Date: Sat, 07 Nov 2026 18:00:44 +0100
Message-Id: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOTQ6CMBCFr2Jm7agtUcSV9zAs2jrCqLRmWhEl3
 F3Atcv39+X1EEmYIhwWPQi1HDn4UejlAlxtfEXI51GD3uidUpsMhcw90Q3rVxM8pg8WW53lptD
 KXgoYZw+hC3cz8gSeEnrqEpS/JD7tlVyaiFPXmkhoxXhXT1YQrtivG8N+SmuOKch7/taqmff/R
 qtQIe1ynevMbffOHhsjd7KrIBWUwzB8AWPgrAnrAAAA
X-Change-ID: 20261103-realtek-hwmon-tz-95237a921bf9
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1331; i=me@marleb.org;
 h=from:subject:message-id; bh=jAz7L+bhgd/IVWN5dn7Smhib0FoZG3Ky40jagdvleSc=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWe8jU3kmRdpLp007m2Ck1bXiqMS8m4L/ThcZqO2pn
 qXpdG3NVcuOUhYGMS4GWTFFlk3NRaJPV0a/da3ekwUzh5UJZAgDF6cATORrC8M/zeSla5JvOp/d
 ovrp5t0Psl9uTAi5u/Xj6/Ld/Mln/+k5fmdkmOM5heWJuyPjJY6V39Xmy6UtC3Oek3fqYJPO7Ow
 7K3mtuQCvbEpo
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let device-tree thermal zones use the temperature sensor of Realtek
PHYs. Patch 1 allows #thermal-sensor-cells in PHY nodes, patch 2 stops
failed MDIO reads from being reported as temperatures, and patch 3
registers the sensor with the thermal framework.

This series was prepared with AI assistance; each patch says how.

---
Changes in v2:
- Add #thermal-sensor-cells to the ethernet-phy binding (patch 1).
- Return MDIO read errors from the hwmon read (patch 2).
- Patch 3: name the mainline PHYs it affects and say that the RTL8261N
  test relied on OpenWrt's out-of-tree support. Code unchanged, so I
  kept Andrew's Reviewed-by.
- Link to v1: https://patch.msgid.link/20261103-realtek-hwmon-tz-v1-1-e672723c58cb@marleb.org

---
Hleb Shauchenka (3):
      dt-bindings: net: ethernet-phy: add property #thermal-sensor-cells
      net: phy: realtek: return MDIO read errors from hwmon
      net: phy: realtek: register hwmon thermal zones

 Documentation/devicetree/bindings/net/ethernet-phy.yaml |  6 ++++++
 drivers/net/phy/realtek/realtek_hwmon.c                 | 13 +++++++++----
 2 files changed, 15 insertions(+), 4 deletions(-)
---
base-commit: fa5196392691051963726787944db872420dfa75
change-id: 20261103-realtek-hwmon-tz-95237a921bf9

Best regards,
--  
Hleb Shauchenka <me@marleb.org>

