From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 25 Nov 2026 11:17:43 +0100
Subject: [PATCH 3/4] PCI: qcom: Recalibrate the PHY on temperature drift
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-glymur-thermal-fix-v1-3-b93a9feae156@oss.qualcomm.com>
References: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
In-Reply-To: <20261125-glymur-thermal-fix-v1-0-b93a9feae156@oss.qualcomm.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=10105;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=TFDAjWR+23MEVOtOz9p+bSn13D7ZIySlWyk2j+uTRNY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBrBrXOmi8rNoSC+/cMC8Il9mN6QUNurM2aYbd87
 OBJgYS1ngaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCawa1zgAKCRBVnxHm/pHO
 9U0+B/9BJWbKXXwXIDmBwkkXOpabXhk7HlSvaZAg4dTOXl9j/dwwEDvqrQ9StcbW0QgmIMazPsK
 LxTySSC+unrVMVJPQXi0WOMJwn00RBlIDgQQylVnjFbBn7yVCmsq6vAO/Yd5RXUbWJMl5MmyJwu
 VUCHuzQJWH0y1Fs094Wpg3GvnI89qi1qP/0LbQdiwtdaaUd560NTtt1PJqaHSTi3kdLwCVt4CwW
 UJQtgIw3nBzHoFHdmXqRvozZtITW95xgbQfRb8L6+aR01pGbEEz+PZuOog22gAyr4MoBD1x8ppG
 TQBAlOO8yV1RRMDrR8+frdTjz/KYUp0V/RcLSeFVhXsQx5gk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some PCIe PHY instances on SoCs like Glymur benefit from periodic
recalibration to compensate for temperature-related drift and maintain
stable link operation. Otherwise there is a potential for a link drop. The
recalibration is performed by the hardware during a PCIe link speed
switch, which the driver initiates once the temperature change on a
polled sensor exceeds the defined threshold. For this purpose, the driver
needs to know which sensors track the PHY temperature and the drift
temperature.

First, get the list of thermal zones and the drift temperature by parsing
the 'qcom,pcie-recalibration-thermal-zones' DT property. Then record the
current temperature of each zone, which is the reference the drift gets
measured against. Then schedule a delayed worker thread 'recalib_work' for
every 5s to monitor the temperature drift and initiate the recalibration if
the drift happens.

qcom_pcie_recalib_work() does the actual work of reading the sensor
temperatures and performing recalibration when required. The worker
compares every zone against the reference recorded for it, and if none of
them has drifted far enough, it skips the recalibration. Otherwise the
worker performs the link speed switching by scaling down the Target Link
Speed to 2.5 GT/s and then restoring the original Target Link Speed. This
forces the link to run Equalization again, which recalibrates the PHY
against the current temperature, thereby maintaining stable link
operation. Equalization only runs on a speed change to 8.0 GT/s or above.

Finally, the recalibration has to be stopped across system suspend as it
touches config space, which is not reachable once the interconnect paths
are powered down. So cancel the work in the noirq suspend callback and
rearm the recalib worker on resume.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-qcom.c | 224 +++++++++++++++++++++++++++++++++
 1 file changed, 224 insertions(+)

diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index d903f10211c2..fb11718cea39 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -8,6 +8,7 @@
  * Author: Stanimir Varbanov <svarbanov@mm-sol.com>
  */
 
+#include <linux/atomic.h>
 #include <linux/clk.h>
 #include <linux/crc8.h>
 #include <linux/debugfs.h>
@@ -34,6 +35,7 @@
 #include <linux/regulator/consumer.h>
 #include <linux/reset.h>
 #include <linux/slab.h>
+#include <linux/thermal.h>
 #include <linux/types.h>
 #include <linux/units.h>
 
@@ -314,6 +316,18 @@ struct qcom_pcie_port {
 	struct list_head perst;
 };
 
+/**
+ * struct qcom_pcie_recalib_zone - thermal zone used for recalibration
+ * @tz: thermal zone whose sensor tracks the PHY temperature
+ * @drift: drift this zone may accumulate before the PHY needs recalibrating
+ * @ref: temperature @tz reported after the last recalibration
+ */
+struct qcom_pcie_recalib_zone {
+	struct thermal_zone_device *tz;
+	int drift;
+	int ref;
+};
+
 struct qcom_pcie {
 	struct dw_pcie *pci;
 	void __iomem *parf;			/* DT parf */
@@ -328,6 +342,11 @@ struct qcom_pcie {
 	int global_irq;
 	bool use_pm_opp;
 	struct mutex reset_lock;
+
+	struct qcom_pcie_recalib_zone *recalib_zones;
+	unsigned int recalib_num_zones;
+	struct workqueue_struct *recalib_wq;
+	struct delayed_work recalib_work;
 };
 
 #define to_qcom_pcie(x)		dev_get_drvdata((x)->dev)
@@ -1839,6 +1858,197 @@ static void qcom_pcie_icc_opp_update(struct qcom_pcie *pcie)
 	}
 }
 
+static int qcom_pcie_recalib_update_ref_temp(struct qcom_pcie *pcie)
+{
+	unsigned int i;
+	int temp, ret;
+
+	for (i = 0; i < pcie->recalib_num_zones; i++) {
+		struct qcom_pcie_recalib_zone *zone = &pcie->recalib_zones[i];
+
+		ret = thermal_zone_get_temp(zone->tz, &temp);
+		if (ret)
+			return ret;
+
+		zone->ref = temp;
+	}
+
+	return 0;
+}
+
+#define QCOM_PCIE_RECALIB_INTERVAL_MS	5000
+
+static void qcom_pcie_recalib_arm_worker(struct qcom_pcie *pcie)
+{
+	if (!pcie->recalib_wq)
+		return;
+
+	queue_delayed_work(pcie->recalib_wq, &pcie->recalib_work,
+			   msecs_to_jiffies(QCOM_PCIE_RECALIB_INTERVAL_MS));
+}
+
+static void qcom_pcie_recalib_work(struct work_struct *work)
+{
+	struct qcom_pcie *pcie = container_of(work, struct qcom_pcie,
+					      recalib_work.work);
+	struct dw_pcie_rp *pp = &pcie->pci->pp;
+	struct device *dev = pcie->pci->dev;
+	struct pci_dev *port __free(pci_dev_put) = pci_get_slot(pp->bridge->bus, PCI_DEVFN(0, 0));
+	enum pci_bus_speed speed;
+	bool drifted = false;
+	unsigned int i;
+	u16 lnkctl2;
+	int temp, ret;
+
+	if (!port || !port->subordinate)
+		goto rearm;
+
+	scoped_guard(mutex, &pcie->reset_lock) {
+		for (i = 0; i < pcie->recalib_num_zones; i++) {
+			struct qcom_pcie_recalib_zone *zone = &pcie->recalib_zones[i];
+
+			ret = thermal_zone_get_temp(zone->tz, &temp);
+			if (ret) {
+				dev_err(dev, "Failed to read %s: %d\n",
+					thermal_zone_device_type(zone->tz), ret);
+				continue;
+			}
+
+			if (abs(temp - zone->ref) >= zone->drift)
+				drifted = true;
+		}
+
+		/* No zone has drifted far enough to need a recalibration */
+		if (!drifted)
+			break;
+
+		ret = pcie_capability_read_word(port, PCI_EXP_LNKCTL2, &lnkctl2);
+		if (ret != PCIBIOS_SUCCESSFUL)
+			break;
+
+		speed = PCIE_LNKCTL2_TLS2SPEED(lnkctl2);
+		if (!pcie_valid_speed(speed))
+			break;
+
+		/*
+		 * Equalization only runs at 8.0 GT/s and above, so a slower
+		 * link has nothing to recalibrate.
+		 */
+		if (speed >= PCIE_SPEED_8_0GT) {
+			ret = pcie_set_target_speed(port, PCIE_SPEED_2_5GT, true);
+			if (ret)
+				dev_err(dev, "Failed to step down the link speed: %d\n", ret);
+
+			/*
+			 * The device below may not be able to train to the
+			 * original Target Link Speed, which is reported as
+			 * -EAGAIN even though the speed was restored.
+			 */
+			ret = pcie_set_target_speed(port, speed, true);
+			if (ret && ret != -EAGAIN)
+				dev_err(dev, "Failed to restore the link speed: %d\n", ret);
+		}
+
+		/*
+		 * Update the reference temperature of every zone and not just
+		 * of the one that drifted, so all of them measure their next
+		 * drift from the same point in time.
+		 */
+		ret = qcom_pcie_recalib_update_ref_temp(pcie);
+		if (ret)
+			dev_err(dev, "Failed to update the reference temperature: %d\n", ret);
+	}
+
+rearm:
+	qcom_pcie_recalib_arm_worker(pcie);
+}
+
+#define QCOM_PCIE_RECALIB_ZONE_CELLS	2
+
+static int qcom_pcie_recalib_get_zones(struct qcom_pcie *pcie)
+{
+	const char *prop = "qcom,pcie-recalibration-thermal-zones";
+	struct device *dev = pcie->pci->dev;
+	struct of_phandle_args args;
+	unsigned int i, num_zones;
+	int ret;
+
+	ret = of_count_phandle_with_args(dev->of_node, prop, NULL);
+	if (ret == -ENOENT)
+		return 0;
+	if (ret < 0)
+		return ret;
+
+	if (!IS_ENABLED(CONFIG_THERMAL_OF))
+		return dev_err_probe(dev, -ENODEV,
+				     "%s requires CONFIG_THERMAL_OF\n", prop);
+
+	num_zones = ret / QCOM_PCIE_RECALIB_ZONE_CELLS;
+
+	pcie->recalib_zones = devm_kcalloc(dev, num_zones,
+					   sizeof(*pcie->recalib_zones), GFP_KERNEL);
+	if (!pcie->recalib_zones)
+		return -ENOMEM;
+
+	for (i = 0; i < num_zones; i++) {
+		struct qcom_pcie_recalib_zone *zone = &pcie->recalib_zones[i];
+		struct thermal_zone_device *tz;
+
+		ret = of_parse_phandle_with_fixed_args(dev->of_node, prop,
+						       QCOM_PCIE_RECALIB_ZONE_CELLS - 1,
+						       i, &args);
+		if (ret)
+			return ret;
+
+		tz = thermal_zone_get_zone_by_node(args.np);
+		of_node_put(args.np);
+		if (IS_ERR(tz))
+			return PTR_ERR(tz) == -ENODEV ? -EPROBE_DEFER : PTR_ERR(tz);
+
+		zone->tz = tz;
+		zone->drift = args.args[0];
+	}
+
+	pcie->recalib_num_zones = num_zones;
+
+	return 0;
+}
+
+static void qcom_pcie_recalib_deinit(void *data)
+{
+	struct qcom_pcie *pcie = data;
+
+	cancel_delayed_work_sync(&pcie->recalib_work);
+	destroy_workqueue(pcie->recalib_wq);
+}
+
+static int qcom_pcie_recalib_init(struct qcom_pcie *pcie)
+{
+	struct device *dev = pcie->pci->dev;
+	int ret;
+
+	if (!pcie->recalib_num_zones)
+		return 0;
+
+	pcie->recalib_wq = alloc_workqueue("pcie-recalib/%s",
+					   WQ_UNBOUND | WQ_HIGHPRI | WQ_MEM_RECLAIM,
+					   0, dev_name(dev));
+	if (!pcie->recalib_wq)
+		return -ENOMEM;
+
+	INIT_DELAYED_WORK(&pcie->recalib_work, qcom_pcie_recalib_work);
+
+	ret = qcom_pcie_recalib_update_ref_temp(pcie);
+	if (ret) {
+		destroy_workqueue(pcie->recalib_wq);
+		return dev_err_probe(dev, ret, "Failed to update the reference temperature\n");
+	}
+
+	qcom_pcie_recalib_arm_worker(pcie);
+
+	return devm_add_action_or_reset(dev, qcom_pcie_recalib_deinit, pcie);
+}
+
 static int qcom_pcie_set_max_opp(struct device *dev)
 {
 	unsigned long max_freq = ULONG_MAX;
@@ -2370,6 +2580,10 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 			goto err_pm_runtime_put;
 	}
 
+	ret = qcom_pcie_recalib_get_zones(pcie);
+	if (ret)
+		goto err_pm_runtime_put;
+
 	ret = pcie->cfg->ops->get_resources(pcie);
 	if (ret)
 		goto err_pm_runtime_put;
@@ -2430,6 +2644,10 @@ static int qcom_pcie_probe(struct platform_device *pdev)
 
 	qcom_pcie_icc_opp_update(pcie);
 
+	ret = qcom_pcie_recalib_init(pcie);
+	if (ret)
+		goto err_host_deinit;
+
 	if (pcie->mhi)
 		qcom_pcie_init_debugfs(pcie);
 
@@ -2464,6 +2682,10 @@ static int qcom_pcie_suspend_noirq(struct device *dev)
 	if (!pcie)
 		return 0;
 
+	/* Recalibration touches config space, so it must not run past here */
+	if (pcie->recalib_wq)
+		cancel_delayed_work_sync(&pcie->recalib_work);
+
 	ret = dw_pcie_suspend_noirq(pcie->pci);
 	if (ret)
 		return ret;
@@ -2575,6 +2797,8 @@ static int qcom_pcie_resume_noirq(struct device *dev)
 
 	qcom_pcie_icc_opp_update(pcie);
 
+	qcom_pcie_recalib_arm_worker(pcie);
+
 	return 0;
 disable_icc_mem:
 	icc_disable(pcie->icc_mem);

-- 
2.43.0

