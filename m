From: Igor Velkov <iav@iav.lv>
Date: Sat, 14 Nov 2026 22:12:58 +0000
Subject: [PATCH 1/2] PCI: meson: Power the PHY on and reset the controller
 in host .init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-b4-pci-meson-suspend-v1-1-be3d04a13304@iav.lv>
References: <20261114-b4-pci-meson-suspend-v1-0-be3d04a13304@iav.lv>
In-Reply-To: <20261114-b4-pci-meson-suspend-v1-0-be3d04a13304@iav.lv>
To: Yue Wang <yue.wang@Amlogic.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pci@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3928; i=iav@iav.lv;
 h=from:subject:message-id; bh=sVRTJrvFuucyhaCx7JzxASlark4tRG0RVp/ihG4vEWE=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk/7rx1crwUHcWQ9/LE2mO5cybv+yaw9b7a4n25FpN22
 BzqP7Ogr6OUhUGMi0FWTJFlwiGNWxlLrv719zB/ADOHlQlkCAMXpwBMRNaF4X/KFAHrSadWJzod
 ecf1sNm6h+uI4MXTs8/wbr0w5X7ElAUSDP+LK0P5kp+66V05aZh1dmL7PZvaifxNDU39tbofTsc
 snMwOAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the PHY power on and the PHY and controller reset from probe into
the host .init callback, and add a .deinit that asserts PERST# and
powers the PHY off, and a .stop_link that disables the LTSSM.
dw_pcie_host_init() calls .deinit on a later probe error and
dw_pcie_host_deinit() calls it at remove, so probe and remove do not
power the PHY off themselves.

This prepares for system suspend, where dw_pcie_suspend_noirq() and
dw_pcie_resume_noirq() run the same callbacks.

It also changes the order in probe: the clocks are enabled before the
PHY is powered on and the controller is reset.  Resume runs .init with
the clocks still on, so both take the same order.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/pci/controller/dwc/pci-meson.c | 55 ++++++++++++++++++++++------------
 1 file changed, 36 insertions(+), 19 deletions(-)

diff --git a/drivers/pci/controller/dwc/pci-meson.c b/drivers/pci/controller/dwc/pci-meson.c
index 03dd1282f3f3..627470c83bb5 100644
--- a/drivers/pci/controller/dwc/pci-meson.c
+++ b/drivers/pci/controller/dwc/pci-meson.c
@@ -315,6 +315,16 @@ static int meson_pcie_start_link(struct dw_pcie *pci)
 	return 0;
 }
 
+static void meson_pcie_stop_link(struct dw_pcie *pci)
+{
+	struct meson_pcie *mp = to_meson_pcie(pci);
+	u32 val;
+
+	val = meson_cfg_readl(mp, PCIE_CFG0);
+	val &= ~APP_LTSSM_ENABLE;
+	meson_cfg_writel(mp, val, PCIE_CFG0);
+}
+
 static int meson_pcie_rd_own_conf(struct pci_bus *bus, u32 devfn,
 				  int where, int size, u32 *val)
 {
@@ -360,6 +370,20 @@ static int meson_pcie_host_init(struct dw_pcie_rp *pp)
 {
 	struct dw_pcie *pci = to_dw_pcie_from_pp(pp);
 	struct meson_pcie *mp = to_meson_pcie(pci);
+	int ret;
+
+	ret = meson_pcie_power_on(mp);
+	if (ret) {
+		dev_err(pci->dev, "phy power on failed, %d\n", ret);
+		return ret;
+	}
+
+	ret = meson_pcie_reset(mp);
+	if (ret) {
+		dev_err(pci->dev, "reset failed, %d\n", ret);
+		meson_pcie_power_off(mp);
+		return ret;
+	}
 
 	pp->bridge->ops = &meson_pci_ops;
 
@@ -369,13 +393,23 @@ static int meson_pcie_host_init(struct dw_pcie_rp *pp)
 	return 0;
 }
 
+static void meson_pcie_host_deinit(struct dw_pcie_rp *pp)
+{
+	struct meson_pcie *mp = to_meson_pcie(to_dw_pcie_from_pp(pp));
+
+	gpiod_set_value_cansleep(mp->reset_gpio, 1);
+	meson_pcie_power_off(mp);
+}
+
 static const struct dw_pcie_host_ops meson_pcie_host_ops = {
 	.init = meson_pcie_host_init,
+	.deinit = meson_pcie_host_deinit,
 };
 
 static const struct dw_pcie_ops dw_pcie_ops = {
 	.link_up = meson_pcie_link_up,
 	.start_link = meson_pcie_start_link,
+	.stop_link = meson_pcie_stop_link,
 };
 
 static int meson_pcie_probe(struct platform_device *pdev)
@@ -419,22 +453,10 @@ static int meson_pcie_probe(struct platform_device *pdev)
 		return ret;
 	}
 
-	ret = meson_pcie_power_on(mp);
-	if (ret) {
-		dev_err(dev, "phy power on failed, %d\n", ret);
-		return ret;
-	}
-
-	ret = meson_pcie_reset(mp);
-	if (ret) {
-		dev_err(dev, "reset failed, %d\n", ret);
-		goto err_phy;
-	}
-
 	ret = meson_pcie_probe_clocks(mp);
 	if (ret) {
 		dev_err(dev, "init clock resources failed, %d\n", ret);
-		goto err_phy;
+		return ret;
 	}
 
 	platform_set_drvdata(pdev, mp);
@@ -442,14 +464,10 @@ static int meson_pcie_probe(struct platform_device *pdev)
 	ret = dw_pcie_host_init(&pci->pp);
 	if (ret < 0) {
 		dev_err(dev, "Add PCIe port failed, %d\n", ret);
-		goto err_phy;
+		return ret;
 	}
 
 	return 0;
-
-err_phy:
-	meson_pcie_power_off(mp);
-	return ret;
 }
 
 static void meson_pcie_remove(struct platform_device *pdev)
@@ -457,7 +475,6 @@ static void meson_pcie_remove(struct platform_device *pdev)
 	struct meson_pcie *mp = platform_get_drvdata(pdev);
 
 	dw_pcie_host_deinit(&mp->pci.pp);
-	meson_pcie_power_off(mp);
 }
 
 static const struct of_device_id meson_pcie_of_match[] = {

-- 
2.43.0

