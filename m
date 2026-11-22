From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:25 +0000
Subject: [PATCH 2/3] media: qcom: camss: Vote interconnect bandwidth on
 SDM845
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-camss-sdm845-icc-v1-2-0671ef770fd0@enser.io>
References: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
In-Reply-To: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324405; l=2685;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=OGRKEtq1Lkj7N/ZDmYMtE6pVd6l+uYydxBq4WiI271o=;
 b=p+n2DY76jLDaVZyJPwPtm0f/fxI+Q8073fq8RLCO8U6oOuB1lTuWNsAkBXSibxjg5SSATESrM
 at7RsKh8GjICCJoLdNsaXwssozuSZakY2E4SfTBQeXByFW7UfvgUiRQ
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sdm845_resources has no icc_res, so on SDM845 CAMSS never votes for
memory bandwidth: while streaming, the camnoc HF and SF masters show no
votes in interconnect_summary. They get whatever another client holds
on the same mmss_noc to mem_noc path, in practice the display, and with
the display off capture stalls.

On a OnePlus 6T (imx519, 1920x1080 RAW10 into the simple pipeline), ten
100-frame captures each:

  display on:   10 of 10 runs complete
  display off:   2 of 10 complete, 8 stall at 0-1 frames

Add a table with the sm8250 values for the AHB, HF and SF paths, plus
the second HF port that SDM845 splits its two full VFEs across. As on
the other SoCs, the votes are applied at runtime resume and dropped at
runtime suspend. A device tree without the interconnects gets no votes,
as before.

Tested on a OnePlus 6T with this change on the postmarketOS sdm845
kernel (6.18): with the display off, 10 of 10 1080p captures of 100
frames complete, and the camnoc HF ports vote 2 GB/s while streaming
and nothing when idle.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/media/platform/qcom/camss/camss.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index f8e5cf9f3f..0ed497b7b6 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -2219,6 +2219,30 @@ static const struct camss_subdev_resources vfe_res_8250[] = {
 	},
 };
 
+static const struct resources_icc icc_res_845[] = {
+	/* Same values as sm8250, plus the second HF port SDM845 splits its VFEs across */
+	{
+		.name = "ahb",
+		.icc_bw_tbl.avg = 38400,
+		.icc_bw_tbl.peak = 76800,
+	},
+	{
+		.name = "hf_0",
+		.icc_bw_tbl.avg = 2097152,
+		.icc_bw_tbl.peak = 2097152,
+	},
+	{
+		.name = "hf_1",
+		.icc_bw_tbl.avg = 2097152,
+		.icc_bw_tbl.peak = 2097152,
+	},
+	{
+		.name = "sf_mnoc",
+		.icc_bw_tbl.avg = 0,
+		.icc_bw_tbl.peak = 2097152,
+	},
+};
+
 static const struct resources_icc icc_res_sm8250[] = {
 	{
 		.name = "cam_ahb",
@@ -5690,6 +5714,8 @@ static const struct camss_resources sdm845_resources = {
 	.csiphy_res = csiphy_res_845,
 	.csid_res = csid_res_845,
 	.vfe_res = vfe_res_845,
+	.icc_res = icc_res_845,
+	.icc_path_num = ARRAY_SIZE(icc_res_845),
 	.csiphy_num = ARRAY_SIZE(csiphy_res_845),
 	.csid_num = ARRAY_SIZE(csid_res_845),
 	.vfe_num = ARRAY_SIZE(vfe_res_845),

-- 
2.47.3

