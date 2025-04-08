From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v2 0/3] net: phy: dp83822: Add support for
 changing the MAC series termination
Date: Tue, 08 Apr 2025 09:45:31 +0200
Message-Id: <20250408-dp83822-mac-impedance-v2-0-fefeba4a9804@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABvU9GcC/3WNywqDMBBFf0Vm3Skxmhpd9T+KizymdaBGSUQs4
 r83SLddHg733B0SRaYEXbFDpJUTTyGDvBTgBhNehOwzgxRSiUoo9LOutJQ4Goc8zuRNcIS6FnW
 lrHAt3SBv50hP3s7uAwItGGhboM9m4LRM8XMeruXpf+3mT3stUaD1XivTqNbW6v5msgPFeHXTC
 P1xHF/GHUuUxwAAAA==
X-Change-ID: 20250305-dp83822-mac-impedance-840435b0c9e6
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744098338; l=1500;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=OvKGbB2FbzBCATO/Bgq5TPoN+AHARPbGu6KH2H1fDDw=;
 b=LAP+5KozOfLFiM9ARSpBu0uYlfKBnWFlKSIEmHuCE92oEypvNMNHSfEJlTOZxY+HY6lLA1X/f
 tK9686IiRiaAPUOAdgx9IRqOWq4Szc8sSbjvHzzoEx48sIfqzoqz3aj
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dp83822 provides the possibility to set the resistance value of the
the MAC series termination. Modifying the resistance to an appropriate
value can reduce signal reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Renamed "mac-series-termination-ohms" to "mac-termination-ohms"
- Added description for "mac-termination-ohms"
- Renamed "phy_get_mac_series_termination" to "phy_get_mac_termination"
- Dropped "mac_series_termination_modify" from dp83822_private
- Init mac_termination_index in dp8382x_probe
- Renamed "mac_series_termination" to "mac_termination"
- Link to v1: https://lore.kernel.org/r/20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com

---
Dimitri Fedrau (3):
      dt-bindings: net: ethernet-phy: add property mac-termination-ohms
      net: phy: Add helper for getting MAC termination resistance
      net: phy: dp83822: Add support for changing the MAC termination

 .../devicetree/bindings/net/ethernet-phy.yaml      |  9 ++++++
 drivers/net/phy/dp83822.c                          | 33 ++++++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 15 ++++++++++
 include/linux/phy.h                                |  3 ++
 4 files changed, 60 insertions(+)
---
base-commit: 61f96e684edd28ca40555ec49ea1555df31ba619
change-id: 20250305-dp83822-mac-impedance-840435b0c9e6

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

