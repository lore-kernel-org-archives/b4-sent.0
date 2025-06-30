From: George Chan <gchan9527@gmail.com>
Date: Mon, 30 Jun 2025 15:56:54 +0800
Subject: [PATCH v4 5/6] iommu: qcom-smmu: Introduce sc7180 compatible
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-sc7180-android-boot-v4-5-24cdb50e860f@gmail.com>
References: <20250630-sc7180-android-boot-v4-0-24cdb50e860f@gmail.com>
In-Reply-To: <20250630-sc7180-android-boot-v4-0-24cdb50e860f@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, Simon Glass <sjg@chromium.org>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Lukasz Majewski <lukma@denx.de>, Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, gchan9527@gmail.com, 
 Vitalii Skorkin <nikroks@mainlining.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751270223; l=870;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=42TwfPn6+UwUrF0bHJRtbT/XxJmf4Tq0MSQfLwkdXQg=;
 b=GiDz7MYXn7i8SzFDqs7WyFRZUmuwyhFyN67T1uF+EFir0n68InKCOmuJzK18NWxLIDQbIESaP
 +FDx4n0MknlBn8d6af5VE/jpsRpFWmneLZNQNHKcjNE9QhG4dNbQF0d
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
index 2e51ce4f242..519e7f4e7b2 100644
--- a/drivers/iommu/qcom-hyp-smmu.c
+++ b/drivers/iommu/qcom-hyp-smmu.c
@@ -389,6 +389,7 @@ static struct iommu_ops qcom_smmu_ops = {
 
 static const struct udevice_id qcom_smmu500_ids[] = {
 	{ .compatible = "qcom,sdm845-smmu-500" },
+	{ .compatible = "qcom,sc7180-smmu-500" },
 	{ .compatible = "qcom,sc7280-smmu-500" },
 	{ .compatible = "qcom,smmu-500", },
 	{ /* sentinel */ }

-- 
2.43.0

