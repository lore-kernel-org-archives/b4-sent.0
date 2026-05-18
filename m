From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v7 0/5] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
Date: Mon, 18 May 2026 19:22:16 +0530
Message-Id: <20260518-qcom-ice-fix-v7-0-2a595382185b@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJAZC2oC/3XOwQrCMAwG4FeRnq3ENO2mJ99DPHRt1II6XXUos
 nc320UZ7hL4f5KPvFXmJnFW69lbNdymnOqLhGI+U+HoLwfWKUpWCOgAl6BvoT7rFFjv01NH9MY
 D2cpgVHJybVjqgdvuJB9TvtfNa9Bb7NsJqEUNehWWvrLRWcCwqXNe3B7+JFvnhQzVe635MdCMD
 COGC96W5Ayu9sWEQV/DAI4MEgPY2YLA2xim/rC/RjkyrBhMBZeeqHKB/hhd130Al7QznHsBAAA
 =
X-Change-ID: 20260210-qcom-ice-fix-d2a3a045b32d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, Ulf Hansson <ulfh@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, stable@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Ulf Hansson <ulfh@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2360;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=kWISkeVRfd8jvFcHNKLpQ1GFOQCP73gX7K3vEQF5lPE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqCxmYCvvALWkQZC2rYZ1PvIwFlbeupGGU1KLFO
 g0x8cKNlvGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagsZmAAKCRBVnxHm/pHO
 9Q6zB/0fF5aKOehEDnZHrPz34NODgyB+ECsieVqHX9VV4Kmy3+UxjD5MrLQiO8dYt2/0eVBbgQ1
 FnQhTG+rKcCBvS3gPmMFwehUwnQSGpymnBi9DASd6nHpef6sZxXTA0Sw/ORiZSBdKpNK4lLgqON
 P+seFQ/0DljEM6jrlzS73Ewh3Or9C0W+V3f8+X3x5NfvL/mlg/gi0kdsZjwL75zzw1WCNnDTJAc
 njmjXmcOnT7tM4ucirlONeEQFW4TbyFRlNi12CIx+LFAGXjBEtzV0V0OpAUfNZIVl3p+STo+Q2q
 Fnjlm661UD6dOH3wDv1LjuxiGvIb1+HBk0zxEhCaP/UTwVJ8
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the race betwen qcom_ice_probe() and of_qcom_ice_get()
but synchronizing the two APIs and properly propagating the error codes to
clients.

Merge Strategy
==============

Due to dependency, all patches should go through Qcom SoC tree.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v7:
- Rebased on top of v7.1-rc1
- Collected tags

Changes in v6:
- Fixed sparse warnings
- Link to v5: https://lore.kernel.org/r/20260308-qcom-ice-fix-v5-0-e47e8a44b6c4@oss.qualcomm.com

Changes in v5:
- Used Xarray instead of platform drvdata for passing the pointer since driver
  core frees drvdata on probe failure.
- Link to v4: https://lore.kernel.org/r/20260302-qcom-ice-fix-v4-0-0e65740a5dcc@oss.qualcomm.com

Changes in v4:
- For supporting multi-ice instances in a SoC, stored the err ptr in platform
  drvdata instead of in a global pointer.
- Link to v3: https://lore.kernel.org/r/20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com

Changes in v3:
- Dropped the platform driver removal patch and used the ice_handle to pass
  error codes. This was done as I learned that we need to have the platform
  driver design going forward and also removing it introduces other issues.
- Link to v2: https://lore.kernel.org/r/20260210-qcom-ice-fix-v2-0-9c1ab5d6502c@oss.qualcomm.com

Changes in v2:

- Added MODULE_* macros back
- Removed spurious platform_device_put()
- Added patches to remove NULL return

---
Manivannan Sadhasivam (5):
      soc: qcom: ice: Fix race between qcom_ice_probe() and of_qcom_ice_get()
      soc: qcom: ice: Return -ENODEV if the ICE platform device is not found
      soc: qcom: ice: Return proper error codes from devm_of_qcom_ice_get() instead of NULL
      mmc: sdhci-msm: Remove NULL check from devm_of_qcom_ice_get()
      scsi: ufs: ufs-qcom: Remove NULL check from devm_of_qcom_ice_get()

 drivers/mmc/host/sdhci-msm.c | 10 ++++-----
 drivers/soc/qcom/ice.c       | 49 ++++++++++++++++++++++++++++++++------------
 drivers/ufs/host/ufs-qcom.c  | 10 ++++-----
 3 files changed, 46 insertions(+), 23 deletions(-)
---
base-commit: 254f49634ee16a731174d2ae34bc50bd5f45e731
change-id: 20260210-qcom-ice-fix-d2a3a045b32d

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

