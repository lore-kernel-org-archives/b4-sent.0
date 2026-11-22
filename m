From: Suyuan Wang <shyckless@gmail.com>
Date: Sun, 22 Nov 2026 10:11:52 +0000
Subject: [PATCH] iommu/qcom: Disable clocks if restoring the secure config
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-qcom-iommu-v1-1-ecb20a28871f@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOe/AmsC/yXMTQ5AMBBA4avIrDXR8RtXEQtqMJIqLSIRd1csv
 8V7FziyTA7K4AJLBzs2s4cMA1BjMw8kuPMGjDCTElGsymjBRutdYJLHqsAO0xTBB4ulns9vVtW
 /3d5OpLb3APf9AM6McwVuAAAA
X-Change-ID: 20261122-qcom-iommu-2473c82d2552
To: joro@8bytes.org, will@kernel.org, robin.clark@oss.qualcomm.com
Cc: iommu@lists.linux.dev, robin.murphy@arm.com, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795342312; l=1475;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=1Eskb3u6fGizPUm16aNFvrkib/eJ2zFG+/IzmSV4X/Y=;
 b=ZOGKdTHhmGOSbeG4MiNOD9O4UG/bQnmgXpNcWMIuhzXL6CbNW60fDSSxuqAPYbf+CxdaRHuqT
 bUCoNBgV+eAA5fWSVT4jLwsfiqxAeW3ig/BT3bfrHFybV/AwxRrQ6hQ
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

qcom_iommu_resume() enables the clocks and then, for an IOMMU with a
power domain, calls qcom_scm_restore_sec_cfg(). If that call fails, the
error is returned but the clocks stay enabled. The PM core then treats
the device as still suspended, so qcom_iommu_suspend() will not run to
turn them off.

Disable the clocks again when qcom_scm_restore_sec_cfg() fails.

Found with a static analysis tool and checked by hand.

Fixes: 268dd4edb748 ("iommu/qcom: restore IOMMU state if needed")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Compile tested on arm64 (W=1). I don't have the hardware.
---
 drivers/iommu/arm/arm-smmu/qcom_iommu.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/iommu/arm/arm-smmu/qcom_iommu.c b/drivers/iommu/arm/arm-smmu/qcom_iommu.c
index 96903cd9cfc2..52bcb8cf46b1 100644
--- a/drivers/iommu/arm/arm-smmu/qcom_iommu.c
+++ b/drivers/iommu/arm/arm-smmu/qcom_iommu.c
@@ -898,8 +898,11 @@ static int __maybe_unused qcom_iommu_resume(struct device *dev)
 	if (ret < 0)
 		return ret;
 
-	if (dev->pm_domain)
-		return qcom_scm_restore_sec_cfg(qcom_iommu->sec_id, 0);
+	if (dev->pm_domain) {
+		ret = qcom_scm_restore_sec_cfg(qcom_iommu->sec_id, 0);
+		if (ret)
+			clk_bulk_disable_unprepare(CLK_NUM, qcom_iommu->clks);
+	}
 
 	return ret;
 }



