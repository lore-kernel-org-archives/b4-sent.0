From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/4] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
Date: Mon, 23 Feb 2026 13:32:51 +0530
Message-Id: <20260223-qcom-ice-fix-v3-0-6ca5846329f7@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKsJnGkC/3WMwQ6CMBBEf4Xs2SVlKyR68j8Ih9JW2USotNpoS
 P/dlbuXSd5k5m2QfGSf4FxtEH3mxGER0IcK7GSWm0d2wkCKOkWNwtWGGdl6vPIbHRlt1LEdNTm
 QyyN6qXddPwhPnJ4hfnZ7pl/7R5QJFZ5sY8bWda0iewkp1evL3GU11xIwlFK+tk5zta8AAAA=
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1601;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=U1vbfXxLYJpoqB0vLtDD0LEYx0ULx7q4q0aMqEAXCSA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnAmtN8Ptqj4btgkzlM7I4Zv1HbbBIxzFPxKSK
 dMX+Ibdcq2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZwJrQAKCRBVnxHm/pHO
 9SlOB/0Srn5ALm2UkqC9jb+Y8PXdN/0aNbzSarWRB1uFSwYAapsmWMATDInbKhtmZyQlkGvVZSa
 QvrGOEOSdHJikIB5oFMo0OkAZKwaYV9aZK93TPiNzCPPHsXoKNOKCzjqYesStDy6fJ+kkNib9Is
 Y8Ce1KVLQicL6IflvKxQfIRe155Mr1CKsiWAuJrNvrP2q7QcYqw59+h2h8Gz/+AXctT8uXEFysY
 VjfoSjGpRgMDDK9GvnBkCTOn51llH98DVk8jkHw9ctipbZhBfEOreEDvB74N+qnYonWfzA1IA7S
 tVRDa2m6U5AwhnX8jW89hVUaB/grAMpKeVN8FGVAKkVnGY5A
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
Manivannan Sadhasivam (4):
      soc: qcom: ice: Fix race between qcom_ice_probe() and of_qcom_ice_get()
      soc: qcom: ice: Return proper error codes from devm_of_qcom_ice_get() instead of NULL
      mmc: sdhci-msm: Remove NULL check from devm_of_qcom_ice_get()
      scsi: ufs: ufs-qcom: Remove NULL check from devm_of_qcom_ice_get()

 drivers/mmc/host/sdhci-msm.c | 10 ++++-----
 drivers/soc/qcom/ice.c       | 53 ++++++++++++++++++++++++++------------------
 drivers/ufs/host/ufs-qcom.c  | 10 ++++-----
 3 files changed, 41 insertions(+), 32 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260210-qcom-ice-fix-d2a3a045b32d

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

