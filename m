From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 07 Nov 2024 11:58:09 +0000
Subject: [PATCH 1/2] clk: qcom: gcc-sm8550: Keep UFS PHY GDSCs ALWAYS_ON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-ufs-clk-fix-v1-1-6032ff22a052@linaro.org>
References: <20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org>
In-Reply-To: <20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Amit Pundir <amit.pundir@linaro.org>, 
 Nitin Rawat <quic_nitirawa@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1811;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=HLNXhxeA0d1kaDOGx2ZDq/GyczbnxDOYCBJsf8padcs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnLKtWlMyTFtfeKixW/Ry1GRcw0Wc5ZeIShmfST
 ljUoOuh8CCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZyyrVgAKCRBVnxHm/pHO
 9dUECACmLYKmlwTa3vNIOh8c2A9iQNTlvtbUop9MU+loAitzIM7cVs4ieKxbIdbNIV2OKoJpeDZ
 VaBcbVCrOjtKb0OcshplAXBbO+ev5HC1Vk/SRBf6SfZMF2JT0m1I6MpPP4g0HHnRaSuaJZFkGGa
 zNlEJZQyx/E1b03Tu0EOqnpdC4vLyN8YTB4YKukAtWBiEdHN/5mY4OreyvRzb/EBG3IfPB4DKJm
 LQ9VDOBMNRG7Y7Hr1M0le04AlUaiz+MD8r+ReV3GyCu0NYhbV2p7qnSEq1lf66BDZ9kop5lDJzR
 oNv6e5rrm5Tyz6/9DuQpTxNmYITg+BOTcM6QDTVvdu8cjqkh
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Starting from SM8550, UFS PHY GDSCs doesn't support hardware retention. So
using RETAIN_FF_ENABLE is wrong. Moreover, without ALWAYS_ON flag, GDSCs
will get powered down during suspend, causing the UFS PHY to loose its
state. And this will lead to below UFS error during resume as observed on
SM8550-QRD:

ufshcd-qcom 1d84000.ufs: ufshcd_uic_hibern8_exit: hibern8 exit failed. ret = 5
ufshcd-qcom 1d84000.ufs: __ufshcd_wl_resume: hibern8 exit failed 5
ufs_device_wlun 0:0:0:49488: ufshcd_wl_resume failed: 5
ufs_device_wlun 0:0:0:49488: PM: dpm_run_callback(): scsi_bus_resume+0x0/0x84 returns 5
ufs_device_wlun 0:0:0:49488: PM: failed to resume async: error 5

Cc: stable@vger.kernel.org # 6.8
Fixes: 1fe8273c8d40 ("clk: qcom: gcc-sm8550: Add the missing RETAIN_FF_ENABLE GDSC flag")
Reported-by: Neil Armstrong <neil.armstrong@linaro.org>
Suggested-by: Nitin Rawat <quic_nitirawa@quicinc.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/clk/qcom/gcc-sm8550.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/qcom/gcc-sm8550.c b/drivers/clk/qcom/gcc-sm8550.c
index 5abaeddd6afc..7dd08e175820 100644
--- a/drivers/clk/qcom/gcc-sm8550.c
+++ b/drivers/clk/qcom/gcc-sm8550.c
@@ -3046,7 +3046,7 @@ static struct gdsc ufs_phy_gdsc = {
 		.name = "ufs_phy_gdsc",
 	},
 	.pwrsts = PWRSTS_OFF_ON,
-	.flags = POLL_CFG_GDSCR | RETAIN_FF_ENABLE,
+	.flags = POLL_CFG_GDSCR | ALWAYS_ON,
 };
 
 static struct gdsc ufs_mem_phy_gdsc = {
@@ -3055,7 +3055,7 @@ static struct gdsc ufs_mem_phy_gdsc = {
 		.name = "ufs_mem_phy_gdsc",
 	},
 	.pwrsts = PWRSTS_OFF_ON,
-	.flags = POLL_CFG_GDSCR | RETAIN_FF_ENABLE,
+	.flags = POLL_CFG_GDSCR | ALWAYS_ON,
 };
 
 static struct gdsc usb30_prim_gdsc = {

-- 
2.25.1

