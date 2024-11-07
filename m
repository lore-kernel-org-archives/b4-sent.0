From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 07 Nov 2024 11:58:10 +0000
Subject: [PATCH 2/2] clk: qcom: gcc-sm8650: Keep UFS PHY GDSCs ALWAYS_ON
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-ufs-clk-fix-v1-2-6032ff22a052@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1726;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=FYMKCEEuacXk+42R8P6zQhXoxh2cvI/j+fmsSrjKCbU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnLKtWTSaVN7myne/t1gzjS1A1koyo4Svt/P6RF
 qn/vo26NbCJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZyyrVgAKCRBVnxHm/pHO
 9YJhCACEM11P1PgwtQ5SOpPd5K0j4R0YiML/G5exG9X1Il6TFhcWi1gOKtfe4Qxa7PV18rq871H
 Xxt4v9fyAZrR/sO4kIzKE9UE4VjUOx7uEQLx0mfHjYVhSfmFOA1+IwvNz0QSJZxSmJbMA4Ngl+N
 3fytbwtVJfLD+L9+Sj0jrezK4xc9JdTSEETyRcPXhKIcQxEY98Y8uUuzpsR8SOWuu7mtyAYUgcz
 pFh8mQwrmT+8zHpPb5PYhmHc91rJjy1c99aflBgmCL2X66hc7UuL4LMwBK5XTtuf48lKjxEMcVC
 jdv+PWToC5RWqj30LLEY2qpW8fWoRw4isIOtSEm2Si7KmCfi
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In SM8650, UFS PHY GDSCs doesn't support hardware retention. So using
RETAIN_FF_ENABLE is wrong. Moreover, without ALWAYS_ON flag, GDSCs will get
powered down during suspend, causing the UFS PHY to loose its state. And
this will lead to UFS error similar to below during resume:

ufshcd-qcom 1d84000.ufs: ufshcd_uic_hibern8_exit: hibern8 exit failed. ret = 5
ufshcd-qcom 1d84000.ufs: __ufshcd_wl_resume: hibern8 exit failed 5
ufs_device_wlun 0:0:0:49488: ufshcd_wl_resume failed: 5
ufs_device_wlun 0:0:0:49488: PM: dpm_run_callback(): scsi_bus_resume+0x0/0x84 returns 5
ufs_device_wlun 0:0:0:49488: PM: failed to resume async: error 5

Cc: stable@vger.kernel.org # 6.8
Fixes: c58225b7e3d7 ("clk: qcom: add the SM8650 Global Clock Controller driver, part 1")
Suggested-by: Nitin Rawat <quic_nitirawa@quicinc.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/clk/qcom/gcc-sm8650.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/qcom/gcc-sm8650.c b/drivers/clk/qcom/gcc-sm8650.c
index fd9d6544bdd5..ddc38caf7160 100644
--- a/drivers/clk/qcom/gcc-sm8650.c
+++ b/drivers/clk/qcom/gcc-sm8650.c
@@ -3480,7 +3480,7 @@ static struct gdsc ufs_phy_gdsc = {
 		.name = "ufs_phy_gdsc",
 	},
 	.pwrsts = PWRSTS_OFF_ON,
-	.flags = POLL_CFG_GDSCR | RETAIN_FF_ENABLE,
+	.flags = POLL_CFG_GDSCR | ALWAYS_ON,
 };
 
 static struct gdsc ufs_mem_phy_gdsc = {
@@ -3489,7 +3489,7 @@ static struct gdsc ufs_mem_phy_gdsc = {
 		.name = "ufs_mem_phy_gdsc",
 	},
 	.pwrsts = PWRSTS_OFF_ON,
-	.flags = POLL_CFG_GDSCR | RETAIN_FF_ENABLE,
+	.flags = POLL_CFG_GDSCR | ALWAYS_ON,
 };
 
 static struct gdsc usb30_prim_gdsc = {

-- 
2.25.1

