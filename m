From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Mon, 11 Nov 2024 23:18:30 +0530
Subject: [PATCH 1/5] scsi: ufs: core: Cancel RTC work during
 ufshcd_remove()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-ufs_bug_fix-v1-1-45ad8b62f02e@linaro.org>
References: <20241111-ufs_bug_fix-v1-0-45ad8b62f02e@linaro.org>
In-Reply-To: <20241111-ufs_bug_fix-v1-0-45ad8b62f02e@linaro.org>
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Mike Bi <mikebi@micron.com>, Bean Huo <beanhuo@micron.com>, 
 =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <linux@weissschuh.net>, 
 Luca Porzio <lporzio@micron.com>, Asutosh Das <quic_asutoshd@quicinc.com>, 
 Can Guo <quic_cang@quicinc.com>, Pedro Sousa <pedrom.sousa@synopsys.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, Peter Wang <peter.wang@mediatek.com>, 
 Stanley Jhu <chu.stanley@gmail.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>, 
 Orson Zhai <orsonzhai@gmail.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Chunyan Zhang <zhang.lyra@gmail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Santosh Y <santoshsy@gmail.com>, Namjae Jeon <linkinjeon@gmail.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-renesas-soc@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1553;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=DVIcv3/NWxzqjqTgGie8L2Gx0Ep0Cnv9hngTv71tWI8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnMkNyuWNNeuyqHW6wHJWBMDDSw07Unxl6usmOR
 ufHW4bxRbuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZzJDcgAKCRBVnxHm/pHO
 9T95CACMdtOCvpWHJK1lxW2m+V6GbLEuNbAD0lZ2wBw1SXofplwVCWGJdvi40XW/5/caHDa4p3V
 8cl5LFsw29z6p0n6ZwMC4Fl2nQjs3S8M+frDwLyelMKBvzuuhqIKf1bp8oJZC8e8q7I3i/+hBbc
 g0a3GvGZaTFNACN7v88ROg0J9CvhylTTeAWC5gTWLOF/dIr+6AUP+8VTPa9v+zTeGaCibMJvN0e
 P632FxzWqbrUCP6X/NUCeptORHwrSlkmUtMK3pLku6vxzQRpDtM1l/S4o8ktUdVsglUmtXnzCNW
 Ix2pNkxM4jEkVNJqrZ9ceWl40kPLs2qa2Tg09M7wbBDHLane
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, RTC work is only cancelled during __ufshcd_wl_suspend(). When
ufshcd is removed in ufshcd_remove(), RTC work is not cancelled. Due to
this, any further trigger of the RTC work after ufshcd_remove() would
result in a NULL pointer dereference as below:

Unable to handle kernel NULL pointer dereference at virtual address 00000000000002a4
Workqueue: events ufshcd_rtc_work
Call trace:
 _raw_spin_lock_irqsave+0x34/0x8c
 pm_runtime_get_if_active+0x24/0xb4
 ufshcd_rtc_work+0x124/0x19c
 process_scheduled_works+0x18c/0x2d8
 worker_thread+0x144/0x280
 kthread+0x11c/0x128
 ret_from_fork+0x10/0x20

Since RTC work accesses the ufshcd internal structures, it should be cancelled
when ufshcd is removed. So do that in ufshcd_remove(), as per the order in
ufshcd_init().

Cc: stable@vger.kernel.org # 6.8
Fixes: 6bf999e0eb41 ("scsi: ufs: core: Add UFS RTC support")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/ufs/core/ufshcd.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/ufs/core/ufshcd.c b/drivers/ufs/core/ufshcd.c
index f5846598d80e..cc2555333512 100644
--- a/drivers/ufs/core/ufshcd.c
+++ b/drivers/ufs/core/ufshcd.c
@@ -10225,6 +10225,7 @@ void ufshcd_remove(struct ufs_hba *hba)
 	ufs_hwmon_remove(hba);
 	ufs_bsg_remove(hba);
 	ufs_sysfs_remove_nodes(hba->dev);
+	cancel_delayed_work_sync(&hba->ufs_rtc_update_work);
 	blk_mq_destroy_queue(hba->tmf_queue);
 	blk_put_queue(hba->tmf_queue);
 	blk_mq_free_tag_set(&hba->tmf_tag_set);

-- 
2.25.1

