From: David Heidelberg <david@ixit.cz>
Date: Sat, 17 Jan 2026 19:18:28 +0100
Subject: [PATCH] clk: qcom: dispcc-sm7150: Fix dispcc_mdss_pclk1_clk_src
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260117-sm7150-dispcc-fix-v1-1-2f39966bcad2@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAHPSa2kC/x2MSQqAMAwAvyI5G0iDVvAr4kHbVHNwoQERxL9bP
 M7AzAMmWcWgrx7IcqnpsRdwdQVhnfZFUGNhYGJPznVoW+dawqh2hoBJb/ScyPMcmaSB0p1Ziv6
 fw/i+H/Ws2eBjAAAA
X-Change-ID: 20260117-sm7150-dispcc-fix-62f062bd20e4
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Jens Reidel <adrian@mainlining.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1272; i=david@ixit.cz;
 h=from:subject:message-id; bh=DehSC42DoLuOU48sX00s0uMz8/ZmcNB/sAtQOA+m9mE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpa9KEl7PYVfM8z3T/52r1eu/lL5DJxmGQHNlmL
 aqy1wWgkwKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWvShAAKCRBgAj/E00kg
 cjmDD/0QhyDqp28pSI9fXFMiRNW+f587HV1YFHvXnqO1mYu08kw5/7BTvFVW7Lr2ovVM4TQI71/
 Dy/gGMyWVnlNY1CHc4C1xPJQVeRiPfdGh3T/mFx0veBH1hpUZiUvJ4q2vP+Y69NHeeyPqOt4Ekk
 dg2C81t1vC4KzRr45ARtO0AVSDyWVkiPvJhHZQqeIqmgy1a8w5GfRoWXAt5fsU4C8f1FuJead9M
 IoVhAjJlV7uBrDGg0mf7Q1KA3vHWtujuo+YYH2R5C9bOM+i/v3t0EIMU3Rl09edXR5FDJq0Okpf
 aBXl8T3M+gKXev2S/ANr3Y+sGLop3w5OvednjPwXxd7S/cxgt2SYFf5Brw8Bt3lVwoT2FcfIvIk
 ObxW8Itr7IIxgtmjlmnwJcuBBJufgUrz4K5qkwfZKpGT6UrAhT6hjK1T99LQM62em24lSFrz+Xf
 pr87jv1r7/xLjV4uKYfp+/CfWf1w06evYyTv0gtG/IPYO5wQXpWLKLlKQWkHKnBC6h9JG03M2+Y
 +BbKR5KzMo5hiAIR5g20qhiJv1J4r4yBiq/gM6QfcwYpN7qakU0WvFWctmblQVnaa5AiNtFW5hG
 zbgJPwn/7uwocP53xyxR6kb624vZa45fmj8d+GSpQe54PPSy1Q0cqO0POlcK1DcA/9rFbFX8lu6
 Bsy1qNK3BD1Y0Jw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set CLK_OPS_PARENT_ENABLE to ensure the parent gets prepared and enabled
when switching to it.

Fixes: e3c13e0caa8c ("clk: qcom: dispcc-sm7150: Fix dispcc_mdss_pclk0_clk_src")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
I would call it more addition than fix regarding to how the commit is
named, but generally both pclk0 and pclk1 should receive this flag.

Feel free to drop the Fixes tag.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/clk/qcom/dispcc-sm7150.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/dispcc-sm7150.c b/drivers/clk/qcom/dispcc-sm7150.c
index 811d380a8e9f9..ed8e34ffd69b0 100644
--- a/drivers/clk/qcom/dispcc-sm7150.c
+++ b/drivers/clk/qcom/dispcc-sm7150.c
@@ -371,7 +371,7 @@ static struct clk_rcg2 dispcc_mdss_pclk1_clk_src = {
 		.name = "dispcc_mdss_pclk1_clk_src",
 		.parent_data = dispcc_parent_data_4,
 		.num_parents = ARRAY_SIZE(dispcc_parent_data_4),
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 		.ops = &clk_pixel_ops,
 	},
 };

---
base-commit: 46fe65a2c28ecf5df1a7475aba1f08ccf4c0ac1b
change-id: 20260117-sm7150-dispcc-fix-62f062bd20e4

Best regards,
-- 
David Heidelberg <david@ixit.cz>

