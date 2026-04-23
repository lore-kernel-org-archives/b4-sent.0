From: Corey Leavitt <corey@leavitt.info>
Subject: [PATCH RFC net-next 0/4] net: pse-pd: decouple controller lookup
 from MDIO probe
Date: Thu, 23 Apr 2026 01:42:13 -0600
Message-Id: <20260423-pse-notifier-decouple-v1-0-86ed750a9d62@leavitt.info>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBQFrxL+2g8xFCtuBQ/gtrhokxf9IklIU
 imU3t2oy2GYWakgCwqd1EoZbykSQ4P9TpF9jOEOFteYjDYH3RnDqYBDrOIFmR1snNMLDD8etet
 7302g1qYML8vvO9D1clYBlQOWSre/LfP0hK3fNW3bBzhMoZmHAAAA
X-Change-ID: 20260422-pse-notifier-decouple-efa80d77f4be
To: Oleksij Rempel <o.rempel@pengutronix.de>, 
 Kory Maincent <kory.maincent@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Andrew Lunn <andrew@lunn.ch>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Corey Leavitt <corey@leavitt.info>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776930134; l=5388;
 i=corey@leavitt.info; s=default; h=from:subject:message-id;
 bh=SHR2yJQ/Tjbh+rC55nFexgk7YhcMTx8ekAsEFlEHgTk=;
 b=BtV/BevWrW5hwYx+khyDHbDE7TKm3ukK8q2aMjCdsZMF22Qb4DO/rZ49yXtFKOlR3PVVhhVTf
 n177erRh+ePC94oDFIsSyGa34zybnTgA9T3r8000oCGk4Eon3iUzQHo
X-Developer-Key: i=corey@leavitt.info; a=ed25519;
 pk=Q3mmZT+4CRYT8qp8RWvab30X2v2JnLdhHuK7YIHKzpI=
X-Endpoint-Received: by B4 Relay for corey@leavitt.info/default with auth_id=748
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On systems where a PSE controller driver loads as a module and a
device-tree PHY node carries a `pses = <&pse_pi>` reference,
fwnode_mdiobus_register_phy() tries to resolve the PSE handle before
the controller driver has probed. of_pse_control_get() returns
-EPROBE_DEFER, the enclosing MDIO/DSA probe fails, and driver-core
re-queues the work. The retry loop spins until the PSE driver module
loads and its controller registers.

Commit fa2f0454174c ("net: pse-pd: Introduce attached_phydev to pse
control") made each retry expensive. It reordered
fwnode_mdiobus_register_phy() so the PHY is registered before the
PSE lookup. Every deferral now performs a full
phy_device_register() / phy_device_remove() cycle. On a board with a
sufficiently tight watchdog the retry loop can starve the watchdog
kthread. On the reporting hardware (MT7621 + gpio-wdt, 1-second
margin) the retry loop converts a slow probe phase into a reset
before userspace loads.

The affected population today looks small. OpenWrt, where PSE
actually ships, is still on 6.12 (pre-regression), and most
environments with CONFIG_PSE_*=m do not have boards whose DT
references a PSE controller from a PHY. Still, the mechanism is
general. Any modular PSE driver combined with the documented
`pses = <&...>` binding reproduces the retry loop. Whether it
reaches brick-grade or merely slow/flaky boot depends on local
watchdog timing. More exposure is expected as distribution and
embedded kernels move to 6.13 and later.

The narrow fix would be to partially revert the ordering in
fa2f0454174c so each defer is cheap again. That keeps the same
architecture (fwnode_mdio holding PSE knowledge, -EPROBE_DEFER
flowing across the subsystem boundary), and any future reorder
reintroduces the same class of bug. This series takes the larger
fix: decouple PSE controller lookup from MDIO registration entirely.
pse_core now publishes a BLOCKING_NOTIFIER chain with REGISTERED
and UNREGISTERED events. phy_device subscribes, owns phydev->psec
lifetime, and attaches PSE handles in response to controller
lifecycle rather than during probe. fwnode_mdio loses its PSE
awareness, and -EPROBE_DEFER no longer flows out of fwnode_mdio.

Patch breakdown:

  1. Scope the pse_control regulator handle to kref lifetime
     (Fixes: d83e13761d5b). A latent bug that patch 4 makes
     reachable.
  2. Add the notifier chain (enum, head, register/unregister
     helpers). Pure infrastructure. No subscribers yet, no
     observable change.
  3. Fire REGISTERED and UNREGISTERED events from the controller
     register/unregister paths. Still no subscribers, still no
     observable change.
  4. Subscribe from the PHY layer, take ownership of phydev->psec
     via the notifier, and remove fwnode_find_pse_control() from
     fwnode_mdio.

Patch 1 is bundled here per stable-kernel-rules section 4
reachability guidance. On mainline today, with no notifier
subscriber, no caller drives the dangling regulator-handle sequence.
Patches 2 and 3 are deliberately split to separate "add
infrastructure" from "wire it up". Happy to fold them if maintainers
prefer the combined form.

Validated on a Cudy C200P (MT7621 + IP804AR) running an OpenWrt
build of 6.18.21 with the series applied. A lockdep build
(CONFIG_PROVE_LOCKING + CONFIG_DEBUG_ATOMIC_SLEEP) shows no splats
from the series' code paths during boot, PHY attach, PHY detach, or
a full controller unbind/rebind cycle. ethtool --set-pse drives all
four PoE-capable LAN ports, and a Ruckus H510 class-4 PD plugged
into lan3 negotiates and receives 48 V.

The C200P has no SFP cage, so the SFP path change in sfp.c
(phy_device_register -> phy_device_register_locked) isn't exercised
on the bench. Verified by call-graph audit: every path reaching
sfp_sm_probe_phy() holds rtnl at entry, via sfp_timeout,
sfp_check_state, sfp_probe, sfp_remove, or
sfp_bus_{add,del}_upstream.

Not addressed by this series: ethtool --show-pse returns "No data
available" on DSA netdevs in 6.18, because dev->phydev is NULL for
DSA-frontend netdevs and ethnl_req_get_phydev() therefore returns
NULL. That's a DSA / ethtool integration quirk that predates this
work.

Sending as RFC because this is my first net-next series. I'd
appreciate maintainer guidance on whether patch 1 should go to net
rather than net-next, and whether the patch 2/3 split is preferred
to the combined form.

Signed-off-by: Corey Leavitt <corey@leavitt.info>
---
Corey Leavitt (4):
      net: pse-pd: scope pse_control regulator handle to kref lifetime
      net: pse-pd: add notifier chain for controller lifecycle events
      net: pse-pd: fire lifecycle events on controller register/unregister
      net: phy: own phydev->psec via PSE notifier and remove fwnode_mdio hook

 drivers/net/mdio/fwnode_mdio.c |  34 ----------
 drivers/net/phy/phy_device.c   | 144 ++++++++++++++++++++++++++++++++++++++---
 drivers/net/phy/sfp.c          |   2 +-
 drivers/net/pse-pd/pse_core.c  |  60 ++++++++++++++++-
 include/linux/phy.h            |   2 +
 include/linux/pse-pd/pse.h     |  41 ++++++++++++
 6 files changed, 236 insertions(+), 47 deletions(-)
---
base-commit: 1f5ffc672165ff851063a5fd044b727ab2517ae3
change-id: 20260422-pse-notifier-decouple-efa80d77f4be

Best regards,
--  
Corey Leavitt <corey@leavitt.info>

