From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/3] scsi: ufs: qcom: Suspend fixes
Date: Wed, 11 Dec 2024 23:10:15 +0530
Message-Id: <20241211-ufs-qcom-suspend-fix-v1-0-83ebbde76b1c@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH/OWWcC/x2MSQqAMAwAvyI5GzB1Qf2KeJA2ag5WbagI4t8tH
 mdg5gHlIKzQZw8EvkRl9wkoz8Cuk18YxSUGU5iKDBHGWfG0+4Ya9WDvcJYb64Za7mzduK6ElB6
 Bk/63w/i+H+hB7tlmAAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1691;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=nTPLx+F/uIjNlE3QmhI8zO7IqE2vvW6UobaEj+4tukI=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYkiPPNf60/Tk6StscSpJE6I7pL7Fr73e7JXqOsstcGmq4
 Jo3b5gudjIaszAwcjHIiimypC911mr0OH1jSYT6dJhBrEwgUxi4OAVgImXf2H8xc0WrWzOuPzix
 Nl7GWiLB/0w8h/zzxC+fY/6ZZfx+4bqKaaX+bWEJHuPMRCejr9ssWLbpN07sK243+rQksmnH/co
 lTDWVUmnt674L2bVFKjw4cfQBowF//PS3m33KK7aZHTTXXrjj5GvjnEWmzjYcp6fbbsi8sv5P/y
 Ld3NsTWMXW/ynbd5nl5lT5Z6FKfKriHt+dU56xHbgcn7ZT6PPN9KDCBe39V6Q7Fp9NyjU93VD6g
 4NTcGW7gFZ/mZqs8ERDNV2pL47Ln4gZ9PDZNrH9U32kYC8Tc1NEgWH6qafnDFZdLb2dpZn1bmvU
 DO5YH4kirTO3TmxW+PnRPMI1MnhZimfYDiePOy5N9uJZAA==
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes the several suspend issues on Qcom platforms. Patch 1 fixes
the resume failure with spm_lvl=5 suspend on most of the Qcom platforms. For
this patch, I couldn't figure out the exact commit that caused the issue. So I
used the commit that introduced reinit support as a placeholder.

Patch 3 fixes the suspend issue on SM8550 and SM8650 platforms where UFS
PHY retention is not supported. Hence the default spm_lvl=3 suspend fails. So
this patch configures spm_lvl=5 as the default suspend level to force UFSHC/
device powerdown during suspend. This supersedes the previous series [1] that
tried to fix the issue in clock drivers.

This series is tested on Qcom SM8550 MTP and Qcom RB5 boards.

[1] https://lore.kernel.org/linux-arm-msm/20241107-ufs-clk-fix-v1-0-6032ff22a052@linaro.org

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Manivannan Sadhasivam (3):
      scsi: ufs: qcom: Power off the PHY if it was already powered on in ufs_qcom_power_up_sequence()
      scsi: ufs: qcom: Allow passing platform specific OF data
      scsi: ufs: qcom: Power down the controller/device during system suspend for SM8550/SM8650 SoCs

 drivers/ufs/core/ufshcd-priv.h |  6 ------
 drivers/ufs/core/ufshcd.c      |  1 -
 drivers/ufs/host/ufs-qcom.c    | 31 +++++++++++++++++++------------
 drivers/ufs/host/ufs-qcom.h    |  5 +++++
 include/ufs/ufshcd.h           |  2 --
 5 files changed, 24 insertions(+), 21 deletions(-)
---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241211-ufs-qcom-suspend-fix-5618e9c56d93

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

