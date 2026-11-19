From: Igor Velkov <iav@iav.lv>
Date: Thu, 19 Nov 2026 01:12:36 +0000
Subject: [PATCH] PCI: rockchip-host: Support hibernation with endpoints in
 D0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-rockchip-pcie-hib-v1-1-05df24cc77e6@iav.lv>
X-B4-Tracking: v=1; b=H4sIAANN/moC/x3MQQqAIBBA0avErBtwRIK6SrTIccohKFGIQLp70
 vIt/q9QJKsUmLoKWW4tep0N1HfAcT13QQ3NYI0diGhE7zBffHDUhIlVMKpHY5zQGtgZZ6GlKcu
 mz7+dl/f9AEvHSUxmAAAA
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, Heiko Stuebner <heiko@sntech.de>, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Rob Herring <robh@kernel.org>, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3860; i=iav@iav.lv;
 h=from:subject:message-id; bh=tt1dbxgPAsX3IFa6cNo4EeAGvruDQ8t+mQUrzu36VIA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFn/fFkLdjOq/VvaYb5qy+rEVp9/9i1Kum+enHy7OHvJw
 +56/X8uHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiW68yMiy6dXtzyes9JYFh
 EzrObIx5cy/W4desP1GbA59ozX+gZBDGyNCroHr9tm1TxhZNtfNPZ/d6byj5oWV1V2dp3Oftv5e
 IvmYDAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver runs its suspend callback on every system sleep transition,
including hibernation freeze and the quiesce step of the kernel that
loads the image. The PCI core leaves the endpoints in D0 there, the
link does not enter L2 after PME_Turn_Off, and hibernation aborts:

  rockchip-pcie f8000000.pcie: PCIe link enter L2 timeout!
  rockchip-pcie f8000000.pcie: PM: failed to freeze noirq: error -110

Keep the link up across freeze and thaw. On restore, power the port
down and bring it up as on resume, because the kernel that loaded the
image may have left it in any state. The port may already be down if
poweroff_noirq ran, so track that state.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on v7.4-rc3 with this patch, ROCK Pi 4A with a WD SN770 NVMe:
5 of 5 hibernation cycles restored, the NVMe readable after each.
---
 drivers/pci/controller/pcie-rockchip-host.c | 33 +++++++++++++++++++++++++++--
 drivers/pci/controller/pcie-rockchip.h      |  1 +
 2 files changed, 32 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 1e1556e436b8..df4b9b3ec031 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -863,6 +863,8 @@ static int rockchip_pcie_suspend_noirq(struct device *dev)
 
 	regulator_disable(rockchip->vpcie0v9);
 
+	rockchip->powered_down = true;
+
 	return ret;
 }
 
@@ -893,6 +895,8 @@ static int rockchip_pcie_resume_noirq(struct device *dev)
 	rockchip_pcie_update_txcredit_mui(rockchip);
 	rockchip_pcie_enable_interrupts(rockchip);
 
+	rockchip->powered_down = false;
+
 	return 0;
 
 err_err_deinit_port:
@@ -904,6 +908,25 @@ static int rockchip_pcie_resume_noirq(struct device *dev)
 	return err;
 }
 
+static int rockchip_pcie_restore_noirq(struct device *dev)
+{
+	struct rockchip_pcie *rockchip = dev_get_drvdata(dev);
+
+	/*
+	 * The boot kernel may have left the port in any state, while the image
+	 * holds the enable counts of a running port. Power it down so that
+	 * resume brings it up from scratch.
+	 */
+	if (!rockchip->powered_down) {
+		rockchip_pcie_deinit_phys(rockchip);
+		rockchip_pcie_disable_clocks(rockchip);
+		regulator_disable(rockchip->vpcie0v9);
+		rockchip->powered_down = true;
+	}
+
+	return rockchip_pcie_resume_noirq(dev);
+}
+
 static int rockchip_pcie_probe(struct platform_device *pdev)
 {
 	struct rockchip_pcie *rockchip;
@@ -1011,9 +1034,15 @@ static void rockchip_pcie_remove(struct platform_device *pdev)
 	regulator_disable(rockchip->vpcie0v9);
 }
 
+/*
+ * Freeze leaves the endpoints in D0 and the link does not reach L2 then,
+ * so keep the link up across freeze and thaw; restore re-inits the port.
+ */
 static const struct dev_pm_ops rockchip_pcie_pm_ops = {
-	NOIRQ_SYSTEM_SLEEP_PM_OPS(rockchip_pcie_suspend_noirq,
-				  rockchip_pcie_resume_noirq)
+	.suspend_noirq = pm_sleep_ptr(rockchip_pcie_suspend_noirq),
+	.resume_noirq = pm_sleep_ptr(rockchip_pcie_resume_noirq),
+	.poweroff_noirq = pm_sleep_ptr(rockchip_pcie_suspend_noirq),
+	.restore_noirq = pm_sleep_ptr(rockchip_pcie_restore_noirq),
 };
 
 static const struct of_device_id rockchip_pcie_of_match[] = {
diff --git a/drivers/pci/controller/pcie-rockchip.h b/drivers/pci/controller/pcie-rockchip.h
index b5da15601b58..51877678d3df 100644
--- a/drivers/pci/controller/pcie-rockchip.h
+++ b/drivers/pci/controller/pcie-rockchip.h
@@ -324,6 +324,7 @@ struct rockchip_pcie {
 	void    __iomem *msg_region;
 	phys_addr_t msg_bus_addr;
 	bool is_rc;
+	bool powered_down;
 	struct resource *mem_res;
 };
 

---
base-commit: 35f800669ce835aa77364a2ab5b61be19b778d3c
change-id: 20261119-b4-rockchip-pcie-hib-004e1adc4042

Best regards,
-- 
Igor Velkov <iav@iav.lv>

