From: Igor Velkov <iav@iav.lv>
Date: Sat, 31 Oct 2026 08:01:13 +0000
Subject: [PATCH net v4 2/5] net: phy: disable the line of a postponed PHY
 interrupt only once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b4-phylib-mac-pm-irq-v3-v4-2-5ba23b3ff9a4@iav.lv>
References: <20261031-b4-phylib-mac-pm-irq-v3-v4-0-5ba23b3ff9a4@iav.lv>
In-Reply-To: <20261031-b4-phylib-mac-pm-irq-v3-v4-0-5ba23b3ff9a4@iav.lv>
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
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 Shenwei Wang <shenwei.wang@nxp.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4062; i=iav@iav.lv;
 h=from:subject:message-id; bh=8zXAet3FysmTNcLxuqPvOqbMTt4jhwFxSje2BLOJunQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFlPF3idmVP5ZuGJFTI6xhNNr6mU9/Z9fzSngbvy3K/DE
 +4ztG6b2VHKwiDGxSArpsgy4ZDGrYwlV//6e5g/gJnDygQyhIGLUwAm8msZw/+Mt6LzdE4a7CsP
 9iq+fn/SkZWfO9+93FrpayRgZ/3C5kwKw3+/4xs9XQM/e/BXK904LFQfV7daQcyc+XdfZ5ZT3vo
 Lt1gA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

phy_interrupt() postpones interrupts during a system sleep transition:
it sets irq_rerun and disables the line, and mdio_bus_phy_resume()
re-enables the line once and reruns the handler. On an edge-triggered
line the IRQ core does not mask a ONESHOT interrupt, so an edge that
arrives before disable_irq_nosync() runs the thread again. That second
run disables the line again, and the line stays disabled after resume.

Make irq_rerun atomic, as the next patch adds a second setter, and let
only the run that sets it disable the line. Mark the irq_suspended
accesses with READ_ONCE() and WRITE_ONCE(): the handler reads it while
the PM callbacks write it.

Fixes: 1758bde2e4aa ("net: phy: Don't trigger state machine while in suspend")
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/net/phy/phy.c        | 7 ++++---
 drivers/net/phy/phy_device.c | 7 +++----
 include/linux/phy.h          | 5 ++---
 3 files changed, 9 insertions(+), 10 deletions(-)

diff --git a/drivers/net/phy/phy.c b/drivers/net/phy/phy.c
index 9af303d60bd6..b47f0d3d99e5 100644
--- a/drivers/net/phy/phy.c
+++ b/drivers/net/phy/phy.c
@@ -1416,7 +1416,7 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 	/* Wakeup interrupts may occur during a system sleep transition.
 	 * Postpone handling until the PHY has resumed.
 	 */
-	if (IS_ENABLED(CONFIG_PM_SLEEP) && phydev->irq_suspended) {
+	if (IS_ENABLED(CONFIG_PM_SLEEP) && READ_ONCE(phydev->irq_suspended)) {
 		struct net_device *netdev = phydev->attached_dev;
 
 		if (netdev) {
@@ -1430,8 +1430,9 @@ static irqreturn_t phy_interrupt(int irq, void *phy_dat)
 				pm_wakeup_dev_event(parent, 0, true);
 		}
 
-		phydev->irq_rerun = true;
-		disable_irq_nosync(irq);
+		/* Disable the line only once: an edge can rerun the thread. */
+		if (!atomic_xchg(&phydev->irq_rerun, 1))
+			disable_irq_nosync(irq);
 		return IRQ_HANDLED;
 	}
 
diff --git a/drivers/net/phy/phy_device.c b/drivers/net/phy/phy_device.c
index 79dba43d703a..d5d0efc10418 100644
--- a/drivers/net/phy/phy_device.c
+++ b/drivers/net/phy/phy_device.c
@@ -344,7 +344,7 @@ static __maybe_unused int mdio_bus_phy_suspend(struct device *dev)
 	 * has resumed. Wait for concurrent interrupt handler to complete.
 	 */
 	if (phy_interrupt_is_valid(phydev)) {
-		phydev->irq_suspended = true;
+		WRITE_ONCE(phydev->irq_suspended, true);
 		synchronize_irq(phydev->irq);
 	}
 
@@ -394,14 +394,13 @@ static __maybe_unused int mdio_bus_phy_resume(struct device *dev)
 		return ret;
 no_resume:
 	if (phy_interrupt_is_valid(phydev)) {
-		phydev->irq_suspended = false;
+		WRITE_ONCE(phydev->irq_suspended, false);
 		synchronize_irq(phydev->irq);
 
 		/* Rerun interrupts which were postponed by phy_interrupt()
 		 * because they occurred during the system sleep transition.
 		 */
-		if (phydev->irq_rerun) {
-			phydev->irq_rerun = false;
+		if (atomic_xchg(&phydev->irq_rerun, 0)) {
 			enable_irq(phydev->irq);
 			irq_wake_thread(phydev->irq, phydev);
 		}
diff --git a/include/linux/phy.h b/include/linux/phy.h
index bbe28ff97e51..48b4e852f230 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -651,8 +651,7 @@ struct phy_oatc14_sqi_capability {
  * @interrupts: Flag interrupts have been enabled
  * @irq_suspended: Flag indicating PHY is suspended and therefore interrupt
  *                 handling shall be postponed until PHY has resumed
- * @irq_rerun: Flag indicating interrupts occurred while PHY was suspended,
- *             requiring a rerun of the interrupt handler after resume
+ * @irq_rerun: Set by the postponed interrupt that disabled the line
  * @default_timestamp: Flag indicating whether we are using the phy
  *		       timestamp as the default one
  * @interface: enum phy_interface_t value
@@ -728,7 +727,7 @@ struct phy_device {
 	unsigned interrupts:1;
 	/* Written without phydev->lock, so not bitfields */
 	bool irq_suspended;
-	bool irq_rerun;
+	atomic_t irq_rerun;
 
 	unsigned default_timestamp:1;
 

-- 
2.43.0

