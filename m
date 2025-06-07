From: George Chan <gchan9527@gmail.com>
Date: Sat, 07 Jun 2025 13:24:59 +0800
Subject: [PATCH v2 4/5] iommu: qcom-smmu: Introduce sc7180 compatible
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250607-sc7180-android-boot-v2-4-2df5d7f61124@gmail.com>
References: <20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com>
In-Reply-To: <20250607-sc7180-android-boot-v2-0-2df5d7f61124@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com, 
 Vitalii Skorkin <nikroks@mainlining.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749273923; l=870;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=jHr2VerS2shSVgdFBvM78HoeM11NXrop9lMSboNBekI=;
 b=cV8zKB8Vp9gIjNiPZ6RbBGb61AkJ/lXR1kKIhIJ6PUC1LPaUfLZdFHzOumc9069qzjCwas2ur
 e+RCY1ntKtiCTyCb23RVgFRYPrb0UDNNJEmGx29vOkdpDisw3cmbyef
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add basic compatible string for sc7180 family soc.

Signed-off-by: Vitalii Skorkin <nikroks@mainlining.org>
Co-developed-by: George Chan <gchan9527@gmail.com>
Signed-off-by: George Chan <gchan9527@gmail.com>
Reviewed-by: Casey Connolly <casey.connolly@linaro.org>
---
 drivers/iommu/qcom-hyp-smmu.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/qcom-hyp-smmu.c b/drivers/iommu/qcom-hyp-smmu.c
index c1b95bc8b8c..2a356613a26 100644
--- a/drivers/iommu/qcom-hyp-smmu.c
+++ b/drivers/iommu/qcom-hyp-smmu.c
@@ -388,6 +388,7 @@ static struct iommu_ops qcom_smmu_ops = {
 
 static const struct udevice_id qcom_smmu500_ids[] = {
 	{ .compatible = "qcom,sdm845-smmu-500" },
+	{ .compatible = "qcom,sc7180-smmu-500" },
 	{ .compatible = "qcom,sc7280-smmu-500" },
 	{ .compatible = "qcom,smmu-500", },
 	{ /* sentinel */ }

-- 
2.43.0

