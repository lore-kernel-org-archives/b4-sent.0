From: Vincent Knecht <vincent.knecht@mailoo.org>
Date: Mon, 14 Apr 2025 18:45:12 +0200
Subject: [PATCH RESEND2 v2] clk: qcom: gcc-msm8939: Fix mclk0 & mclk1 for
 24 MHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250414-gcc-msm8939-fixes-mclk-v2-resend2-v2-1-5ddcf572a6de@mailoo.org>
X-B4-Tracking: v=1; b=H4sIAJc7/WcC/x3MsQqDMBCA4VeRm3ugZ1JM57o62LF0kHjao02UH
 IggvntDxw9+/gOUk7DCrTgg8SYqS8ygSwH+PcSZUcZsoJJsaSqDs/cYNDSudjjJzorBfz+4ESZ
 WjiOhM7YZjOX6Sg7yZ038D/PmCX37aLs7wes8f4bHAqF8AAAA
X-Change-ID: 20250414-gcc-msm8939-fixes-mclk-v2-resend2-9458a45e3629
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Shawn Guo <shawn.guo@linaro.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Stephan Gerhold <stephan@gerhold.net>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>, 
 linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Vincent Knecht <vincent.knecht@mailoo.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744649140; l=1473;
 i=vincent.knecht@mailoo.org; s=20250414; h=from:subject:message-id;
 bh=rmTNV+QNatPi9Yx+q9e80eZX7u4a7NReIZUsYB1JC3A=;
 b=bL5pEw4ycYvfASyvE3TY6wTsYbglQYSn1nspsXLgmUqe+Ru3JenjqUx2i03WIVWSr2jBXJT+h
 +PCGG8dDluLCnrdBxuZQodXyYLh+YQwcLjxihpKehisRBxvd3wG5DEt
X-Developer-Key: i=vincent.knecht@mailoo.org; a=ed25519;
 pk=MFCVQkhL3+d3NHDzNPWpyZ4isxJvT+QTqValj5gSkm4=
X-Endpoint-Received: by B4 Relay for vincent.knecht@mailoo.org/20250414 with auth_id=377
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix mclk0 & mclk1 parent map to use correct GPLL6 configuration and
freq_tbl to use GPLL6 instead of GPLL0 so that they tick at 24 MHz.

Fixes: 1664014e4679 ("clk: qcom: gcc-msm8939: Add MSM8939 Generic Clock Controller")
Suggested-by: Stephan Gerhold <stephan@gerhold.net>
Reviewed-by: Konrad Dybcio <konrad.dybcio@linaro.org>
Reviewed-by: Bryan O'Donoghue <bryan.odonoghue@linaro.org>
Signed-off-by: Vincent Knecht <vincent.knecht@mailoo.org>
---
 drivers/clk/qcom/gcc-msm8939.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/qcom/gcc-msm8939.c b/drivers/clk/qcom/gcc-msm8939.c
index 7431c9a65044f841f711df6e84008f759e7ab026..45193b3d714babcf56fc0c6877a13a73f3e79104 100644
--- a/drivers/clk/qcom/gcc-msm8939.c
+++ b/drivers/clk/qcom/gcc-msm8939.c
@@ -432,7 +432,7 @@ static const struct parent_map gcc_xo_gpll0_gpll1a_gpll6_sleep_map[] = {
 	{ P_XO, 0 },
 	{ P_GPLL0, 1 },
 	{ P_GPLL1_AUX, 2 },
-	{ P_GPLL6, 2 },
+	{ P_GPLL6, 3 },
 	{ P_SLEEP_CLK, 6 },
 };
 
@@ -1113,7 +1113,7 @@ static struct clk_rcg2 jpeg0_clk_src = {
 };
 
 static const struct freq_tbl ftbl_gcc_camss_mclk0_1_clk[] = {
-	F(24000000, P_GPLL0, 1, 1, 45),
+	F(24000000, P_GPLL6, 1, 1, 45),
 	F(66670000, P_GPLL0, 12, 0, 0),
 	{ }
 };

---
base-commit: b425262c07a6a643ebeed91046e161e20b944164
change-id: 20250414-gcc-msm8939-fixes-mclk-v2-resend2-9458a45e3629

Best regards,
-- 
Vincent Knecht <vincent.knecht@mailoo.org>

