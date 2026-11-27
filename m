From: Willie Wiholm <willie.wiholm@tritechsolutions.se>
Subject: [PATCH RFC net 0/2] net: phy: dp83867: fix Wake-on-LAN without a
 PHY IRQ
Date: Fri, 27 Nov 2026 19:44:55 +0100
Message-Id: <20261127-wol-net-v1-0-769a2aff91df@tritechsolutions.se>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKfPCWsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNz3fL8HN281BJdQ4O01BRjS2NLU5NEJaDqgqLUtMwKsEnRSkFuziA
 xoDql2NpaAO5RlSZlAAAA
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Thomas Haemmerle <thomas.haemmerle@wolfvision.net>
Cc: netdev@vger.kernel.org, 
 Willie Wiholm <willie.wiholm@tritechsolutions.se>, stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795805097; l=1805;
 i=willie.wiholm@tritechsolutions.se; s=20261127; h=from:subject:message-id;
 bh=zddDQvfZ9dxo0LCn2owtXLM1iCgLlXakX558pOBrSeM=;
 b=vZVKp/CppB+qxIrBmL+iU53YfoBeLS7NQwGSdbJfzPJZ9xcANDTOtDPdY0Ey2oUkZmCps1EA3
 OMMqeezq3GKD4nv8lM+GvslrBXQ+ilbp2t6JdO73c6dFySjbCqM3zo/
X-Developer-Key: i=willie.wiholm@tritechsolutions.se; a=ed25519;
 pk=+cNLoL8211zFctWUX7P+l/TZm0pSVfYhLugt3NOecW8=
X-Endpoint-Received: by B4 Relay for willie.wiholm@tritechsolutions.se/20261127 with auth_id=1669
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On an Intel Elkhart Lake board (congatec conga-SA7, dwmac-intel with a
DP83867 over RGMII) Wake-on-LAN from S3 does not work on the first
suspend after boot or after a link down/up.

Patch 1 sets CFG3.INT_OE when WoL is enabled. Without a PHY IRQ the
driver never sets it, so the pin stays a power-down input. The firmware
sets it, but the soft reset on attach clears it, so the first suspend
after boot does not wake up.

Patch 2 reads ISR before suspend. Nothing reads it when the PHY is
polled, so a magic packet received while the system is running leaves
the WoL interrupt latched, and the next suspend does not wake up.

Tested on the board with net (28a371228d4e): the first suspend after
boot, after link down/up and after a magic packet received while
running all wake up on a unicast magic packet.

Questions:
1. Patch 1 makes the pin an output when WoL is enabled. Would you
   rather preserve the firmware setting across the soft reset, as
   043777e94880 does for the LED registers?
2. Patch 2 uses PHY_ALWAYS_CALL_SUSPEND to get a hook before suspend,
   like bcm54xx. Is that acceptable?

I used an AI coding assistant (Claude) for parts of the analysis, the
test automation and for drafting the cover letter. I have
reviewed the changes and tested them on the hardware.

Signed-off-by: Willie Wiholm <willie.wiholm@tritechsolutions.se>
---
Willie Wiholm (2):
      net: phy: dp83867: set INT_OE when enabling Wake-on-LAN
      net: phy: dp83867: clear latched WoL interrupt before suspend

 drivers/net/phy/dp83867.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)
---
base-commit: 28a371228d4eb4857cc31eeb1a0d7d01e9c3ea2f
change-id: 20261127-wol-net-10fed393954a

Best regards,
-- 
Willie Wiholm <willie.wiholm@tritechsolutions.se>

