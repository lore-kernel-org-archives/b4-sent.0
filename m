From: Demeter Barna <me@fromdisposition.org>
Date: Mon, 12 Oct 2026 06:04:13 +0000
Subject: [PATCH] iommu/arm-smmu-qcom: Add SM8350 MDSS compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261012-arm-smmu-qcom-sm8350-mdss-v1-1-deae44695301@fromdisposition.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw6CQAyF4VchXdtkpoi3VzEuhmnRmgzIVAwJ4
 d0ddHe+xfkXMMkqBpdqgSwfNR36Ar+rID5CfxdULgZydPDOE4ac0FKacIzDtk514zCxGZ5539V
 HZqImQPm/snQ6/9rX2982tU+J7y0I6/oFhuIVvn0AAAA=
X-Change-ID: 20261012-arm-smmu-qcom-sm8350-mdss-9d4f37dd225a
To: Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791785057; l=1459;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=g1QXs8w3o+qcZcGg/r4biOtnY2Etr8byKo19QjIIQdY=;
 b=rMMwu5/9HX4Syb5ShzURIreiL99EnXfdA0EEVWrjImfRhuJKBmFuA7eqgvYSj1mnJCdzstwSu
 zb58pWwpyyPAGu8/zwrsa8EmzhE/SHmMVNgL95MF1CERhwGoSFqN/jh
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SM8150, SM8250 and SM8450 MDSS are in the list of identity clients;
SM8350 looks to have been missed.

Without it, the framebuffer left by the bootloader takes unhandled
context faults (SID 0xc20) as soon as arm-smmu probes, and the panel
shows no picture.

Assisted-by: LLM
Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
Tested on a Razer Edge 5G, whose board support is not upstream yet:
without this patch there are 10 context faults and the panel stays
black; with it there are none and the picture is there. This is the
same change as d149c8b2c014 for SM8450.
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
base-commit: 2888520bdcbe0599cfc77b2fad8dc6c95505a3cb
change-id: 20261012-arm-smmu-qcom-sm8350-mdss-9d4f37dd225a

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

