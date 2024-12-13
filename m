From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v2 0/3] scsi: ufs: qcom: Suspend fixes
Date: Fri, 13 Dec 2024 19:23:28 +0530
Message-Id: <20241213-ufs-qcom-suspend-fix-v2-0-1de6cd2d6146@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFg8XGcC/4WNQQ6CMBBFr0K6dgxTBMGV9zAsaDvAJNpiR4iGc
 HcrF3D5XvLfX5VQZBJ1yVYVaWHh4BPoQ6bs2PmBgF1ipXN9Qo0Icy/wtOEBMstE3kHPbygrrKm
 xZeWaQqXpFCnpPXtrE48srxA/+8uCP/snuCDkUBdkjKNzZdBe7+y7GI4hDqrdtu0LZeQanrkAA
 AA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1899;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=fIuJ9Ysk9gL+ewa+bZt/zoZBjAsb6V7Ms7TdivTupdo=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnXDxb3KcXOghNgIpuuCcdfyVgKGCwAcCekf5fQ
 LpHRst7b0+JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1w8WwAKCRBVnxHm/pHO
 9XY3B/wLzUP0NCGuuYLBOLe0RaLeeWkLOene69s5naQb3jmGe58IDnTYvyusrK3iC9RyYFpamGq
 M1PPlvCjuWcFa51KtKvdjISqMc37XqBZfe7qzsyJCtz1srHqbgOx0jkvQYuKFU1NLEWTx2jE3J0
 XjBA6biHVHcRjbHFs5XzuoIOih19uMmv0ADGM2pVtADUVPNhtH4WaAx/25EGpQW5ppuOmLBSaSw
 9VNNN8EPEH3ePwu+vODoYmbFjeabB7R03o1knI4nHBgjvB5qyxWznWAvd8WNi3IMZlpJhwk1GSb
 5i+8p0FNF2dp2mM+SNHREjKelzyJWLTvQy1tTtvIrOzlcGqx
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the several suspend issues on Qcom platforms. Patch 1 fixes
the resume failure with spm_lvl=5 suspend on most of the Qcom platforms. For
this patch, I couldn't figure out the exact commit that caused the issue. So I
used the commit that introduced reinit support as a placeholder.

Patch 3 fixes the suspend issue on SM8550 and SM8650 platforms where UFS
PHY retention is not supported. Hence the default spm_lvl=3 suspend fails. So
this patch configures spm_lvl=5 as the default suspend level to force UFSHC/
device powerdown during suspend. This supersedes the previous series [1] that
tried to fix the issue in clock drivers.

This series is tested on Qcom SM8550 MTP and Qcom RB5 boards.

[1] https://lore.kernel.org/linux-arm-msm/20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v2:
- Changed 'ufs_qcom_drvdata::quirks' type to 'enum ufshcd_quirks'
- Collected tags
- Link to v1: https://lore.kernel.org/r/20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org

---
Manivannan Sadhasivam (3):
      scsi: ufs: qcom: Power off the PHY if it was already powered on in ufs_qcom_power_up_sequence()
      scsi: ufs: qcom: Allow passing platform specific OF data
      scsi: ufs: qcom: Power down the controller/device during system suspend for SM8550/SM8650 SoCs

 drivers/ufs/core/ufshcd-priv.h |  6 ------
 drivers/ufs/core/ufshcd.c      |  1 -
 drivers/ufs/host/ufs-qcom.c    | 31 +++++++++++++++++++------------
 drivers/ufs/host/ufs-qcom.h    |  5 +++++
 include/ufs/ufshcd.h           |  2 --
 5 files changed, 24 insertions(+), 21 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241211-ufs-qcom-suspend-fix-5618e9c56d93

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

