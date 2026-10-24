From: Igor Velkov <iav@iav.lv>
Date: Sat, 24 Oct 2026 04:02:43 +0300
Subject: [PATCH RFC 1/2] PCI: rockchip-host: Retry link training that times
 out
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-rockchip-pcie-resume-v1-1-58e54a5cf5f1@iav.lv>
References: <20261024-rockchip-pcie-resume-v1-0-58e54a5cf5f1@iav.lv>
In-Reply-To: <20261024-rockchip-pcie-resume-v1-0-58e54a5cf5f1@iav.lv>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: Rob Herring <robh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2899; i=iav@iav.lv;
 h=from:subject:message-id; bh=XyiyrHT+pm4QSQTgMimlGl6CYo9QtiIPmsWqK8gJ4SM=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl3mLfkvz242aLCc9kGMaUY60fpTxlnm+nuqd7PImudz
 zGF7556RykLgxgXg6yYIsuEQxq3MpZc/evvYf4AZg4rE8gQBi5OAZiI4CRGhjvf9A4u3tt4JNBi
 2qysDcdeC+u/XX/soP6jr8vXf/hZ6nuNkWFtyEdT+bgjFXO5zrGdSjbXjDS2Y66bwXex9P81rY/
 md1gB
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a Kobol Helios64 the JMB585 SATA controller sometimes does not train
the link on resume from s2idle. The 500 ms poll times out and
resume_noirq() returns -ETIMEDOUT. On v7.3-rc7 with the mainline DT
this happened in the 14th of 14 cycles, and the system did not resume.

When training times out, bring the port up again, at most twice. Each
attempt initializes the PHYs again and, where PERST# is wired, holds it
low for at least 100 ms. Without an endpoint, probe now gives up after
three attempts, in about 2.1 s instead of 0.7 s.

Print the LTSSM state with the timeout message.

With the patch, one such timeout showed LTSSM 0x10, and the first retry
trained the link.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/pci/controller/pcie-rockchip-host.c | 29 ++++++++++++++++++++++++++---
 1 file changed, 26 insertions(+), 3 deletions(-)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 5b071bdc4f90..b4499fc3f90b 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -325,7 +325,10 @@ static int rockchip_pcie_host_init_port(struct rockchip_pcie *rockchip)
 				 status, PCIE_LINK_UP(status), 20,
 				 500 * USEC_PER_MSEC);
 	if (err) {
-		dev_err(dev, "PCIe link training gen1 timeout!\n");
+		status = rockchip_pcie_read(rockchip, PCIE_CLIENT_DEBUG_OUT_0) &
+			 PCIE_CLIENT_DEBUG_LTSSM_MASK;
+		dev_err(dev, "PCIe link training gen1 timeout! (LTSSM %#x)\n",
+			status);
 		goto err_power_off_phy;
 	}
 
@@ -377,6 +380,26 @@ static int rockchip_pcie_host_init_port(struct rockchip_pcie *rockchip)
 	return err;
 }
 
+#define ROCKCHIP_PCIE_INIT_RETRIES	2
+
+/* Pulse PERST# and train again when the link does not come up */
+static int rockchip_pcie_init_port_retry(struct rockchip_pcie *rockchip)
+{
+	struct device *dev = rockchip->dev;
+	int i, err;
+
+	for (i = 0; ; i++) {
+		err = rockchip_pcie_host_init_port(rockchip);
+		if (err != -ETIMEDOUT || i == ROCKCHIP_PCIE_INIT_RETRIES)
+			break;
+		dev_info(dev, "link training retry %d\n", i + 1);
+	}
+
+	if (!err && i)
+		dev_info(dev, "link up after %d retries\n", i);
+	return err;
+}
+
 static irqreturn_t rockchip_pcie_subsys_irq_handler(int irq, void *arg)
 {
 	struct rockchip_pcie *rockchip = arg;
@@ -881,7 +904,7 @@ static int rockchip_pcie_resume_noirq(struct device *dev)
 	if (err)
 		goto err_disable_0v9;
 
-	err = rockchip_pcie_host_init_port(rockchip);
+	err = rockchip_pcie_init_port_retry(rockchip);
 	if (err)
 		goto err_pcie_resume;
 
@@ -938,7 +961,7 @@ static int rockchip_pcie_probe(struct platform_device *pdev)
 		goto err_set_vpcie;
 	}
 
-	err = rockchip_pcie_host_init_port(rockchip);
+	err = rockchip_pcie_init_port_retry(rockchip);
 	if (err)
 		goto err_vpcie;
 

-- 
2.43.0

