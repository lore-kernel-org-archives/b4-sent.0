From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v2 0/2] net: phy: dp83822: Add support for GPIO2
 clock output
Date: Wed, 11 Dec 2024 09:04:38 +0100
Message-Id: <20241211-dp83822-gpio2-clk-out-v2-0-614a54f6acab@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJZHWWcC/3WNQQ6CMBBFr0Jm7RhoBYGV9zAssJ3CRGxJWwmGc
 Hcb4tbly8t/f4NAnilAm23gaeHAziYQpwzU2NuBkHViELm4FCKvUM+1rIXAYWYnUE1PdO+ISjf
 KVJLkVRtI29mT4fXo3sFSREtrhC6ZkUN0/nMcLsXhf+3mT3spMEejpap7UzbGlLeJ6TGS92flX
 tDt+/4FEX7aKMcAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733904292; l=1344;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=ZzbxjgecJ8fa0v+feo6S6Xx4k2fRvoVfmSCJajpyxHQ=;
 b=sNlY2EfgzLwGNb75JNVptc++ZJf3vlOpn5gLzzjBlNAnNB4zy2Al0D50jxbE8q+7pR6VXf+3W
 T/iOfzIr1arBmYAzRZpt/FjSEXBERck4PI0DR0BuQAOLyIMTPfACQMB
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
Changes in v2:
- Move MII_DP83822_IOCTRL2 before MII_DP83822_GENCFG
- List case statements together, and have one break at the end.
- Move dp83822->set_gpio2_clk_out = true at the end of the validation
- Link to v1: https://lore.kernel.org/r/20241209-dp83822-gpio2-clk-out-v1-0-fd3c8af59ff5@liebherr.com

---
Dimitri Fedrau (2):
      dt-bindings: net: dp83822: Add support for GPIO2 clock output
      net: phy: dp83822: Add support for GPIO2 clock output

 .../devicetree/bindings/net/ti,dp83822.yaml        |  7 ++++
 drivers/net/phy/dp83822.c                          | 40 ++++++++++++++++++++++
 include/dt-bindings/net/ti-dp83822.h               | 21 ++++++++++++
 3 files changed, 68 insertions(+)
---
base-commit: 65fb414c93f486cef5408951350f20552113abd0
change-id: 20241206-dp83822-gpio2-clk-out-cd9cf63e37df

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

