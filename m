From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 11 Dec 2024 23:10:16 +0530
Subject: [PATCH 1/3] scsi: ufs: qcom: Power off the PHY if it was already
 powered on in ufs_qcom_power_up_sequence()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241211-ufs-qcom-suspend-fix-v1-1-83ebbde76b1c@linaro.org>
References: <20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org>
In-Reply-To: <20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Abel Vesa <abel.vesa@linaro.org>, Bjorn Andersson <andersson@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Amit Pundir <amit.pundir@linaro.org>, 
 Nitin Rawat <quic_nitirawa@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org, Ram Kumar Dwivedi <quic_rdwivedi@quicinc.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=6152;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=xhrzNYPSULlJXapKlJ6dtb9q0uMDOQ9cAb170YQPfZ0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnWc6IPEgnucJRoa0EXM+AY3yX+GuzERMVeKObz
 0chiJGruZ6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1nOiAAKCRBVnxHm/pHO
 9V1HB/9NT4gDekZUDY7HuihUu8qmQEKs1n0GQXewx/1N4ho6Y9wMpLER25A7byMNPGIgtf946GC
 t+TXh1nj+iCgQgh4qVO0q2SPv4gQMB7eNeRJmFeg/ZmCVPitKmwQQR7dLqZtGD2rkG2SaP2iehZ
 mPrhuB5yln/w+hq+kULpECn9mhHoV9CEt70CpTBnUHyghY+fWm+6O0U+C9ZxC3MvVZmASiunpYP
 PyPbPd2NHy+KpwyhP5vLSbfq6NiewoVntIp77b3UOerpkIjcnyVrHu/2wB1DSPASBYFyR0nXs70
 vWjgTok9AnG6wvZlOfDDEZ+sGcQLGQBM+1g9k5y6kUCYWbNX
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PHY might already be powered on during ufs_qcom_power_up_sequence() in a
couple of cases:

1. During UFSHCD_QUIRK_REINIT_AFTER_MAX_GEAR_SWITCH quirk
2. Resuming from spm_lvl = 5 suspend

In those cases, it is necessary to call phy_power_off() and phy_exit() in
ufs_qcom_power_up_sequence() function to power off the PHY before calling
phy_init() and phy_power_on().

Case (1) is doing it via ufs_qcom_reinit_notify() callback, but case (2) is
not handled. So to satisfy both cases, call phy_power_off() and phy_exit()
if the phy_count is non-zero. And with this change, the reinit_notify()
callback is no longer needed.

This fixes the below UFS resume failure with spm_lvl = 5:

ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: ufshcd_host_reset_and_restore: Host init failed -5
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: ufshcd_host_reset_and_restore: Host init failed -5
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: ufshcd_host_reset_and_restore: Host init failed -5
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: ufshcd_host_reset_and_restore: Host init failed -5
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: Enabling the controller failed
ufshcd-qcom 1d84000.ufshc: ufshcd_host_reset_and_restore: Host init failed -5
ufs_device_wlun 0:0:0:49488: ufshcd_wl_resume failed: -5
ufs_device_wlun 0:0:0:49488: PM: dpm_run_callback(): scsi_bus_resume returns -5
ufs_device_wlun 0:0:0:49488: PM: failed to resume async: error -5

Cc: stable@vger.kernel.org # 6.3
Fixes: baf5ddac90dc ("scsi: ufs: ufs-qcom: Add support for reinitializing the UFS device")
Reported-by: Ram Kumar Dwivedi <quic_rdwivedi@quicinc.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd-priv.h |  6 ------
 drivers/ufs/core/ufshcd.c      |  1 -
 drivers/ufs/host/ufs-qcom.c    | 13 +++++--------
 include/ufs/ufshcd.h           |  2 --
 4 files changed, 5 insertions(+), 17 deletions(-)

diff --git a/drivers/ufs/core/ufshcd-priv.h b/drivers/ufs/core/ufshcd-priv.h
index 7aea8fbaeee8..1f413b3aab5d 100644
--- a/drivers/ufs/core/ufshcd-priv.h
+++ b/drivers/ufs/core/ufshcd-priv.h
@@ -236,12 +236,6 @@ static inline void ufshcd_vops_config_scaling_param(struct ufs_hba *hba,
 		hba->vops->config_scaling_param(hba, p, data);
 }
 
-static inline void ufshcd_vops_reinit_notify(struct ufs_hba *hba)
-{
-	if (hba->vops && hba->vops->reinit_notify)
-		hba->vops->reinit_notify(hba);
-}
-
 static inline int ufshcd_vops_mcq_config_resource(struct ufs_hba *hba)
 {
 	if (hba->vops && hba->vops->mcq_config_resource)
diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index 6a2685333076..7bd0f5482db3 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -8820,7 +8820,6 @@ static int ufshcd_probe_hba(struct ufs_hba *hba, bool init_dev_params)
 		ufshcd_device_reset(hba);
 		ufs_put_device_desc(hba);
 		ufshcd_hba_stop(hba);
-		ufshcd_vops_reinit_notify(hba);
 		ret = ufshcd_hba_enable(hba);
 		if (ret) {
 			dev_err(hba->dev, "Host controller enable failed\n");
diff --git a/drivers/ufs/host/ufs-qcom.c b/drivers/ufs/host/ufs-qcom.c
index 3b592492e152..32b0c74437de 100644
--- a/drivers/ufs/host/ufs-qcom.c
+++ b/drivers/ufs/host/ufs-qcom.c
@@ -368,6 +368,11 @@ static int ufs_qcom_power_up_sequence(struct ufs_hba *hba)
 	if (ret)
 		return ret;
 
+	if (phy->power_count) {
+		phy_power_off(phy);
+		phy_exit(phy);
+	}
+
 	/* phy initialization - calibrate the phy */
 	ret = phy_init(phy);
 	if (ret) {
@@ -1579,13 +1584,6 @@ static void ufs_qcom_config_scaling_param(struct ufs_hba *hba,
 }
 #endif
 
-static void ufs_qcom_reinit_notify(struct ufs_hba *hba)
-{
-	struct ufs_qcom_host *host = ufshcd_get_variant(hba);
-
-	phy_power_off(host->generic_phy);
-}
-
 /* Resources */
 static const struct ufshcd_res_info ufs_res_info[RES_MAX] = {
 	{.name = "ufs_mem",},
@@ -1825,7 +1823,6 @@ static const struct ufs_hba_variant_ops ufs_hba_qcom_vops = {
 	.device_reset		= ufs_qcom_device_reset,
 	.config_scaling_param = ufs_qcom_config_scaling_param,
 	.program_key		= ufs_qcom_ice_program_key,
-	.reinit_notify		= ufs_qcom_reinit_notify,
 	.mcq_config_resource	= ufs_qcom_mcq_config_resource,
 	.get_hba_mac		= ufs_qcom_get_hba_mac,
 	.op_runtime_config	= ufs_qcom_op_runtime_config,
diff --git a/include/ufs/ufshcd.h b/include/ufs/ufshcd.h
index d7aca9e61684..6e40b8e8009b 100644
--- a/include/ufs/ufshcd.h
+++ b/include/ufs/ufshcd.h
@@ -327,7 +327,6 @@ struct ufs_pwr_mode_info {
  * @program_key: program or evict an inline encryption key
  * @fill_crypto_prdt: initialize crypto-related fields in the PRDT
  * @event_notify: called to notify important events
- * @reinit_notify: called to notify reinit of UFSHCD during max gear switch
  * @mcq_config_resource: called to configure MCQ platform resources
  * @get_hba_mac: reports maximum number of outstanding commands supported by
  *	the controller. Should be implemented for UFSHCI 4.0 or later
@@ -379,7 +378,6 @@ struct ufs_hba_variant_ops {
 				    void *prdt, unsigned int num_segments);
 	void	(*event_notify)(struct ufs_hba *hba,
 				enum ufs_event_type evt, void *data);
-	void	(*reinit_notify)(struct ufs_hba *);
 	int	(*mcq_config_resource)(struct ufs_hba *hba);
 	int	(*get_hba_mac)(struct ufs_hba *hba);
 	int	(*op_runtime_config)(struct ufs_hba *hba);

-- 
2.25.1

