From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/4] soc: qcom: ice: Remove platform_driver support and
 expose as a pure library
Date: Tue, 10 Feb 2026 12:26:49 +0530
Message-Id: <20260210-qcom-ice-fix-v2-0-9c1ab5d6502c@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALHWimkC/x2MQQqAIBAAvxJ7bsHW6tBXooPpVntISyEC8e9Jx
 xmYyZA4CieYmgyRH0kSfAVqG7CH8TujuMpAikZFncLbhhPFMm7yoiOjjeqHVZODmlyRq/5381L
 KBwYdpUJeAAAA
X-Change-ID: 20260210-qcom-ice-fix-d2a3a045b32d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, mani@kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org, Abel Vesa <abel.vesa@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1328;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=14eJu/e65Krl0O98yiBCxz41S1FxvvsUyw5DkWoDIB8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpitaz5wD+GT+GNV8a016Lvwg57YK23bFzxBP4T
 liFCTBMpFiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaYrWswAKCRBVnxHm/pHO
 9crvB/44ZaWUxDpDQJq9WmevFXzgclsf03FlbKbk890kwx9abXvj9q2xOGnKtNy9W2zK+MKIPPN
 skq61LCzs7pwGsfrnRWI2TmJCVFnEVqppxWy8YDoFpRMCbUdNBPq12xxP5I3WSoCBOAh/ygugw7
 KUy+CKxs/EqzCqWrVkltMw5+tYDZQoyghuSHZ29LvRNYmiZRdVwENkmtuK4K7WhL7iTc/uEs+/r
 DUJUp5uzcnJ06ioX1J0W5hzr5quhoyXmd/vlpz4I2gutArY9InQyvxkqY2sKMQo7L2fpLuhXkOe
 J6wmCiokkV8CBUJpVsk/dRe7SaNffe42WDTQlgjarZSZ6l3b
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series removes the platform_driver support from Qcom ICE driver and
exposes it as a pure library to the clients to avoid race conditions with ICE
SCM call availability.

Merge Strategy
==============

ICE patches (1,2) through Qcom tree and MMC/UFS patches (3,4) through respective
subsystem trees as there is no dependency.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v2:

* Added MODULE_* macros back
* Removed spurious platform_device_put()
* Added patches to remove NULL return

---
Manivannan Sadhasivam (4):
      soc: qcom: ice: Remove platform_driver support and expose as a pure library
      soc: qcom: ice: Return proper error codes from devm_of_qcom_ice_get() instead of NULL
      mmc: sdhci-msm: Remove NULL check from devm_of_qcom_ice_get()
      scsi: ufs: ufs-qcom: Remove NULL check from devm_of_qcom_ice_get()

 drivers/mmc/host/sdhci-msm.c |  10 ++--
 drivers/soc/qcom/ice.c       | 127 ++++++++++++++++---------------------------
 drivers/ufs/host/ufs-qcom.c  |  10 ++--
 3 files changed, 58 insertions(+), 89 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20260210-qcom-ice-fix-d2a3a045b32d

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

