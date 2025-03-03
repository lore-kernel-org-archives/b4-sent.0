From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Subject: [PATCH 0/2] net: phy: tja11xx: add support for TJA1102S
Date: Mon, 03 Mar 2025 16:14:35 +0100
Message-Id: <20250303-tja1102s-support-v1-0-180e945396e0@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFvHxWcC/x3MTQqAIBBA4avErBP8yaKuEi1Ep5oWJU5FIN09a
 fkt3svAmAgZhipDwpuYjr1A1RX41e0LCgrFoKW20kgjzs0pJTULvmI80ims0W3nFfbBN1CymHC
 m51+O0/t+sMKyR2IAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741014885; l=566;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=7DLOK/uhRKtW30A5mCMAwsDsod/wz2T3WW1IlbasAnk=;
 b=aagF8ewbwPElpUY+E2ZZONvvLuQXE+3+j6MZYavYlI+YfpogKKmYMiMbKU4mrqT2cndfpY8FA
 MC15ND+uWqYDP1Pu8liEaHxfI69xO4UGNLgbVAseQKTD/cDAmnuPNCM
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- add support for TJA1102S
- enable PHY in sleep mode for TJA1102S

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
Dimitri Fedrau (2):
      net: phy: tja11xx: add support for TJA1102S
      net: phy: tja11xx: enable PHY in sleep mode for TJA1102S

 drivers/net/phy/nxp-tja11xx.c | 39 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)
---
base-commit: f77f12010f67259bd0e1ad18877ed27c721b627a
change-id: 20250303-tja1102s-support-53267c1e9dc4

Best regards,
-- 
Dimitri Fedrau <dimitri.fedrau@liebherr.com>

