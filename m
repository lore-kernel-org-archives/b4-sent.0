From: Demeter Barna <me@fromdisposition.org>
Date: Fri, 27 Nov 2026 15:09:10 +0000
Subject: [PATCH v2] iommu/arm-smmu-qcom: Add SM8350 MDSS compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-arm-smmu-qcom-sm8350-mdss-v2-1-dad015f87aa2@fromdisposition.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OQQ6CMBBFr0K6dkxbCoor72FcVDpATUpxBogJ4
 e62egF385L/359NMJJHFpdiE4SrZx/HBPpQiHawY4/gXWKhpa6VVBosBeAQFni1MV/nspIQHDM
 0znTlyTmtKytSfyLs/Pvrvt1/zMvjie2chTnRUVLMA6H9d2NVoMChRWPqpiqlumaH8zxF9nP6/
 RipF/v+Aacf9bHYAAAA
X-Change-ID: 20261012-arm-smmu-qcom-sm8350-mdss-9d4f37dd225a
To: Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795792194; l=1791;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=BVU49xzmqJjxmH+k6PMmulmhXXlj79Xhc52D5bfuUbk=;
 b=YbEWNyPc8BUkUkaGUJdU/Zak+9zk3D1uiiv/GYOKJW8JIoxTOd8jHloFEXknVQJcyViNDFhOz
 hyuagtPMO1jBBM8eeATMF8dWws+e2b8wX+864v/hd8xzjpA3al/Whd7
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8150, SM8250 and SM8450 MDSS are in the list of identity clients;
SM8350 looks to have been missed.

Without it, the framebuffer left by the bootloader takes unhandled
context faults (SID 0xc20) as soon as arm-smmu probes, and the panel
shows no picture.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
Changes in v2:
- Dropped the Assisted-by trailer.
- Rebased on next-20261126.
- Cc Konrad, who reviewed the SM8450 and SM8550 entries.
- Link to v1: https://patch.msgid.link/20261012-arm-smmu-qcom-sm8350-mdss-v1-1-deae44695301@fromdisposition.org

Tested on a Razer Edge 5G (SM8350): without this patch there are 10
context faults and the panel stays black; with it there are none and
the picture is there. An AI assistant pointed out that SM8350 was
missing from this list.

This one is important for SM8350: without it the display does not come
up at all. Thanks for having a look!
---
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
index 795e8ec7e..3dd8335c4 100644
--- a/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
+++ b/drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c
@@ -425,6 +425,7 @@ static const struct of_device_id qcom_smmu_client_of_match[] __maybe_unused = {
 	{ .compatible = "qcom,sm6375-mdss" },
 	{ .compatible = "qcom,sm8150-mdss" },
 	{ .compatible = "qcom,sm8250-mdss" },
+	{ .compatible = "qcom,sm8350-mdss" },
 	{ .compatible = "qcom,sm8450-mdss" },
 	{ .compatible = "qcom,x1e80100-mdss" },
 	{ }

---
base-commit: a9c48428cbd8d96b26f92631d0db6f8519c5fcc5
change-id: 20261012-arm-smmu-qcom-sm8350-mdss-9d4f37dd225a

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

