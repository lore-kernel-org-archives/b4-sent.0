From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v3 0/2] ufs: qcom: Fix probe failure on SM8550 SoC due to
 broken LSDBS field
Date: Fri, 16 Aug 2024 11:55:09 +0530
Message-Id: <20240816-ufs-bug-fix-v3-0-e6fe0e18e2a3@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMXwvmYC/22MQQ7CIBAAv2L2LAYoCHryH8YD2KXdxBQDlmia/
 l3ak008ziQzE2RMhBnOuwkSFsoUhwrNfgf33g0dMmorg+RScSsUG0NmfuxYoDdTSprgufD2yKE
 Wz4RVr7frrXJP+RXTZ50Xsdj/nyIYZxq9OrU6GG3E5UGDS/EQUwfLqMjfWG9jWWPfmMYFh9bas
 Innef4CGgeA0OQAAAA=
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Amit Pundir <amit.pundir@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1401;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=j24GEDJCnKKDhHy6+RSpTUWeG0bpq/+BqdmeI6YLZn4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvvDG3izCG4Aa4sIaF9MGmyp4+eBt4PIJ3zbzq
 Kt240kMDlGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZr7wxgAKCRBVnxHm/pHO
 9c2wB/9LY1wbsfKqBJFfhbFYqm85l2kz0QHzdTnHH3r370AEFKpjXDPutaU74fUl3fjleZrXY9a
 K5SbpRidW+agu3ggKsJRoTCVTKS3BWGAmtGyrebpBEnrYx6cd9634+ipEi79puvqXXH0RYqjxvt
 IbQgCu+fz+Tc9D3Kq8KV0WGdfHrAG6OxBoJ4Orn5XCSVpBRsuhaOtoN48rjxKdSXS+4E0FwK1Ra
 MY7tOvUs3oquLZ/AnYnSdyP+LzLb5gQCn26ai0FtVcAk9xpPJTMlU0eZTyg4GkIdRpb2rO8BWXJ
 1a1S7oxN431YYc1x9SQpQtQu6/fNPK7Fico8eyKIumpR0DOI
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
Changes in v3:
- Dropped the patch that renamed LSDB field
- Changed the comment for the quirk and also fixed the UFSHCI version in
  description
- Collected review tag
- Link to v2: https://lore.kernel.org/r/20240815-ufs-bug-fix-v2-0-b373afae888f@linaro.org

Changes in v2:
- Changed SDBS to LSDBS as per the final version of UFSHCI 4.0 spec
- Moved the quirk check to assignment
- Used correct fixes tag in patch 3/3
- Added tested-by tags
- Link to v1: https://lore.kernel.org/r/20240814-ufs-bug-fix-v1-0-5eb49d5f7571@linaro.org

---
Manivannan Sadhasivam (2):
      ufs: core: Add a quirk for handling broken LSDBS field in controller capabilities register
      ufs: qcom: Add UFSHCD_QUIRK_BROKEN_LSDBS_CAP for SM8550 SoC

 drivers/ufs/core/ufshcd.c   | 6 +++++-
 drivers/ufs/host/ufs-qcom.c | 6 +++++-
 include/ufs/ufshcd.h        | 8 ++++++++
 3 files changed, 18 insertions(+), 2 deletions(-)
---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240814-ufs-bug-fix-4427fb01b860

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

