From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH net-next v2 0/2] net: phy: tja11xx: add support for
 TJA1102S
Date: Tue, 04 Mar 2025 19:37:25 +0100
Message-Id: <20250304-tja1102s-support-v2-0-cd3e61ab920f@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGVIx2cC/3WNQQ6CMBBFr0Jm7ZhpCyisvIdhgWWUMdqSthIM4
 e427F2+vPz3V4gchCO0xQqBZ4niXQZ9KMCOvXswypAZNOmKDBlMz14p0hHjZ5p8SFgZXZ+s4ma
 wJeTZFPguy568guOEjpcEXTajxOTDd/+a1e7/Z2eFhOpM3JSVaWqmy0v4NnIIR+vf0G3b9gP0m
 GUJvQAAAA==
X-Change-ID: 20250303-tja1102s-support-53267c1e9dc4
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, Marek Vasut <marex@denx.de>, 
 Oleksij Rempel <o.rempel@pengutronix.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741113448; l=746;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Bw/dVSTLK7luxcPDdZYBYiUmYtXIgw/tfsWJ50AcuGA=;
 b=Lzb7ZvTFLeQN9Nzmki4hto+FnxiU8s/DQkQenhhoHerRNaslxzIRqEOGw3vcesOTL4i2oe3KD
 4uGh0FLyG+PAddTFUCm3rw3b1I76uKesd9t+x87abubgFa4kWbW0pOl
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- add support for TJA1102S
- enable PHY in sleep mode for TJA1102S

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Changes in v2:
- Drop fallthrough tja11xx_config_init
- Address net-next
- Link to v1: https://lore.kernel.org/r/20250303-tja1102s-support-v1-0-180e945396e0@liebherr.com

---
Dimitri Fedrau (2):
      net: phy: tja11xx: add support for TJA1102S
      net: phy: tja11xx: enable PHY in sleep mode for TJA1102S

 drivers/net/phy/nxp-tja11xx.c | 38 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)
---
base-commit: f77f12010f67259bd0e1ad18877ed27c721b627a
change-id: 20250303-tja1102s-support-53267c1e9dc4

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

