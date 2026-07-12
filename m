From: Esteban Urrutia <esteuwu@proton.me>
Date: Sat, 11 Jul 2026 23:14:01 -0400
Subject: [PATCH v2] iommu/arm-smmu-qcom: Add SM8450 MDSS compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-sm8450-qol-smmu-v2-1-41a6fba41c3e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02NQQ6CMBREr0L+2pq2CAVW3sOwQPqRGqHYD42G9
 O4W2Libl8y8WYHQGSSokhUcekPGjhHkKYG2b8YHMqMjg+Qy50oIRkNxyTh721eMw8IyhboUqHl
 aKoiryWFnPrvxVh9My/2J7bxptkZvaLbuu196sfUOey7lv90LxlmqUCIWuit1c52cne14HhDqE
 MIPrXS1FbsAAAA=
X-Change-ID: 20260711-sm8450-qol-smmu-57ed91ed0397
To: Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783826044; l=1419;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=IfJaejqIoPsz18N/gqtzvEjuLMyEPDB5DAuVkODkmwc=;
 b=UvSUTz/MEMZyJa7vizKpKWIYxkiZgRxVdBJ+9EKLTBhRtjyn7HLNnNYv7ncQG/5rvMzEMVbEi
 1LpVyl+XTlpB1FA0BgmVY6yPnRyCCrkkSS8bu45gFrluIVoQYEDttnj
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for the MDSS client on the Snapdragon 8 Gen 1 so it can
be properly configured by the IOMMU driver.

Otherwise, there is an unhandled context fault, because the framebuffer is
already configured in UEFI.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
This patch allows the MDSS driver to properly function on SM8450 based
devices.
---
Changes in v2:
- Split series in subseries (dispcc, dts, qmp, smmu)
- Link to v1: https://patch.msgid.link/20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me
---
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
index e2c914fccd6f..795e8ec7e8fa 100644
--- a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
+++ b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
@@ -425,6 +425,7 @@ static const struct of_device_id qcom_smmu_client_of_match[] __maybe_unused = {
 	{ .compatible = "qcom,sm6375-mdss" },
 	{ .compatible = "qcom,sm8150-mdss" },
 	{ .compatible = "qcom,sm8250-mdss" },
+	{ .compatible = "qcom,sm8450-mdss" },
 	{ .compatible = "qcom,x1e80100-mdss" },
 	{ }
 };

---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260711-sm8450-qol-smmu-57ed91ed0397

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

