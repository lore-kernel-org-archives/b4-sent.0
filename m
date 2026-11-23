From: Igor Velkov <iav@iav.lv>
Subject: [PATCH net v8 0/5] net: phy: postpone PHY interrupts during sleep
 with MAC-managed PM
Date: Mon, 23 Nov 2026 00:46:12 +0000
Message-Id: <20261123-b4-phylib-mac-pm-irq-v3-v8-0-e9f706e79614@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANaMA2sC/4XQwW7DIAwA0F+pOI+JYCBJT/uPagccYLHUphmpU
 Ksq/z4vhy05ZEO+2JafLZ5iipniJI6Hp8ix0ETXgZPm5SC63g8fUVLgXGilXaV0K9HIsX+cCeX
 Fd3K8SMqfsoBMzrpgYtU5kwRPjzkmui/ySQzxJt652NN0u+bHsq3A0voX5lDStqpWxibQlXojX
 17PZQGLWSFQ7SPmG0GvASGl1psNYn8RfvuIZQQxBbQ+YR1gg7g1AvuIY0QxoK2CDvUWqdfIH39
 SMxIabJIBPsbpH2Se5y9YXAnL1AEAAA==
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Thomas Gleixner <tglx@kernel.org>, linux-pm@vger.kernel.org, 
 Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Lukas Wunner <lukas@wunner.de>, 
 "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 Wei Fang <wei.fang@nxp.com>, 
 =?utf-8?q?Niklas_S=C3=B6derlund?= <niklas.soderlund@ragnatech.se>, 
 Paul Barker <paul@pbarker.dev>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Doug Berger <opendmb@gmail.com>, 
 Thangaraj Samynathan <Thangaraj.S@microchip.com>, 
 Shenwei Wang <shenwei.wang@nxp.com>, 
 Haoning Cheng <Haoning.CHENG@cn.bosch.com>, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=10904; i=iav@iav.lv;
 h=from:subject:message-id; bh=j/BdLVaoHr/cHBR9QupJ0EX++LpaeV/lr1EBxrVAv0w=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNnMPdeP6f9Xf5q8L09vRe7G/lqLg12RvNzvuvbNkatW3
 6g5YeGCjlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjAR9fWMDKfrPN7/e7Xo8KTb
 d05eaTjKqFqxRFh1h+G+1VWnI/ctT+1i+GexO3FvjNcG5TPn2z9YcH/8rhayco1gr9/6yedWThH
 cM5sXAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the MAC driver manages PHY PM, phylib never sets irq_suspended, and
a PHY interrupt during the sleep transition runs the PHY driver's
handler while the MDIO bus may be powered down. On Helios64 (dwmac-rk)
this hangs the board on suspend as well as on resume.

mac_managed_pm hands phy_suspend(), phy_resume() and the state machine
to the MAC driver, since commit fba863b81604 ("net: phy: make PHY PM
ops a no-op if MAC driver manages PHY PM"); the PHY interrupt stays
with phylib, and so does postponing it.

Patches 1-4 fix the postponing that phylib applies to other PHYs, so
that patch 5 can extend it to MAC-managed ones. Patch 1 moves the two
flags out of a bitfield they share with the link state written under
phydev->lock. Patch 2 fixes three paths that unbalance the line of a
postponed interrupt: an edge that reruns the IRQ thread, a PHY that
frees its interrupt during the transition so that the line restarts,
and a PHY that falls back to polling. Patch 3 undoes the postponing
when phy_suspend() fails. Patch 4 runs the postponed handler directly,
as a nested threaded interrupt has no thread to wake, and not for a PHY
that has its interrupts disabled. Patch 5 sets irq_suspended for
MAC-managed PHYs too, from the PM prepare callback on; their postponed
interrupts report no wakeup. Patch 5 also enables a wakeup line that a
postponed interrupt left disabled for the noirq phase, for any PHY.

Patch 5 fixes a hang seen on Helios64 (dwmac-rk, RTL8211F): in s2idle
without WoL the board hung or reset 10 of 10 times without the series.
The PHY IRQ thread stalls its CPU on an MDIO read while the GMAC clocks
are off, so that CPU never answers the NMI:

  watchdog: CPU0: Watchdog detected hard LOCKUP on cpu 1
  After 10 seconds, these CPUS still haven't responded to the NMI: 1

Patches 1-4 fix defects found by code inspection and Sashiko review;
they were not triggered.

With MAC-managed PM, a postponed interrupt cannot tell Wake-on-LAN from
a link change that the MAC causes, so it reports no wakeup. The line it
disabled may stay masked for the whole sleep on an irqchip without
IRQCHIP_ENABLE_WAKEUP_ON_SUSPEND; patch 5 enables such a line for the
noirq phase when it is armed for wakeup, so an event the PHY still
signals wakes the system or aborts the suspend. On a level-triggered
line, a PHY that keeps a link interrupt asserted then aborts every
suspend with Wake-on-LAN enabled; on an edge-triggered line, a magic
packet that arrives during the transition does not abort it.

Thomas, the noirq suspend callback in patch 5 reads irqd_irq_disabled()
and irqd_is_wakeup_armed() from phylib to see whether to enable the
line. Would you rather have a helper in the irq core for this?

Not covered: MDIO accesses from closing or opening the interface during
the transition, and a MAC resume that fails to power the bus up. On a
shared line, a postponed PHY interrupt disables the line for its other
users until the PHY resumes. After all users have freed a shared line,
a PHY whose postponed interrupt disabled it still gets an unbalanced
enable_irq() at resume if another user requests the line before it
does; so does a PHY whose phy_free_interrupt() or
phy_request_interrupt() races with another user's request or free of
the line. The irq core does not arm a wakeup line behind a nested
threaded interrupt controller, so patch 5 leaves such a line disabled:
after a postponed interrupt, a MAC-managed PHY on it cannot wake the
system. When a PHY sits on an
MDIO bus its MAC does not own, the MAC resumes after the PHY, and the
replay still runs before the MAC resumes; ODROID-HC4 takes this path.
When mdio_bus_phy_resume() fails, the interrupts stay postponed.
mdio_bus_phy_may_suspend() does not ask phy_may_wakeup() about an
attached PHY, so phy_suspend() can still return -EBUSY and fail the
system suspend; patch 3 only cleans up after that.

Tested on Helios64 (dwmac-rk, RTL8211F) and ODROID-HC4 (dwmac-meson8b,
RTL8211F behind mdio-mux-meson-g12a), the noirq part of patch 5 under a
flood of magic packets. Haoning Cheng tested v5 on i.MX6 (fec).

Changes in v8:
- patch 5: for MAC-managed PHYs postponing starts in the PM prepare
  callback, so it covers a PHY on an MDIO bus its MAC does not own,
  where the MAC suspends first; the complete callback stops it after a
  transition that aborted before the PHY's suspend callback
- patch 2: the commit message names the interrupt storm with a stale
  irq_rerun (Sashiko on v7)
- commit messages after the review of v7 (Sashiko): the resume error
  path that patch 3 leaves alone, a third race on a shared line (patch
  2), a PHY that the MDIO bus did not suspend (patch 4), a PHY that
  raises no further edge, hibernation and PHY_ALWAYS_CALL_SUSPEND
  (patch 5); the kernel-doc of irq_pm_lock says what the lock covers
- tests rerun on v8, ODROID-HC4 added
- Link to v7: https://lore.kernel.org/r/20261119-b4-phylib-mac-pm-irq-v3-v7-0-d8b8f43b5a62@iav.lv

Changes in v7:
- patch 2: the postponed interrupt records the line it disabled;
  phy_request_interrupt() clears irq_rerun when the line has no users,
  so a line restarted after all its users freed it is not enabled once
  more at resume; mdio_bus_phy_resume() enables the recorded line also
  for a PHY that fell back to polling (Sashiko on v6)
- new patch 4: the postponed handler runs directly from
  mdio_bus_phy_resume(); irq_wake_thread() does nothing for a nested
  threaded interrupt (Sashiko on v6); the handler does not run for a PHY
  that has freed its interrupt, and phy_free_interrupt() waits for it
- patch 5: the commit message covers a PHY on an MDIO bus its MAC does
  not own (Sashiko on v6); noirq callbacks enable a wakeup line that a
  postponed interrupt left disabled
- tests rerun on v7
- Link to v6: https://lore.kernel.org/r/20261113-b4-phylib-mac-pm-irq-v3-v6-0-05af2503cb23@iav.lv

Changes in v6:
- patch 2: phy_free_interrupt() enables no line; it clears irq_rerun
  when the PHY was alone on the line, and mdio_bus_phy_resume()
  enables a shared line. Enabling it in phy_free_interrupt() could
  unmask a source that phy_disable_interrupts() failed to clear, or
  unbalance a wakeup line in the noirq phase (Sashiko on v5)
- patch 3: the resume error path is left as in net; clearing
  irq_suspended there let the handler reach a PHY that failed to
  resume (Sashiko on v5)
- patch 4: with mac_managed_pm, a postponed interrupt reports no
  wakeup, and other PHYs report what they report in net; irq_wake,
  wol_phy and the barriers are gone. A wakeup on Wake-on-LAN in the
  PHY let link interrupts that the MAC causes abort suspend on PHYs
  that leave them unmasked (Sashiko on v5)
- patch 1: the comment names the writers of the two flags (Sashiko on
  v5)
- patch 2: irq_pm_lock sits next to lock in struct phy_device
- comments say again that postponing lasts until the PHY has resumed
- the cover letter says what was reproduced (Jakub)
- Haoning Cheng's Tested-by on v5 kept on patch 1 only
- rebased on net
- tests rerun on v6
- Link to v5: https://lore.kernel.org/r/20261111-b4-phylib-mac-pm-irq-v3-v5-0-bbfdb5afb7d3@iav.lv

Changes in v5:
- v4 patch 2 alone could leave irq_rerun set across
  phy_free_interrupt() and a new request, after which a postponed
  level interrupt fired without end; it is merged with v4 patch 3 into
  patch 2. phy_free_interrupt() re-enables the line after free_irq(),
  not before, and only while other users of a shared line remain, so
  the handler cannot keep running on a source it cannot quiet;
  irq_rerun stays a bool (Sashiko on v4)
- patch 3: when the PHY fails to resume, the line a postponed
  interrupt disabled stays off, as before this series, instead of
  rerunning a handler that may not reach the PHY (Sashiko on v4)
- patch 4: with mac_managed_pm, only Wake-on-LAN in the PHY makes a
  postponed interrupt a wakeup; the ethtool flag may describe
  Wake-on-LAN in the MAC, as with fec (Sashiko on v4); for a PHY that
  phy_suspend() already suspended, the PHY part of its Wake-on-LAN
  state is kept in the new wol_phy
- patch 4: Fixes: now points at 1758bde2e4aa, which added the
  postponing after the early return for MAC-managed PHY PM
- comments say that postponing lasts until the transition ends
- Haoning Cheng's Tested-by on v4 kept on patch 1 only: patches 2-4
  changed
- rebased on net
- tests rerun on v5
- Link to v4: https://lore.kernel.org/r/20261031-b4-phylib-mac-pm-irq-v3-v4-0-5ba23b3ff9a4@iav.lv

Changes in v4:
- new patches 2-4, one pre-existing defect each
- patch 2: an edge that reruns the IRQ thread no longer disables the
  line twice
- patch 3: phy_free_interrupt() during the transition keeps the line
  balanced (Sashiko on v3)
- patch 4: a failing PHY PM callback no longer leaves the interrupt
  postponed (Sashiko on v2 and v3)
- patch 5: the wakeup event is decided in mdio_bus_phy_suspend(), where
  phy_may_wakeup() can still read the PHY (Sashiko on v3); Fixes: now
  points at the stmmac commit that took its PHYs out of postponing
- v3 asked phylib or phylink_suspend(): phylib, as macb sets
  mac_managed_pm but suspends with phylink_stop()
- tests rerun on v4
- Link to v3: https://lore.kernel.org/r/20261029-b4-phylib-mac-pm-irq-v3-v3-0-5907045f3210@iav.lv

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
- Link to v2: https://lore.kernel.org/r/20261026045343.837889-1-iav@iav.lv

Signed-off-by: Igor Velkov <iav@iav.lv>

---
Igor Velkov (5):
      net: phy: move irq_suspended and irq_rerun out of the bitfield
      net: phy: fix three paths that unbalance a postponed PHY interrupt line
      net: phy: stop postponing PHY interrupts when phy_suspend() fails
      net: phy: run a postponed PHY interrupt handler directly on resume
      net: phy: postpone PHY interrupts during sleep with MAC-managed PM

 drivers/net/phy/phy.c        |  32 +++++++--
 drivers/net/phy/phy_device.c | 155 ++++++++++++++++++++++++++++++++++++-------
 include/linux/phy.h          |  30 +++++++--
 3 files changed, 183 insertions(+), 34 deletions(-)
---
base-commit: ead6fa9a0ab194f02a2f36d634b193e9c5f9a1c6
change-id: 20261029-b4-phylib-mac-pm-irq-v3-f656d4e1c64f

Best regards,
-- 
Igor Velkov <iav@iav.lv>

