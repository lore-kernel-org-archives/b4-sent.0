From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next 0/2] net: phy: dp83822: Add support for changing
 the transmit amplitude voltage
Date: Mon, 13 Jan 2025 06:40:11 +0100
Message-Id: <20250113-dp83822-tx-swing-v1-0-7ed5a9d80010@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADunhGcC/x3MSQqAMAxA0atI1gZsHFCvIi4comYTpS1aKN7d4
 vIt/o/g2Ao76LMIlm9xcmqCyTNYjkl3RlmTgQqqDJkS16stWyL0Ad0jumM9T81iuJuLpoaUXZY
 3Cf9yAGWPysHD+L4fOXfUxGwAAAA=
X-Change-ID: 20241213-dp83822-tx-swing-5ba6c1e9b065
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736746828; l=741;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=CMktPUZ1l4ycL/1KVGf9E6EF7MwJYouBdAu3wr7LLjA=;
 b=dbdzM3ZZU5gwurgEXklNsudXAT9os5VxcfxqueqohybLOoAlKkQMczcH3GWhx81HDhTfM12J0
 CVwLo8xavb2C7mMy2kT2yYwmpNMvqCC3Sk4FX9E6BSwNKPPxtsW32D+
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Add support for configuration via DT.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      dt-bindings: net: dp83822: Add support for changing the transmit amplitude voltage
      net: phy: dp83822: Add support for changing the transmit amplitude voltage

 .../devicetree/bindings/net/ti,dp83822.yaml        | 11 +++++++
 drivers/net/phy/dp83822.c                          | 35 ++++++++++++++++++++++
 2 files changed, 46 insertions(+)
---
base-commit: 7d0da8f862340c5f42f0062b8560b8d0971a6ac4
change-id: 20241213-dp83822-tx-swing-5ba6c1e9b065

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

