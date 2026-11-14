From: Demeter Barna <me@fromdisposition.org>
Date: Sat, 14 Nov 2026 02:22:00 +0000
Subject: [PATCH 6/9] iommu: qcom-hyp-smmu: Add SM8350 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-sm8350-support-v1-6-414271f59474@fromdisposition.org>
References: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
In-Reply-To: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=806;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=jt5v3+ugvdaP8Z/aaDMUW0xCt7He4rvF+Tbjb8GneYA=;
 b=nkHXPk1DxifdKSI23UJdNGwRyOHZobyOIh66H6Dtr14bOfhvBX6NXMg4MYE+l13CqI/WAsIYa
 qt2XTG2DvlsCnvGCNZc9t8PPYh/FeIO7+W8MvW2QdEgcemD03Cnd8S0
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sm8350.dtsi describes the apps SMMU as "qcom,sm8350-smmu-500",
"arm,mmu-500", which nothing matches, so every device with iommus fails
to probe.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 drivers/iommu/qcom-hyp-smmu.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/iommu/qcom-hyp-smmu.c b/drivers/iommu/qcom-hyp-smmu.c
index 5b37c21f66..bafc34fcf1 100644
--- a/drivers/iommu/qcom-hyp-smmu.c
+++ b/drivers/iommu/qcom-hyp-smmu.c
@@ -392,6 +392,7 @@ static const struct udevice_id qcom_smmu500_ids[] = {
 	{ .compatible = "qcom,sc7280-smmu-500" },
 	{ .compatible = "qcom,sdm845-smmu-500" },
 	{ .compatible = "qcom,sm6350-smmu-500" },
+	{ .compatible = "qcom,sm8350-smmu-500" },
 	{ .compatible = "qcom,smmu-500", },
 	{ /* sentinel */ }
 };

-- 
2.53.0

