From: Igor Velkov <iav@iav.lv>
Subject: [PATCH net v3 0/2] net: phy: postpone PHY interrupts during sleep
 with MAC-managed PM
Date: Thu, 29 Oct 2026 04:58:20 +0000
Message-Id: <20261029-b4-phylib-mac-pm-irq-v3-v3-0-5907045f3210@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG3S4moC/x3MQQ5AMBBA0avIrE1CVROuIhZVUyahqhUh4u4ay
 7f4/4FIgSlCmz0Q6OTIm0uo8gzMrN1EyGMyiEKoshANDhL9fC884KoN+hU57HhWaFWtRkmlUdJ
 Cqn0gy9d/7sDRAf37fhP5SQhuAAAA
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Lukas Wunner <lukas@wunner.de>, 
 "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 Wei Fang <wei.fang@nxp.com>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Paul Barker <paul@pbarker.dev>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Doug Berger <opendmb@gmail.com>, 
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2683; i=iav@iav.lv;
 h=from:subject:message-id; bh=gJPvY9nSBtRKuoslNWP0NOc/ooK8yuUEFk6N66h2ty0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmPLuXxcXxlvhV5gXVJX822Be+cm7wLRHYseX/y3Oplu
 juC5jQ1d5SyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJTG1k+Kdi1Pm8on/ug63l
 t3o6tp2s65jFI9zVqnNp3T/+tZosqX8ZGdYxXMlewDepWMg3vjVo49nIBTU929j4bLqCnvd7HF2
 lzwkA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the MAC driver manages PHY PM, phylib never sets irq_suspended, and
a PHY interrupt during the sleep transition runs the PHY driver's
handler while the MDIO bus may be powered down. On Helios64 (dwmac-rk)
this hangs the board on suspend as well as on resume.

Patch 1 moves the two flags out of a bitfield they share with the link
state written under phydev->lock; patch 2 sets irq_suspended for these
PHYs too.

Open question on 2/2: a postponed interrupt leaves the PHY line
disabled until resume. With Wake-on-LAN, v3 still signals a wakeup
from it, so suspend would abort when the link changes after
phy_stop(): phylink_suspend() calls phylink_speed_down() after
phylink_stop() when the PHY is the wake source (stmmac sets
wol_phy_speed_ctrl), and a PHY that keeps its link interrupt enabled
raises one there. RTL8211F masks it in suspend when its wakeup is
enabled, so Helios64 woke on a magic packet 3 of 3 times. Never
signalling a
wakeup would let the system sleep with a wake-armed PHY line left
disabled. Is the v3 behaviour acceptable, or should the MAC set
irq_suspended once it has stopped the PHY (phylink_suspend() plus a
phylib helper for MACs without phylink)?

Changes in v3:
- with mac_managed_pm, a postponed interrupt signals a wakeup event only
  with Wake-on-LAN; with MAC power/wakeup enabled and no WoL, v2 aborted
  s2idle on Helios64 3 of 3 times, v3 0 of 3 (reported by Sashiko)
- phy_free_interrupt(): stop postponing and re-enable the line before
  free_irq(), not after it (reported by Sashiko)
- mdio_bus_phy_suspend() comment narrowed to the MDIO bus (reported by
  Sashiko)
- patch 1: Andrew suggested taking phydev->lock in phy_interrupt();
  the commit message says why that does not close the race
- tests rerun on v3

Not changed: the replay does not reach a nested threaded PHY interrupt
(irq_wake_thread() has no thread to wake). That code predates this
series; v3 sends MAC-managed PHYs through it as well.

Link to v2: https://lore.kernel.org/r/20261026045343.837889-1-iav@iav.lv

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (2):
      net: phy: move irq_suspended and irq_rerun out of the bitfield
      net: phy: postpone PHY interrupts during sleep with MAC-managed PM

 drivers/net/phy/phy.c        | 21 +++++++++++++++++---
 drivers/net/phy/phy_device.c | 46 +++++++++++++++++++++++++++-----------------
 include/linux/phy.h          | 10 ++++++----
 3 files changed, 52 insertions(+), 25 deletions(-)
---
base-commit: fcc00b15cb21a6de76826e5012b2c758505f5e65
change-id: 20261029-b4-phylib-mac-pm-irq-v3-f656d4e1c64f

Best regards,
-- 
Igor Velkov <iav@iav.lv>

