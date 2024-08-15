From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v2 0/3] ufs: qcom: Fix probe failure on SM8550 SoC due to
 broken LSDBS field
Date: Thu, 15 Aug 2024 10:46:55 +0530
Message-Id: <20240815-ufs-bug-fix-v2-0-b373afae888f@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEePvWYC/22MQQ7CIBAAv9Ls2TVAQKon/2F6KHahmxgwYBtNw
 9/Fnj3OJDMbFMpMBS7dBplWLpxiA3Xo4D6PMRDy1BiUUFr0UuPiC7oloOc3aq2sd0K6/iSgFc9
 MTe+329B45vJK+bPPV/mz/z+rRIGGnD5Pxltj5fXBcczpmHKAodb6BRhIAo+nAAAA
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Amit Pundir <amit.pundir@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1250;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=/khdo0My3G+swuccfI6ySQc7yVQu776veJ6unGUnbVA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvY9JRRIr3klzE2+LW0sbg+9HwwUTKNVwST3Vs
 06Qf8uV06qJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr2PSQAKCRBVnxHm/pHO
 9bEUCACDNJnn8YxXYv6i8vQzD1bpRkK6pgb3wLXk8j+UWlxvt2N3OkvVH3CHPtngsFUnetodsPu
 z82+ZHIvhP+trg03GWRVQcw0H/Ut7h6XLdBrTYflttlXmbAbMT4u+SrvJXinWiopuP6GtdYSJEI
 Q4OwiVv+iohmkLoXW0fwaIJySkcxVWnt7m5P/XqvdHrC2PNu7CbJniq9EK4Y999ypS900urGfz7
 5B9/R/DY89cg9iI+CJt3z55Dl6BcCoK8Ir7XGhAeUNpcaA7pbPomQuFl9XsJjmvvDvGkNbd0Q7g
 TJh1C8wdQjh7LEWOiMlKX9vbROnxOB5RB9h64RTvSLVrrvs8
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the probe failure on the Qcom SM8550 SoC due to the broken
LSDBS field in the host controller capabilities register.

Please consider this series for v6.11 as it fixes a regression.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v2:
- Changed SDBS to LSDBS as per the final version of UFSHCI 4.0 spec
- Moved the quirk check to assignment
- Used correct fixes tag in patch 3/3
- Added tested-by tags
- Link to v1: https://lore.kernel.org/r/20240814-ufs-bug-fix-v1-0-5eb49d5f7571@linaro.org

---
Manivannan Sadhasivam (3):
      ufs: core: Rename LSDB to LSDBS to reflect the UFSHCI 4.0 spec
      ufs: core: Add a quirk for handling broken LSDBS field in controller capabilities register
      ufs: qcom: Add UFSHCD_QUIRK_BROKEN_LSDBS_CAP for SM8550 SoC

 drivers/ufs/core/ufshcd.c   | 10 +++++++---
 drivers/ufs/host/ufs-qcom.c |  6 +++++-
 include/ufs/ufshcd.h        |  9 ++++++++-
 include/ufs/ufshci.h        |  2 +-
 4 files changed, 21 insertions(+), 6 deletions(-)
---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240814-ufs-bug-fix-4427fb01b860

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

