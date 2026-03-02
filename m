From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v4 0/5] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
Date: Mon, 02 Mar 2026 18:30:17 +0530
Message-Id: <20260302-qcom-ice-fix-v4-0-0e65740a5dcc@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOGJpWkC/3XMQQ6CMBAF0KuQrh1SprSKK+9hXJS2ShOh0mqjI
 dzdgZUxupnk//x5E0suepfYvphYdNknHwYK9aZgptPDxYG3lBlyVBwrDqMJPXjj4OyfYFELzWv
 ZCrSMXm7RUb1yxxPlzqd7iK9Vz7i0f6CMwKExlW6lVZKjOYSUyvGhr7TqSzps8bL4MFB8GYIMZ
 bTc1Upgc97+MOZ5fgNkwVjE8wAAAA==
X-Change-ID: 20260210-qcom-ice-fix-d2a3a045b32d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Adrian Hunter <adrian.hunter@intel.com>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 Abel Vesa <abelvesa@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, linux-scsi@vger.kernel.org, 
 Sumit Garg <sumit.garg@oss.qualcomm.com>, mani@kernel.org, 
 Neeraj Soni <neeraj.soni@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1908;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=toZY+oHCDLL1wXEJv++Eb8dGjU5O3Nr+hFpL9dqNUo0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBppYnyEWxqDOk0BM6sKUfi4886zLwu99WWtrO2C
 n4tV2enwR2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaaWJ8gAKCRBVnxHm/pHO
 9U65B/4ouVogJ2VGvK0uAwP5EfJq2GG6FeMRa61ZJo0S+5+Z57OA4Vjl35RaDiCgGHdHRpPnqek
 Zi7JGgXlv2/4AaXiDcJtEcR4SziGZOCiIMzU+q6TOy5IUxPQA7gTEsL5bjMjceTRWCevd9s44zO
 VsGqRyz/Y0/B9jQg2rTNIiYpdh4pFR9WBJbL/SxG4kHRnFXOa7RTdr/RMXinT3g6RTYokwcQpLA
 UI6p0JiD89+oQJSWF5/WBCS5Pc1LgcWZs4ANxFplvp3UarbT8o6J795qCMuW0UDcqVayfUV5NNd
 iUdzFitWZCUeSX7HdG55V9ViQL6/AYT3707chqN1jblwC3Du
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

 drivers/mmc/host/sdhci-msm.c | 10 +++++-----
 drivers/soc/qcom/ice.c       | 33 ++++++++++++++++++++++-----------
 drivers/ufs/host/ufs-qcom.c  | 10 +++++-----
 3 files changed, 32 insertions(+), 21 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260210-qcom-ice-fix-d2a3a045b32d

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

