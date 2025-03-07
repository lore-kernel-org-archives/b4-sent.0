From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next 0/3] net: phy: dp83822: Add support for changing
 the MAC series termination
Date: Fri, 07 Mar 2025 11:30:00 +0100
Message-Id: <20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKjKymcC/x3MQQrDIBBG4auEWXfAaiy2VyldGP3bziJT0RACI
 XevZPkt3tupoQoaPYadKlZp8tOO62Wg9I36AUvuJmusN854ziW4YC3PMbHMBTlqAofRjM5PJt1
 xo96Wirds5/dJioUV20Kv4/gD0w/AmnEAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741343404; l=1035;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=no+4i1s9VlIVDNY5C3a4f9S1IkOBhSH/FQS6r2TvsaY=;
 b=TCkWSSDE1hhTziwDGZWPe+PbN0V3Vcq/0IiFoPbcdbTu8ZlgotwPZhjgQ+2bB2Ifp+Vpx7dhJ
 OhY+QxDJ1neARIm/ltqGfNpLey1Yg6TACe/NsHZOaVJfO7SR2Snn//9
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dp83822 provides the possibility to set the resistance value of the
the MAC series termination. Modifying the resistance to an appropriate
value can reduce signal reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (3):
      dt-bindings: net: ethernet-phy: add property mac-series-termination-ohms
      net: phy: Add helper for getting MAC series termination resistance
      net: phy: dp83822: Add support for changing the MAC series termination

 .../devicetree/bindings/net/ethernet-phy.yaml      |  5 +++
 drivers/net/phy/dp83822.c                          | 36 ++++++++++++++++++++++
 drivers/net/phy/phy_device.c                       | 15 +++++++++
 include/linux/phy.h                                |  3 ++
 4 files changed, 59 insertions(+)
---
base-commit: 865eddcf0afbcd54f79b81e6327ea40c997714c7
change-id: 20250305-dp83822-mac-impedance-840435b0c9e6

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

