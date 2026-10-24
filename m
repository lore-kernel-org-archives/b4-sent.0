From: Igor Velkov <iav@iav.lv>
Date: Sat, 24 Oct 2026 04:02:44 +0300
Subject: [PATCH RFC 2/2] PCI: rockchip-host: Hot-reset the endpoint before
 using the link
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-rockchip-pcie-resume-v1-2-58e54a5cf5f1@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5422; i=iav@iav.lv;
 h=from:subject:message-id; bh=JqNmsQpPl/FYQLmd44QeXU02W9GHIDITxGbAly7lXUc=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl3mLcK7pkcGBx9dmEJ+/NnLWdW/bvpvvmnb77qE01vc
 a7zl+4rdpSyMIhxMciKKbJMOKRxK2PJ1b/+HuYPYOawMoEMYeDiFICJXDBk+KdsOV9s7n9jlwtR
 b1Yd7HQ/O81Q02BlQXXb3DWyJxlVvj9mZNjcFXfszLJj3Es7Os3d/vwz/L7plk7yyZ9nQhK2PDx
 3r4UdAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a Kobol Helios64 the JMB585 sometimes trains the link but does not
answer config reads. On resume, a read in rockchip_pcie_rd_conf(),
called from pci_power_up(), ends in a synchronous external abort and
the kernel oopses. At probe, a config read during the bus scan ended in
an SError on 1 of 4 boots of v7.3-rc7.

After training, hot-reset the endpoint, hold the reset at least 2 ms as
pci_reset_secondary_bus() does, and wait for the link. Clear the AXI
link-down status (CDNS_PCIE_AT_LINKDOWN in the Cadence host driver),
then wait the 100 ms required after a Conventional Reset. Fail probe
and resume if the hot reset fails.

s2idle on v7.3-rc7 with the mainline DT and patch 1:

  sleep    without this patch    with it
  ~40 s    2 aborts / 30         0 / 100
  ~25 s    1 abort / 11          0 / 40, then 2 aborts in the next 3

After the hot reset the link came back in 2.8-2.9 ms in the good
cycles. In the last abort it came back in 25 ms, and the next config
read aborted. The other abort left no timing. Boots with the patch were
not counted.

Print how long the link took to come back. This explains the data
above and helps anyone who runs the code.

Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 drivers/pci/controller/pcie-rockchip-host.c | 59 +++++++++++++++++++++++++++++
 drivers/pci/controller/pcie-rockchip.h      |  4 ++
 2 files changed, 63 insertions(+)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index b4499fc3f90b..f75c2c8358f5 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -400,6 +400,57 @@ static int rockchip_pcie_init_port_retry(struct rockchip_pcie *rockchip)
 	return err;
 }
 
+/* Hot-reset the endpoint; *link_us: time until the link came back, 0 if not reset */
+static int rockchip_pcie_hot_reset(struct rockchip_pcie *rockchip, s64 *link_us)
+{
+	u32 status;
+	ktime_t start;
+	int err;
+
+	*link_us = 0;
+	rockchip_pcie_write(rockchip, PCIE_CLIENT_HOT_RESET_ASSERT,
+			    PCIE_CLIENT_HOT_RESET_CTRL);
+	err = readl_poll_timeout(rockchip->apb_base + PCIE_CLIENT_INT_STATUS,
+				 status, status & PCIE_CLIENT_INT_HOT_RST,
+				 100, 100 * USEC_PER_MSEC);
+	rockchip_pcie_write(rockchip, PCIE_CLIENT_INT_HOT_RST,
+			    PCIE_CLIENT_INT_STATUS);
+	/* Hold the reset at least 2 ms, as pci_reset_secondary_bus() does */
+	if (!err)
+		usleep_range(2000, 3000);
+	rockchip_pcie_write(rockchip, PCIE_CLIENT_HOT_RESET_DEASSERT,
+			    PCIE_CLIENT_HOT_RESET_CTRL);
+	if (err)
+		return err;
+
+	start = ktime_get();
+	err = readl_poll_timeout(rockchip->apb_base + PCIE_CLIENT_BASIC_STATUS1,
+				 status, PCIE_LINK_UP(status), 20,
+				 LINK_TRAIN_TIMEOUT);
+	*link_us = ktime_us_delta(ktime_get(), start);
+
+	/* Clear the AXI link-down status before config traffic, as the Cadence host driver does */
+	rockchip_pcie_write(rockchip, 0, PCIE_CORE_AXI_LINK_DOWN);
+
+	return err;
+}
+
+/* A JMB585 sometimes comes out of reset unable to answer config requests */
+static int rockchip_pcie_reset_endpoint(struct rockchip_pcie *rockchip)
+{
+	struct device *dev = rockchip->dev;
+	s64 link_us;
+	int err;
+
+	err = rockchip_pcie_hot_reset(rockchip, &link_us);
+	dev_info(dev, "hot reset: link back in %lld us, err %d\n", link_us, err);
+	if (err)
+		return err;
+
+	msleep(PCIE_RESET_CONFIG_WAIT_MS);
+	return 0;
+}
+
 static irqreturn_t rockchip_pcie_subsys_irq_handler(int irq, void *arg)
 {
 	struct rockchip_pcie *rockchip = arg;
@@ -908,6 +959,10 @@ static int rockchip_pcie_resume_noirq(struct device *dev)
 	if (err)
 		goto err_pcie_resume;
 
+	err = rockchip_pcie_reset_endpoint(rockchip);
+	if (err)
+		goto err_err_deinit_port;
+
 	err = rockchip_pcie_cfg_atu(rockchip);
 	if (err)
 		goto err_err_deinit_port;
@@ -965,6 +1020,10 @@ static int rockchip_pcie_probe(struct platform_device *pdev)
 	if (err)
 		goto err_vpcie;
 
+	err = rockchip_pcie_reset_endpoint(rockchip);
+	if (err)
+		goto err_deinit_port;
+
 	err = rockchip_pcie_init_irq_domain(rockchip);
 	if (err < 0)
 		goto err_deinit_port;
diff --git a/drivers/pci/controller/pcie-rockchip.h b/drivers/pci/controller/pcie-rockchip.h
index b5da15601b58..4509e044862b 100644
--- a/drivers/pci/controller/pcie-rockchip.h
+++ b/drivers/pci/controller/pcie-rockchip.h
@@ -47,6 +47,9 @@
 #define   PCIE_CLIENT_INT_IN_DEASSERT		HWORD_CLR_BIT(0x0002)
 #define   PCIE_CLIENT_INT_PEND_ST_PEND		HWORD_SET_BIT(0x0001)
 #define   PCIE_CLIENT_INT_PEND_ST_NORMAL	HWORD_CLR_BIT(0x0001)
+#define PCIE_CLIENT_HOT_RESET_CTRL	(PCIE_CLIENT_BASE + 0x18)
+#define   PCIE_CLIENT_HOT_RESET_ASSERT		HWORD_SET_BIT(0x0001)
+#define   PCIE_CLIENT_HOT_RESET_DEASSERT	HWORD_CLR_BIT(0x0001)
 #define PCIE_CLIENT_SIDE_BAND_STATUS	(PCIE_CLIENT_BASE + 0x20)
 #define   PCIE_CLIENT_PHY_ST			BIT(12)
 #define PCIE_CLIENT_DEBUG_OUT_0		(PCIE_CLIENT_BASE + 0x3c)
@@ -170,6 +173,7 @@
 #define PCIE_CORE_OB_REGION_ADDR1	(PCIE_CORE_AXI_CONF_BASE + 0x4)
 #define PCIE_CORE_OB_REGION_DESC0	(PCIE_CORE_AXI_CONF_BASE + 0x8)
 #define PCIE_CORE_OB_REGION_DESC1	(PCIE_CORE_AXI_CONF_BASE + 0xc)
+#define PCIE_CORE_AXI_LINK_DOWN		(PCIE_CORE_AXI_CONF_BASE + 0x824)
 
 #define PCIE_CORE_AXI_INBOUND_BASE	0xc00800
 #define PCIE_RP_IB_ADDR0		(PCIE_CORE_AXI_INBOUND_BASE + 0x0)

-- 
2.43.0

