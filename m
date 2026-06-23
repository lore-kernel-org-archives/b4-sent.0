From: Esteban Urrutia <esteuwu@proton.me>
Date: Mon, 22 Jun 2026 20:54:28 -0400
Subject: [PATCH 7/8] phy: qcom: qmp-combo: Correct pre-emphasis table for
 QMP v4 DP PHYs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260622-sm8450-qol-v1-7-37e2ee8df9da@proton.me>
References: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
In-Reply-To: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782176157; l=777;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=R63hycbHvUFDnC1cHIBb7h07gA5W8fdx5mdFsG6A0Hc=;
 b=r3MLZtUkiD8mgYlKgmkuEcwMO18d1TmeuiMJv06QB6X1rg0/nZYY0pWJieUde234c4KbTtH4L
 7lpnsa42qcdDqLdn+u6bN6p+Vjlwb7oIe4/LSJRwg0drtzZimgV9mbC
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Comparing sm8350 and sm8450 tables, this seems to be typo.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
 drivers/phy/qualcomm/phy-qcom-qmp-combo.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-qmp-combo.c b/drivers/phy/qualcomm/phy-qcom-qmp-combo.c
index 9bd666ac2c49..5b278fd54a16 100644
--- a/drivers/phy/qualcomm/phy-qcom-qmp-combo.c
+++ b/drivers/phy/qualcomm/phy-qcom-qmp-combo.c
@@ -2108,7 +2108,7 @@ static const u8 qmp_dp_v4_pre_emphasis_hbr3_hbr2[4][4] = {
 static const u8 qmp_dp_v4_pre_emphasis_hbr_rbr[4][4] = {
 	{ 0x00, 0x0d, 0x14, 0x1a },
 	{ 0x00, 0x0e, 0x15, 0xff },
-	{ 0x00, 0x0d, 0xff, 0xff },
+	{ 0x00, 0x0e, 0xff, 0xff },
 	{ 0x03, 0xff, 0xff, 0xff }
 };
 

-- 
2.54.0

