From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/3] ufs: qcom: Fix probe failure on SM8550 SoC due to
 broken SDBS field
Date: Wed, 14 Aug 2024 22:45:33 +0530
Message-Id: <20240814-ufs-bug-fix-v1-0-5eb49d5f7571@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADXmvGYC/x2MQQqAIBAAvyJ7bkFFSvpKdMhabS8WihGIf086z
 sBMhUyJKcMsKiR6OPMVO6hBwH5uMRDy0Rm01EZaZbD4jK4E9PyiMXryTipnRwm9uBN1/d+WtbU
 P2w4f2l0AAAA=
To: Alim Akhtar <alim.akhtar@samsung.com>, 
 Avri Altman <avri.altman@wdc.com>, Bart Van Assche <bvanassche@acm.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Kyoungrul Kim <k831.kim@samsung.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=956;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=sXb5Xiro8MMMUjfccTn033XzuQ3HAuq5W9g4P6QXTk8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmvOY3Y4kE4h7MJI+1mE7wM5BWinEHEnY30bAO1
 JR4NLH8tHuJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZrzmNwAKCRBVnxHm/pHO
 9VfjB/kBuingfo75GYcDWtJsbTxQ8j/onH8QYvbibmGzRHAml3/DzbaPypmohIdpNgaHW73xZXt
 ZQmAqMKbEB5zFYVNKV+u34ZfOUMhQYk8EdZ2PiUyZ3zl6pDjWfnaiV8mGP8BIwzA4p+6dVVl2af
 Vg35XadJNM5UE4RhmL5mktH8zH8OZUiE554CUeNUFyzQaqsobt57t4Lixj3qPYhTHKalt3YhRpN
 LLppR5EwxVNNKaCJKq/Y+aCyTlXMnBp0MPXD0UcxCm/kDnjCMuP/b6uQ72CWxTWkLzPXZPFPK6o
 vnN8PCVsZozTjeWA6ynB+gj3JfqACyYow4yp31RStcBiWH1N
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the probe failure on the Qcom SM8550 SoC due to the broken
SDBS field in the host controller capabilities register.

Please consider this series for v6.11 as it fixes a regression.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (3):
      ufs: core: Rename LSDB to SDBS to reflect the UFSHCI 4.0 spec
      ufs: core: Add a quirk for handling broken SDBS field in controller capabilities register
      ufs: qcom: Add UFSHCD_QUIRK_BROKEN_SDBS_CAP for SM8550 SoC

 drivers/ufs/core/ufshcd.c   | 9 +++++----
 drivers/ufs/host/ufs-qcom.c | 6 +++++-
 include/ufs/ufshcd.h        | 9 ++++++++-
 include/ufs/ufshci.h        | 2 +-
 4 files changed, 19 insertions(+), 7 deletions(-)
---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240814-ufs-bug-fix-4427fb01b860

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

