From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 04 Sep 2024 12:41:58 +0530
Subject: [PATCH v6 2/4] PCI: dwc: Always cache the maximum link speed value
 in dw_pcie::max_link_speed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-pci-qcom-gen4-stability-v6-2-ec39f7ae3f62@linaro.org>
References: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
In-Reply-To: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
To: Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Chuanhua Lei <lchuanhua@maxlinear.com>, 
 Marek Vasut <marek.vasut+renesas@gmail.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>
Cc: linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 imx@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-renesas-soc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 abel.vesa@linaro.org, johan+linaro@kernel.org, 
 Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2426;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=D8fhqlsKz3xyqSNMvnVSSeaKQj4RuRyuF4B9yBERg8c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBm2Ag+gHgv/70oSE6q/WC7SNywmP6sofcRgja3k
 ZSHRiTMBGeJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZtgIPgAKCRBVnxHm/pHO
 9WjuCACnCHbZaYumklhb1N/5rQObm+rKLZHjTx8nDFsA+BUdz3qBaZJ9G7cXIzxhtxrjWVrQgZ1
 KfykKJC4/hQxPZvtuDY7n20z04Q8yja6vmmY4rU4GPK88klgKPHZc/X8Bi3wsWCT4qTCzvhvEm5
 q2W8t/sySpwuMSyu4qnIgmIMtuydHUVs3FKbXcEZpE+ZfVvK4lhjk146BG1rPEOKfY7t5xajIEW
 cg2fx92lMu+4Ek/q6o+HhGNyqpEzTvumEwr0SDMdD1IO3uKAlj9pn8ORUEQ6SuleP+GZIHblIxx
 wXkdgvbLtCQ1YEtaF9thtq6Cjk8UgWZ5MWXjWEvVCJmCGAGu
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, dw_pcie::max_link_speed has a valid value only if the controller
driver restricts the maximum link speed in the driver or if the platform
does so in the devicetree using the 'max-link-speed' property.

But having the maximum supported link speed of the platform would be
helpful for the vendor drivers to configure any link specific settings.
So in the case of non-valid value in dw_pcie::max_link_speed, just cache
the hardware default value from Link Capability register.

While at it, let's also remove the 'max_link_speed' argument to the
dw_pcie_link_set_max_speed() function since the value can be retrieved
within the function.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-designware.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 86c49ba097c6..0704853daa85 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -687,16 +687,27 @@ void dw_pcie_upconfig_setup(struct dw_pcie *pci)
 }
 EXPORT_SYMBOL_GPL(dw_pcie_upconfig_setup);
 
-static void dw_pcie_link_set_max_speed(struct dw_pcie *pci, u32 max_link_speed)
+static void dw_pcie_link_set_max_speed(struct dw_pcie *pci)
 {
 	u32 cap, ctrl2, link_speed;
 	u8 offset = dw_pcie_find_capability(pci, PCI_CAP_ID_EXP);
 
 	cap = dw_pcie_readl_dbi(pci, offset + PCI_EXP_LNKCAP);
+
+	/*
+	 * Even if the platform doesn't want to limit the maximum link speed,
+	 * just cache the hardware default value so that the vendor drivers can
+	 * use it to do any link specific configuration.
+	 */
+	if (pci->max_link_speed < 0) {
+		pci->max_link_speed = FIELD_GET(PCI_EXP_LNKCAP_SLS, cap);
+		return;
+	}
+
 	ctrl2 = dw_pcie_readl_dbi(pci, offset + PCI_EXP_LNKCTL2);
 	ctrl2 &= ~PCI_EXP_LNKCTL2_TLS;
 
-	switch (pcie_link_speed[max_link_speed]) {
+	switch (pcie_link_speed[pci->max_link_speed]) {
 	case PCIE_SPEED_2_5GT:
 		link_speed = PCI_EXP_LNKCTL2_TLS_2_5GT;
 		break;
@@ -1058,8 +1069,7 @@ void dw_pcie_setup(struct dw_pcie *pci)
 {
 	u32 val;
 
-	if (pci->max_link_speed > 0)
-		dw_pcie_link_set_max_speed(pci, pci->max_link_speed);
+	dw_pcie_link_set_max_speed(pci);
 
 	/* Configure Gen1 N_FTS */
 	if (pci->n_fts[0]) {

-- 
2.25.1

