From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 30 Jun 2025 16:35:00 +0400
Subject: [PATCH v6 1/3] clk: qcom: gcc-ipq5018: fix GE PHY reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-ipq5018-ge-phy-v6-1-01be06378c15@outlook.com>
References: <20250630-ipq5018-ge-phy-v6-0-01be06378c15@outlook.com>
In-Reply-To: <20250630-ipq5018-ge-phy-v6-0-01be06378c15@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751286906; l=1220;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=y65n0Od6u+x9wP3HKotpTyPdgu84le/dyFb7G8W0t/E=;
 b=8GFFdXl2KAWvcdLAfio5sbRql6URuWxu1LrF2UScWzaP2crAPzgbOSYYGfwb2CyAvqVN6HQvG
 cKUzsL4FKfOCe0qZu/cImN6p6estTR7yvV1/7E6WEQD7X3ZhI9T9Gqf
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MISC reset is supposed to trigger a resets across the MDC, DSP, and
RX & TX clocks of the IPQ5018 internal GE PHY. So let's set the bitmask
of the reset definition accordingly in the GCC as per the downstream
driver.

Link: https://git.codelinaro.org/clo/qsdk/oss/kernel/linux-ipq-5.4/-/commit/00743c3e82fa87cba4460e7a2ba32f473a9ce932

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/clk/qcom/gcc-ipq5018.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/qcom/gcc-ipq5018.c b/drivers/clk/qcom/gcc-ipq5018.c
index 70f5dcb96700f55da1fb19fc893d22350a7e63bf..6eb86c034fda18c38dcd9726f0903841252381da 100644
--- a/drivers/clk/qcom/gcc-ipq5018.c
+++ b/drivers/clk/qcom/gcc-ipq5018.c
@@ -3660,7 +3660,7 @@ static const struct qcom_reset_map gcc_ipq5018_resets[] = {
 	[GCC_WCSS_AXI_S_ARES] = { 0x59008, 6 },
 	[GCC_WCSS_Q6_BCR] = { 0x18004, 0 },
 	[GCC_WCSSAON_RESET] = { 0x59010, 0},
-	[GCC_GEPHY_MISC_ARES] = { 0x56004, 0 },
+	[GCC_GEPHY_MISC_ARES] = { 0x56004, .bitmask = GENMASK(3, 0) },
 };
 
 static const struct of_device_id gcc_ipq5018_match_table[] = {

-- 
2.49.0

