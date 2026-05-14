From: Rudraksha Gupta <guptarud@gmail.com>
Date: Thu, 14 May 2026 00:04:01 -0700
Subject: [PATCH 2/3] soc: qcom: spm: Add MSM8960 SAW2 CPU support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260514-expressatt_cpufreq-v1-2-487fd2d78859@gmail.com>
References: <20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com>
In-Reply-To: <20260514-expressatt_cpufreq-v1-0-487fd2d78859@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Gross <agross@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778742241; l=2299;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=nrLplu9+cKSqhALRTglWbMzBGC3bon3VtGeZsCT7sGQ=;
 b=UIKrGrwHTX76SeWIsGzDcTrzwRTiJPsh3jweNO+73SQm4NCLT+K87OiaDN45ldZp/Z1rBhkd9
 RzmFjmz8/sPBCpO0h7hUObP/pr30DMtR9rWXN0sO95ox/k5Vlkf+E9Z
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MSM8960 uses SAW2 v1.1, the same hardware version as the APQ8064.
Add SPM register data so that the SAW2 driver can program the correct
SPM sequences and PMIC parameters for MSM8960 CPUs.

The register layout, SPM sequences, voltage range, and regulator
parameters are shared with APQ8064. The only difference is pmic_dly:
0x03020004 on MSM8960 vs 0x02020004 on APQ8064.

Link: https://github.com/CyanogenMod/android_kernel_samsung_d2/blob/0dbe2b56847b304d30b809dfd08ba3b4a61d9af8/arch/arm/mach-msm/board-express.c#L3353-L3381
Assisted-by: Claude:claude-opus-4.6
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/soc/qcom/spm.c | 20 +++++++++++++++++++-
 1 file changed, 19 insertions(+), 1 deletion(-)

diff --git a/drivers/soc/qcom/spm.c b/drivers/soc/qcom/spm.c
index f75659fff287..596431b00a03 100644
--- a/drivers/soc/qcom/spm.c
+++ b/drivers/soc/qcom/spm.c
@@ -233,7 +233,7 @@ static const u16 spm_reg_offset_v1_1[SPM_REG_NR] = {
 
 static void smp_set_vdd_v1_1(void *data);
 
-/* SPM register data for 8064 */
+/* SPM register data for 8064, 8960 */
 static struct linear_range spm_v1_1_regulator_range =
 	REGULATOR_LINEAR_RANGE(700000, 0, 56, 12500);
 
@@ -253,6 +253,22 @@ static const struct spm_reg_data spm_reg_8064_cpu = {
 	.ramp_delay = 1250,
 };
 
+static const struct spm_reg_data spm_reg_8960_cpu = {
+	.reg_offset = spm_reg_offset_v1_1,
+	.spm_cfg = 0x1F,
+	.pmic_dly = 0x03020004,
+	.pmic_data[0] = 0x0084009C,
+	.pmic_data[1] = 0x00A4001C,
+	.seq = { 0x03, 0x0F, 0x00, 0x24, 0x54, 0x10, 0x09, 0x03, 0x01,
+		0x10, 0x54, 0x30, 0x0C, 0x24, 0x30, 0x0F },
+	.start_index[PM_SLEEP_MODE_STBY] = 0,
+	.start_index[PM_SLEEP_MODE_SPC] = 2,
+	.set_vdd = smp_set_vdd_v1_1,
+	.range = &spm_v1_1_regulator_range,
+	.init_uV = 1300000,
+	.ramp_delay = 1250,
+};
+
 static inline void spm_register_write(struct spm_driver_data *drv,
 					enum spm_reg reg, u32 val)
 {
@@ -501,6 +517,8 @@ static const struct of_device_id spm_match_table[] = {
 	  .data = &spm_reg_8974_8084_cpu },
 	{ .compatible = "qcom,apq8064-saw2-v1.1-cpu",
 	  .data = &spm_reg_8064_cpu },
+	{ .compatible = "qcom,msm8960-saw2-v1.1-cpu",
+	  .data = &spm_reg_8960_cpu },
 	{ },
 };
 MODULE_DEVICE_TABLE(of, spm_match_table);

-- 
2.54.0

