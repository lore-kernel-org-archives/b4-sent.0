From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v6 0/5] soc: qcom: ice: Fix race between qcom_ice_probe()
 and of_qcom_ice_get()
Date: Mon, 09 Mar 2026 12:28:30 +0530
Message-Id: <20260309-qcom-ice-fix-v6-0-4dd3347df530@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJdvrmkC/3XOwQrCMAwG4FeRnq3ENO2mJ99DPHRt1II6XXUos
 nc320UZ7hL4f5KPvFXmJnFW69lbNdymnOqLBDefqXD0lwPrFCUrBHSAS9C3UJ91Cqz36akjeuO
 BbGUwKjm5Niz1wG13ko8p3+vmNegt9u0E1KIGvQpLX9noLGDY1Dkvbg9/kq3zQobqvdb8GGhGh
 hHDBW9LcgZX+2LCoK9hAEcGiQHsbEHgbQxTf9hfoxwZVgymgktPVLlAf4yu6z6eyp7newEAAA=
 =
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2294;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=UrB+nwLO5Nzq+PPEH+2q9A2ciYRrBSH/FL5LeliDRRU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBprm+caLzDzWwmsdpiMx11AV2ItnugWPKaWQR9x
 YJ5rdtbVuKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaa5vnAAKCRBVnxHm/pHO
 9T+wB/wOL3Np3hdKYPKOqHmCruktfr3OxHqw8OhBDfJWNoQtbQMk4IUFTx28LU8GrH931Z6vr4u
 INN8lxfKMWHV4zE0vpdI65rykagJj7/8F8mGCzqn3+PzMV0vY011LEURD4XU7zF6ZeY6xNU3RWi
 0vj7FmfRNv18nBCSPDlLd5SbGAqXyvNUgpohNHbsxsKqjiq5OtEKN/gki/xqS+9uKg5qsi3z+xG
 g8ooEjXd8vVs8+IyPzMdj1Qckbvg3he29eM2M6/8ypqMtEDtYmQqM/uraQ0MXSIri05oTuHzciW
 jKvTG7tRlgJL1w3v1SQC99hHo4qljP2Ph+pEWHq9npN6AQEy
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
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260210-qcom-ice-fix-d2a3a045b32d

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

