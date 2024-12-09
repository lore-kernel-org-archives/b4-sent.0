From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next 0/2] net: phy: dp83822: Add support for GPIO2
 clock output
Date: Mon, 09 Dec 2024 09:01:26 +0100
Message-Id: <20241209-dp83822-gpio2-clk-out-v1-0-fd3c8af59ff5@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANajVmcC/x3MTQrDIBBA4auEWWcgGYv5uUroouiYDC0qakoge
 PdKl9/ivRsyJ+EMa3dD4q9kCb5h7Dswx8vvjGKbgQZ6jDRotHFWMxHuUQKh+bwxnAWNXYzTitV
 kHbQ2JnZy/b8beC7o+SrwrPUHfJMjCnEAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733731307; l=1027;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=akpuU8iAvhFkyl41n5dk243jfH9laOe/uww9ehcdnyg=;
 b=VvlYey2w+r42PDWrMgENn0m+P3s0RxqudImUMmE2aM9aEtJO7jbyQnNLZHYmhCyqjitClveOM
 LPavXTfljwMAUxxl5oRWzaK7cy0E518yZeMXzmF95BHSDB2VjDpo9nH
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
Dimitri Fedrau (2):
      dt-bindings: net: dp83822: Add support for GPIO2 clock output
      net: phy: dp83822: Add support for GPIO2 clock output

 .../devicetree/bindings/net/ti,dp83822.yaml        |  7 ++++
 drivers/net/phy/dp83822.c                          | 44 ++++++++++++++++++++++
 include/dt-bindings/net/ti-dp83822.h               | 21 +++++++++++
 3 files changed, 72 insertions(+)
---
base-commit: 7ea2745766d776866cfbc981b21ed3cfdf50124e
change-id: 20241206-dp83822-gpio2-clk-out-cd9cf63e37df

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

