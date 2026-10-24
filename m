From: Franck Baur <franck.baur.67@gmail.com>
Date: Sat, 24 Oct 2026 14:40:44 +0200
Subject: [PATCH net v2] net: jme: keep RX MAC clock enabled for WoL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-jme-wol-v2-submit-v2-1-7a89ef6fb4c9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEun3GoC/x3MSQqAMAxA0atI1gZqHPEq4sIhakSrtHUA8e4Wl
 2/x/wOWjbCFMnjA8ClWNu1BYQDd1OiRUXpvIEVZpCjBeWW8tgVPQnu0qzhUAyd9W+RUpDH4bjc
 8yP0/K9DsoH7fD1/+LzhoAAAA
X-Change-ID: 20261024-jme-wol-v2-submit-0fe4db872853
To: Guo-Fu Tseng <cooldavid@cooldavid.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Franck Baur <franck.baur.67@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792845645; l=5786;
 i=franck.baur.67@gmail.com; s=20261024; h=from:subject:message-id;
 bh=22BEaH8HKwqaRYpioIznd0XJzULoDFALusQ6AsH9C08=;
 b=ZJnzMfzAMFTzgHH4A3FnhMapPYhdQxqyABK8rFksQxXAcuFVv9VoCG9l0x0s1YybjRphadpWQ
 EVce2go1QqjBMS/eXK2VLwXChANNDPLiOIuw8dOYpn45If7urHk0wnz
X-Developer-Key: i=franck.baur.67@gmail.com; a=ed25519;
 pk=jhUaI4DVBj7JgOebLvsUGOrgJCBubeK6gqDJjxIqtZ4=
X-Endpoint-Received: by B4 Relay for franck.baur.67@gmail.com/20261024 with auth_id=1302
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the JMicron JMC250 revision 03, the MAC reset performed during
suspend leaves GPREG1_RXCLKOFF set. Although the driver enables Magic
Packet detection, the gated RX MAC clock prevents wake-up from ACPI S3.

Keep the RX MAC clock enabled while WoL is armed. Restore the gated
clock state immediately after disabling WoL during resume, preserving
the RX engine initialization ordering.

Prevent concurrent link-change work from gating the clock again after
WoL has been armed. Quiesce interrupt-driven link-change scheduling,
synchronize pending interrupts, and cancel outstanding link-change
work before programming WoL in suspend and shutdown paths.

Restore the deferred processing state before requesting link
reinitialization on resume.

Tested on an ASUS K42JE with JMC250 [197b:0250] rev 03 using a
Debian 6.12.111 kernel and an externally built module. ACPI S3 wake
with a Magic Packet completed in 19 seconds, while a control without
a Magic Packet resumed through the RTC alarm after 123 seconds.
Ethernet and SSH recovered after resume.

S4 and S5 wake behaviour has not been validated with this revision.

Fixes: 854a2e7c331a ("jme: Safer MAC processor reset sequence")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Franck Baur <franck.baur.67@gmail.com>
---
Changes in v2:
- Restore RX MAC clock gating when WoL is disabled on resume, before
  reinitializing the RX engine.
- Prevent new interrupt-driven link-change work during suspend and
  shutdown, and drain pending work before arming WoL.
- Restore deferred processing before requesting link reinitialization.
- Validate Magic Packet wake from ACPI S3 on a JMC250 rev 03,
  including an RTC-only control test.
- Link to v1:
  https://lore.kernel.org/r/20261011-jme-wol-submit-v1-1-9cc033e259e4@gmail.com/

The full kernel allyesconfig and allmodconfig builds have not been
completed. The JME driver object builds with W=1 under both
configurations. The full allyesconfig build was limited by host
memory during vmlinux.o processing. S4 has not been tested, and S5
wake remains unconfirmed with this revision.
---
 drivers/net/ethernet/jme.c | 37 ++++++++++++++++++++++++++++++++-----
 drivers/net/ethernet/jme.h |  1 +
 2 files changed, 33 insertions(+), 5 deletions(-)

diff --git a/drivers/net/ethernet/jme.c b/drivers/net/ethernet/jme.c
index 25ec5f757c6828a5f5241340bf3fb01d8e0aa3e9..acb4d41f56e1002c0a34a253be20c780ad9b062f 100644
--- a/drivers/net/ethernet/jme.c
+++ b/drivers/net/ethernet/jme.c
@@ -1502,7 +1502,8 @@ jme_intr_msi(struct jme_adapter *jme, u32 intrstat)
 		 * all other events are ignored
 		 */
 		jwrite32(jme, JME_IEVE, intrstat);
-		schedule_work(&jme->linkch_task);
+		if (!test_bit(JME_FLAG_WOL_QUIESCE, &jme->flags))
+			schedule_work(&jme->linkch_task);
 		goto out_reenable;
 	}
 
@@ -1546,7 +1547,8 @@ jme_intr_msi(struct jme_adapter *jme, u32 intrstat)
 	/*
 	 * Re-enable interrupt
 	 */
-	jwrite32f(jme, JME_IENS, INTR_ENABLE);
+	if (!test_bit(JME_FLAG_WOL_QUIESCE, &jme->flags))
+		jwrite32f(jme, JME_IENS, INTR_ENABLE);
 }
 
 static irqreturn_t
@@ -1892,6 +1894,7 @@ jme_powersave_phy(struct jme_adapter *jme)
 		jme_set_100m_half(jme);
 		if (jme->reg_pmcs & (PMCS_LFEN | PMCS_LREN))
 			jme_wait_link(jme);
+		jme_mac_rxclk_on(jme);
 		jme_clear_pm_enable_wol(jme);
 	} else {
 		jme_phy_off(jme);
@@ -3158,6 +3161,21 @@ jme_shutdown(struct pci_dev *pdev)
 	struct net_device *netdev = pci_get_drvdata(pdev);
 	struct jme_adapter *jme = netdev_priv(netdev);
 
+	if (netif_running(netdev)) {
+		set_bit(JME_FLAG_WOL_QUIESCE, &jme->flags);
+		netif_device_detach(netdev);
+		netif_stop_queue(netdev);
+		jme_stop_irq(jme);
+		synchronize_irq(pdev->irq);
+		jme_stop_irq(jme);
+		cancel_work_sync(&jme->linkch_task);
+		tasklet_disable(&jme->pcc_task);
+		napi_disable(&jme->napi);
+		tasklet_disable(&jme->txclean_task);
+		tasklet_disable(&jme->rxclean_task);
+		tasklet_disable(&jme->rxempty_task);
+	}
+
 	jme_powersave_phy(jme);
 	pci_pme_active(pdev, true);
 }
@@ -3172,11 +3190,16 @@ jme_suspend(struct device *dev)
 	if (!netif_running(netdev))
 		return 0;
 
-	atomic_dec(&jme->link_changing);
-
+	set_bit(JME_FLAG_WOL_QUIESCE, &jme->flags);
 	netif_device_detach(netdev);
 	netif_stop_queue(netdev);
 	jme_stop_irq(jme);
+	synchronize_irq(jme->pdev->irq);
+	jme_stop_irq(jme);
+	cancel_work_sync(&jme->linkch_task);
+	tasklet_disable(&jme->pcc_task);
+	napi_disable(&jme->napi);
+	atomic_dec(&jme->link_changing);
 
 	tasklet_disable(&jme->txclean_task);
 	tasklet_disable(&jme->rxclean_task);
@@ -3215,6 +3238,7 @@ jme_resume(struct device *dev)
 		return 0;
 
 	jme_clear_pm_disable_wol(jme);
+	jme_mac_rxclk_off(jme);
 	jme_phy_on(jme);
 	if (test_bit(JME_FLAG_SSET, &jme->flags))
 		jme_set_link_ksettings(netdev, &jme->old_cmd);
@@ -3226,8 +3250,11 @@ jme_resume(struct device *dev)
 
 	atomic_inc(&jme->link_changing);
 
-	jme_reset_link(jme);
+	napi_enable(&jme->napi);
+	tasklet_enable(&jme->pcc_task);
+	clear_bit(JME_FLAG_WOL_QUIESCE, &jme->flags);
 
+	jme_reset_link(jme);
 	jme_start_irq(jme);
 
 	return 0;
diff --git a/drivers/net/ethernet/jme.h b/drivers/net/ethernet/jme.h
index 860494ff37144da9dc25d3105ecabb77072077b0..ec5dfddf7322730a316a4900026a88e479f8a8a1 100644
--- a/drivers/net/ethernet/jme.h
+++ b/drivers/net/ethernet/jme.h
@@ -450,6 +450,7 @@ enum jme_flags_bits {
 	JME_FLAG_SSET		= 2,
 	JME_FLAG_POLL		= 5,
 	JME_FLAG_SHUTDOWN	= 6,
+	JME_FLAG_WOL_QUIESCE	= 7,
 };
 
 #define TX_TIMEOUT		(5 * HZ)

---
base-commit: af32da41b0327b9c6a37856ba82b6760d6c8d10e
change-id: 20261024-jme-wol-v2-submit-0fe4db872853

Best regards,
-- 
Franck Baur <franck.baur.67@gmail.com>

