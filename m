From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v3 0/4] scsi: ufs: qcom: Suspend fixes
Date: Thu, 19 Dec 2024 22:20:40 +0530
Message-Id: <20241219-ufs-qcom-suspend-fix-v3-0-63c4b95a70b9@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOBOZGcC/4XNQQ6CMBCF4auQrh3DtFDBlfcwLqAdoIm22EqjI
 dzdwkoXxuX/kvlmZoG8ocCO2cw8RROMsynELmNqaGxPYHRqxnNeIEeEqQtwV+4GYQojWQ2deUI
 psaJalVLXgqXT0VOaN/Z8ST2Y8HD+tX2JuK5/wIiQQyWobTUdZIvqdDW28W7vfM9WMfJPRfxQe
 FJQk1Saa4mF/FKWZXkDArZAGP8AAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2310;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=IiSx2c1rWCpopOjw7IUhmvQhktehYl5PNc2RgbhH8LM=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnZE7pF0xR8u5j1AZQNq0a1iIPAASQkMD+7+21s
 TL6BvlQftOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ2RO6QAKCRBVnxHm/pHO
 9Y7xB/wJQUKBYCijZxDVSc4pOmjWd4WRh4wnXcK5J6+Xz6N3i1CNoFuu2JQGfbMx7vUQCgtzsjY
 H8GahM/OrQSw1LWp8tOJQ2idxcqLOYtj76lF/Z6vq97A3rF3O1XoNAS8nfh2aCemWnFx1CofxMy
 YbkPFly62g1yTOe1qboqc7FUjgiXtIAgH79y/RjrpKenhF7aY8ecLbn4kyWn7h+bjTkiGmNGOrW
 EScBBX7B36xE+ifj3bp8FHK8KrL2xkc5KcN6M6fYnrdcmtxwSX0XwMEsqwcCPoqVqqhzqUMKADH
 lfN0Hkcf5d3LO8chNNHB5Zdc5bVUSx+3n+dEeHB2Z1eG/ki4
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the several suspend issues on Qcom platforms. Patch 1 fixes
the resume failure with spm_lvl=5 suspend on most of the Qcom platforms. For
this patch, I couldn't figure out the exact commit that caused the issue. So I
used the commit that introduced reinit support as a placeholder.

Patch 4 fixes the suspend issue on SM8550 and SM8650 platforms where UFS
PHY retention is not supported. Hence the default spm_lvl=3 suspend fails. So
this patch configures spm_lvl=5 as the default suspend level to force UFSHC/
device powerdown during suspend. This supersedes the previous series [1] that
tried to fix the issue in clock drivers.

This series is tested on Qcom SM8550 QRD, SM8650 QRD and Qcom RB5 boards.

[1] https://lore.kernel.org/linux-arm-msm/20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v3:
- Added a patch that honors the runtime/system PM levels set by host drivers.
  Otherwise patch 4 doesn't have any effect. This was discovered with SM8650
  QRD.
- Collected tags
- Link to v2: https://lore.kernel.org/r/20241213-ufs-qcom-suspend-fix-v2-0-1de6cd2d6146@linaro.org

Changes in v2:
- Changed 'ufs_qcom_drvdata::quirks' type to 'enum ufshcd_quirks'
- Collected tags
- Link to v1: https://lore.kernel.org/r/20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org

---
Manivannan Sadhasivam (4):
      scsi: ufs: qcom: Power off the PHY if it was already powered on in ufs_qcom_power_up_sequence()
      scsi: ufs: core: Honor runtime/system PM levels if set by host controller drivers
      scsi: ufs: qcom: Allow passing platform specific OF data
      scsi: ufs: qcom: Power down the controller/device during system suspend for SM8550/SM8650 SoCs

 drivers/ufs/core/ufshcd-priv.h |  6 ------
 drivers/ufs/core/ufshcd.c      | 10 ++++++----
 drivers/ufs/host/ufs-qcom.c    | 31 +++++++++++++++++++------------
 drivers/ufs/host/ufs-qcom.h    |  5 +++++
 include/ufs/ufshcd.h           |  2 --
 5 files changed, 30 insertions(+), 24 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241211-ufs-qcom-suspend-fix-5618e9c56d93

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

