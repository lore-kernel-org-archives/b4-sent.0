From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 24 Sep 2026 16:22:11 +0400
Subject: [PATCH] pinctrl: qcom: ipq5018: add required gpios and missing PWM
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-ipq5018-pwm-functions-v1-1-8990a4e85b2f@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQ5FMBBA0V+RWZukM0HwK2IhNZiFqtZ7JOLfN
 ZZ3ce4NUYJKhDa7Ichfo24uBeUZ2GVws6COqYENV6bhAtXvpaEa/bni9HP2SCAiizVMNFalJUj
 WB5n0+r5d/zwvMhTZo2cAAAA=
X-Change-ID: 20260924-ipq5018-pwm-functions-2ec0211d65c1
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790252534; l=3386;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=FCX8QU8cgCFtMwn95hhkJ8nA0NaX4isbuKSBdSUSSME=;
 b=ipKmPUjyRRYjYNfcp1cI8uSg5mp3lxE5My9Z10KKCYIONhmvlxiZpbojY3CIljTzXbILtMuYD
 3ueUc+Wfc1tARYxMEaAob7irKyuJydrQeWWxc+moimbMKFNpHVlQO3m
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On multiple Linksys routers, GPIO 1, 30, and 46 are used to drive the
PWM led on PWM1, PWM3, and PWM0 channels respectively, so let's update
the pwm# and pingroups accordingly.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/pinctrl/qcom/pinctrl-ipq5018.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/pinctrl/qcom/pinctrl-ipq5018.c b/drivers/pinctrl/qcom/pinctrl-ipq5018.c
index 84392fe258c9..74fccdd5146a 100644
--- a/drivers/pinctrl/qcom/pinctrl-ipq5018.c
+++ b/drivers/pinctrl/qcom/pinctrl-ipq5018.c
@@ -539,7 +539,7 @@ static const char * const qdss_tracectl_b_groups[] = {
 };
 
 static const char * const pwm0_groups[] = {
-	"gpio42",
+	"gpio42", "gpio46",
 };
 
 static const char * const qdss_cti_trig_out_b0_groups[] = {
@@ -547,7 +547,7 @@ static const char * const qdss_cti_trig_out_b0_groups[] = {
 };
 
 static const char * const pwm1_groups[] = {
-	"gpio43",
+	"gpio43", "gpio1",
 };
 
 static const char * const qdss_cti_trig_in_b0_groups[] = {
@@ -563,7 +563,7 @@ static const char * const qdss_cti_trig_out_b1_groups[] = {
 };
 
 static const char * const pwm3_groups[] = {
-	"gpio45", "gpio13",
+	"gpio45", "gpio30", "gpio13",
 };
 
 static const char * const qdss_cti_trig_in_b1_groups[] = {
@@ -677,7 +677,7 @@ static const struct pinfunction ipq5018_functions[] = {
 
 static const struct msm_pingroup ipq5018_groups[] = {
 	PINGROUP(0, atest_char, _, qdss_cti_trig_out_a0, wci_txd, wci_rxd, xfem, _, _, _),
-	PINGROUP(1, atest_char, _, qdss_cti_trig_in_a0, wci_txd, wci_rxd, xfem, _, _, _),
+	PINGROUP(1, atest_char, pwm1, qdss_cti_trig_in_a0, wci_txd, wci_rxd, xfem, _, _, _),
 	PINGROUP(2, atest_char, _, qdss_cti_trig_out_a1, wci_txd, wci_rxd, xfem, _, _, _),
 	PINGROUP(3, atest_char, _, qdss_cti_trig_in_a1, wci_txd, wci_rxd, xfem, _, _, _),
 	PINGROUP(4, sdc1_data, qspi_data, blsp1_spi1, btss, dbg_out, qdss_traceclk_a, _, burn0, _),
@@ -706,7 +706,7 @@ static const struct msm_pingroup ipq5018_groups[] = {
 	PINGROUP(27, audio_txmclk, wsa_swrm, audio_txmclk, blsp2_spi, btss, _, qdss_tracedata_b, _, _),
 	PINGROUP(28, audio_txbclk, wsa_swrm, blsp0_uart1, btss, qdss_tracedata_b, _, _, _, _),
 	PINGROUP(29, audio_txfsync, _, blsp0_uart1, _, qdss_tracedata_b, _, _, _, _),
-	PINGROUP(30, audio_txd, led2, led0, _, _, _, _, _, _),
+	PINGROUP(30, audio_txd, led2, led0, pwm3, _, _, _, _, _),
 	PINGROUP(31, blsp2_spi0, blsp1_uart1, _, qdss_tracedata_b, eud_gpio, _, _, _, _),
 	PINGROUP(32, blsp2_spi0, blsp1_uart1, _, qdss_tracedata_b, eud_gpio, _, _, _, _),
 	PINGROUP(33, blsp2_i2c0, blsp2_spi0, blsp1_uart1, _, qdss_tracedata_b, eud_gpio, _, _, _),
@@ -722,7 +722,7 @@ static const struct msm_pingroup ipq5018_groups[] = {
 	PINGROUP(43, pwm1, qdss_cti_trig_in_b0, wci_txd, wci_rxd, xfem, _, _, _, _),
 	PINGROUP(44, pwm2, qdss_cti_trig_out_b1, wci_txd, wci_rxd, xfem, _, _, _, _),
 	PINGROUP(45, pwm3, qdss_cti_trig_in_b1, wci_txd, wci_rxd, xfem, _, _, _, _),
-	PINGROUP(46, led0, _, _, _, _, _, _, _, _),
+	PINGROUP(46, led0, pwm0, _, _, _, _, _, _, _),
 };
 
 static const struct msm_pinctrl_soc_data ipq5018_pinctrl = {

---
base-commit: 3d7783543c2646af69ad65825e810060494bea21
change-id: 20260924-ipq5018-pwm-functions-2ec0211d65c1

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

