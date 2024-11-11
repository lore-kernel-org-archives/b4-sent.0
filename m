From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/5] scsi: ufs: Bug fixes for ufs core and platform drivers
Date: Mon, 11 Nov 2024 23:18:29 +0530
Message-Id: <20241111-ufs_bug_fix-v1-0-45ad8b62f02e@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG1DMmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDINAtTSuOTypNj0/LrNA1SzE0TzO2TExLTDRRAuooKEoFCoNNi46trQU
 ADEBy810AAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1532;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Y+khpFiawXKLU/+l8e747ZP6KaaIIh+gTXQA+EIkgkY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnMkNyVRymijja4WYsMTq3UufBBioidTEf49F/G
 g6j4UfgEmiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZzJDcgAKCRBVnxHm/pHO
 9d0jB/449IToaB9ZcYdJONBd23MdNRpN9XTjoQ3UaKzzkCrBwemdD8ACugH5wLUaPzsStvYYt3C
 6oYkky5KzIlqwZMoQVr4rSs7t0C+05tD/fKah7PQkWE2sWw6qy5weu7aZdzMMLT4eewC1jVW+OJ
 6sDx7OKs23eLysMs5PpefkS/XDYDkowgBvPz0f1E11UQDoA4Ra1Wd84CkcdyqTh0XDMC0EV4D0p
 fGBOBK0Tpegsz2LI686Q6vrLJQBtn6pZNWAx2GHhNxEGbg97Rg5kF/7FtcnvVdgcDc0CDrxeyOu
 HAIwSVg9lV19dgsYP/y7m/iTY4qce8LrwLtHgy5oTwjONKG5
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series has several bug fixes that I encountered when the ufs-qcom driver
was removed and inserted back. But the fixes are applicable to other platform
glue drivers as well.

This series is tested on Qcom RB5 development board based on SM8250 SoC.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (5):
      scsi: ufs: core: Cancel RTC work during ufshcd_remove()
      scsi: ufs: qcom: Only free platform MSIs when ESI is enabled
      scsi: ufs: pltfrm: Disable runtime PM during removal of glue drivers
      scsi: ufs: pltfrm: Drop PM runtime reference count after ufshcd_remove()
      scsi: ufs: pltfrm: Dellocate HBA during ufshcd_pltfrm_remove()

 drivers/ufs/core/ufshcd.c             |  1 +
 drivers/ufs/host/cdns-pltfrm.c        |  4 +---
 drivers/ufs/host/tc-dwc-g210-pltfrm.c |  5 +----
 drivers/ufs/host/ufs-exynos.c         |  3 +--
 drivers/ufs/host/ufs-hisi.c           |  4 +---
 drivers/ufs/host/ufs-mediatek.c       |  5 +----
 drivers/ufs/host/ufs-qcom.c           |  7 ++++---
 drivers/ufs/host/ufs-renesas.c        |  4 +---
 drivers/ufs/host/ufs-sprd.c           |  5 +----
 drivers/ufs/host/ufshcd-pltfrm.c      | 16 ++++++++++++++++
 drivers/ufs/host/ufshcd-pltfrm.h      |  1 +
 11 files changed, 29 insertions(+), 26 deletions(-)
---
base-commit: 59b723cd2adbac2a34fc8e12c74ae26ae45bf230
change-id: 20241111-ufs_bug_fix-6d17f39afaa4

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

