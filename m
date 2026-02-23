From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Mon, 23 Feb 2026 13:32:52 +0530
Subject: [PATCH v3 1/4] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260223-qcom-ice-fix-v3-1-6ca5846329f7@oss.qualcomm.com>
References: <20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com>
In-Reply-To: <20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Abel Vesa <abelvesa@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4411;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=TpQjQh0YL/KxaPzHttAt0v5EwEXDrjcHE26RHpIWR1Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnAmt+OqW5W1ojr/CHa44/Y3EkWD75xwuAoD55
 l1O/+nAhTCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZwJrQAKCRBVnxHm/pHO
 9WsdB/47B6A4ppKmOIhFjWRIbNVMqY5407U61QnPN4p0d2kx4gyXSF0aSz/qcKyeu9dE4RPFGc/
 l4rlkkDqG/ry2+phiFxz+r85quTl+7U6sxXyiis4JIMaFUqHJpDxf92E5NpHGRaQGcH23L4VJTL
 H61CeOiNKZwcACUDGYl/qfPYhXE6PFmm9d5tdBtyRMqkMKD/+R1IUNLrfmIOzQvvKm7qBSmrWas
 f42QoOGcIM31oY+HaXxZF2reXLrGIITebMsS7lVkMclsqNRS5RTELVGyMO3/RSRy5IHri0JYDtS
 AVVUa0XWgNLCa3cs7zUioSPdWcZQf+Xi3CbGMo9ZgmYwQNme
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current platform driver design causes probe ordering races with
consumers (UFS, eMMC) due to ICE's dependency on SCM firmware calls. If ICE
probe fails (missing ICE SCM or DT registers), devm_of_qcom_ice_get() loops
with -EPROBE_DEFER, leaving consumers non-functional even when ICE should
be gracefully disabled. devm_of_qcom_ice_get() doesn't know if the ICE
driver probe has failed due to above reasons or it is waiting for the SCM
driver.

Moreover, there is no devlink dependency between ICE and consumer drivers
as 'qcom,ice' is not considered as a DT 'supplier'. So the consumer drivers
have no idea of when the ICE driver is going to probe.

To address these issues, introduce a global ice_handle to store the valid
ICE handle pointer, and set during successful ICE driver probe. On probe
failure, set it to an error pointer and propagate the error from
of_qcom_ice_get().

Additionally, add a global ice_mutex to synchronize qcom_ice_probe() and
of_qcom_ice_get().

Note that this change only fixes the standalone ICE DT node bindings and
not the ones with 'ice' range embedded in the consumer nodes, where there
is no issue.

Cc: <stable@vger.kernel.org> # 6.4
Fixes: 2afbf43a4aec ("soc: qcom: Make the Qualcomm UFS/SDCC ICE a dedicated driver")
Reported-by: Sumit Garg <sumit.garg@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/soc/qcom/ice.c | 44 +++++++++++++++++++++++++++-----------------
 1 file changed, 27 insertions(+), 17 deletions(-)

diff --git a/drivers/soc/qcom/ice.c b/drivers/soc/qcom/ice.c
index b203bc685cad..3c3c189e24f9 100644
--- a/drivers/soc/qcom/ice.c
+++ b/drivers/soc/qcom/ice.c
@@ -113,6 +113,9 @@ struct qcom_ice {
 	u8 hwkm_version;
 };
 
+static DEFINE_MUTEX(ice_mutex);
+static struct qcom_ice *ice_handle;
+
 static bool qcom_ice_check_supported(struct qcom_ice *ice)
 {
 	u32 regval = qcom_ice_readl(ice, QCOM_ICE_REG_VERSION);
@@ -608,7 +611,6 @@ static struct qcom_ice *qcom_ice_create(struct device *dev,
 static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 {
 	struct platform_device *pdev = to_platform_device(dev);
-	struct qcom_ice *ice;
 	struct resource *res;
 	void __iomem *base;
 	struct device_link *link;
@@ -631,6 +633,22 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 		return qcom_ice_create(&pdev->dev, base);
 	}
 
+	guard(mutex)(&ice_mutex);
+
+	/*
+	 * If ice_handle is NULL, then it means the ICE driver is not probed
+	 * yet. So return -EPROBE_DEFER to let the client try later.
+	 */
+	if (!ice_handle)
+		return ERR_PTR(-EPROBE_DEFER);
+
+	/*
+	 * If ice_handle has error code, then it means the ICE driver has probe
+	 * failed. So return the handle for the client to digest it.
+	 */
+	if (IS_ERR(ice_handle))
+		return ice_handle;
+
 	/*
 	 * If the consumer node does not provider an 'ice' reg range
 	 * (legacy DT binding), then it must at least provide a phandle
@@ -647,24 +665,16 @@ static struct qcom_ice *of_qcom_ice_get(struct device *dev)
 		return ERR_PTR(-EPROBE_DEFER);
 	}
 
-	ice = platform_get_drvdata(pdev);
-	if (!ice) {
-		dev_err(dev, "Cannot get ice instance from %s\n",
-			dev_name(&pdev->dev));
-		platform_device_put(pdev);
-		return ERR_PTR(-EPROBE_DEFER);
-	}
-
 	link = device_link_add(dev, &pdev->dev, DL_FLAG_AUTOREMOVE_SUPPLIER);
 	if (!link) {
 		dev_err(&pdev->dev,
 			"Failed to create device link to consumer %s\n",
 			dev_name(dev));
 		platform_device_put(pdev);
-		ice = ERR_PTR(-EINVAL);
+		return ERR_PTR(-EINVAL);
 	}
 
-	return ice;
+	return ice_handle;
 }
 
 static void qcom_ice_put(const struct qcom_ice *ice)
@@ -716,20 +726,20 @@ EXPORT_SYMBOL_GPL(devm_of_qcom_ice_get);
 
 static int qcom_ice_probe(struct platform_device *pdev)
 {
-	struct qcom_ice *engine;
 	void __iomem *base;
 
+	guard(mutex)(&ice_mutex);
+
 	base = devm_platform_ioremap_resource(pdev, 0);
 	if (IS_ERR(base)) {
 		dev_warn(&pdev->dev, "ICE registers not found\n");
+		ice_handle = base;
 		return PTR_ERR(base);
 	}
 
-	engine = qcom_ice_create(&pdev->dev, base);
-	if (IS_ERR(engine))
-		return PTR_ERR(engine);
-
-	platform_set_drvdata(pdev, engine);
+	ice_handle = qcom_ice_create(&pdev->dev, base);
+	if (IS_ERR(ice_handle))
+		return PTR_ERR(ice_handle);
 
 	return 0;
 }

-- 
2.51.0

