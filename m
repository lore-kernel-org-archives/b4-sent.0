From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v3 0/2] net: phy: dp83822: Add support for GPIO2
 clock output
Date: Thu, 12 Dec 2024 09:44:05 +0100
Message-Id: <20241212-dp83822-gpio2-clk-out-v3-0-e4af23490f44@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFWiWmcC/3XN0Q6CIBgF4FdxXPc3ASXtqvdoXSD8KKvEgTGb8
 91jrIvW5uXZ2fnOSgJ6i4Gci5V4jDZYN6bADwVRgxx7BKtTJqxkFWWlAD01vGEM+sk6BupxB/e
 aQelWGcGRn7QhaTt5NHbJ7pWMOMOIy0xuqRlsmJ1/58NIc/+12x07UijBaK4aaerWmPrysNgN6
 P1RuWdGI/uBKN2DWIIErWRdGSGV7P6gbds+04fsRBABAAA=
X-Change-ID: 20241206-dp83822-gpio2-clk-out-cd9cf63e37df
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733993055; l=1627;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=BsCgYFZcnDgVtF99wPIkB0aPEfMbStFx+F00Xk/qQfg=;
 b=arNm8HpkQ/hNROhZaSL+MMtw3sgiZkb8Qqo0ATyNiD2tTdFWk+9DFb2cOnueh7L75oYQ+pWx4
 tyQZYnbO/b5B5xUD1aEn9N27qvWhFxGoOo32jX6r1QBw4n0oGsINntf
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DP83822 has several clock configuration options for pins GPIO1, GPIO2
and GPIO3. Clock options include:
  - MAC IF clock
  - XI clock
  - Free-Running clock
  - Recovered clock
This patch adds support for GPIO2, the support for GPIO1 and GPIO3 can be
easily added if needed. Code and device tree bindings are derived from
dp83867 which has a similar feature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v3:
- Dropped <dt-bindings/net/ti-dp83822.h>
- Moved defines from <dt-bindings/net/ti-dp83822.h> to dp83822.c
- Switched to enum of type string for property ti,gpio2-clk-out and added
  explanation for values, added example.
- Link to v2: https://lore.kernel.org/r/20241211-dp83822-gpio2-clk-out-v2-0-614a54f6acab@liebherr.com

Changes in v2:
- Move MII_DP83822_IOCTRL2 before MII_DP83822_GENCFG
- List case statements together, and have one break at the end.
- Move dp83822->set_gpio2_clk_out = true at the end of the validation
- Link to v1: https://lore.kernel.org/r/20241209-dp83822-gpio2-clk-out-v1-0-fd3c8af59ff5@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: net: dp83822: Add support for GPIO2 clock output
      net: phy: dp83822: Add support for GPIO2 clock output

 .../devicetree/bindings/net/ti,dp83822.yaml        | 27 ++++++++++++
 drivers/net/phy/dp83822.c                          | 48 ++++++++++++++++++++++
 2 files changed, 75 insertions(+)
---
base-commit: 65fb414c93f486cef5408951350f20552113abd0
change-id: 20241206-dp83822-gpio2-clk-out-cd9cf63e37df

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

