From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/2] net: qrtr: Drop the MHI 'auto_queue' feature
Date: Thu, 18 Dec 2025 22:21:43 +0530
Message-Id: <20251218-qrtr-fix-v2-0-c7499bfcfbe0@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB8xRGkC/22MQQ6CMBBFr0Jm7ZBOFa2uvIdh0bSDNBEqLRIN6
 d0dWbv5yXv5eStkToEzXKoVEi8hhzgK6F0FrrfjnTF4YdBKN6TphFOaE3bhjU41Rpw3nizI/Zl
 Y9Ja6tcJ9yHNMn6280M/+iSyECrsjHbTdszt7c40519PLPlwchloG2lLKFxUi2w6nAAAA
X-Change-ID: 20251217-qrtr-fix-c058251d8d1a
To: Jeff Hugo <jeff.hugo@oss.qualcomm.com>, 
 Carl Vanderlip <carl.vanderlip@oss.qualcomm.com>, 
 Oded Gabbay <ogabbay@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Johnson <jjohnson@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Maxim Kochetkov <fido_max@inbox.ru>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, mhi@lists.linux.dev, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 ath12k@lists.infradead.org, netdev@vger.kernel.org, 
 Bjorn Andersson <andersson@kernel.org>, Johan Hovold <johan@kernel.org>, 
 Chris Lew <quic_clew@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2023;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=NWdJvH9yOqg1eTTYzzMYejBHNkyExdCjfVBKS/HDM44=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpRDEi+Khc2ZOmm08ikV3hNuslUf4Bh48CandeI
 RWNP6g/wIqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaUQxIgAKCRBVnxHm/pHO
 9cemB/4vwlTSkc1bcE9+WVu8UZBpxkiHP576YpiTakv5EZxlkFChtASnSg5UjtwhIOXzyOgFQy2
 pEEenMNY623MJgBh7dLPRFliZcUk5vqRoynw9xyZoFq0N6+a/Wl9StpbTruRRUlKCZjV45RTnF5
 DPEocovrNLBl0IOuhO2IaNLl28iwB47Rijj/8/14ZY5n7SuWdm6C+s/SX72/nLlSvghNYhlikR/
 GoWwVOwRzqgutCV9wESS0ljwkenQpfx+gNiQv4hbEG7rCIPWPNwzOROxvllQTFCimCsVVbthY/h
 etHKiqG93rCOK9WO1mHhSY/l8rE53ViVBptce8Tt1ed0goJG
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series intends to fix the race between the MHI stack and the MHI client
drivers due to the MHI 'auto_queue' feature. As it turns out often, the best
way to fix an issue in a feature is to drop the feature itself and this series
does exactly that.

There is no real benefit in having the 'auto_queue' feature in the MHI stack,
other than saving a few lines of code in the client drivers. Since the QRTR is
the only client driver which makes use of this feature, this series reworks the
QRTR driver to manage the buffer on its own.

Testing
=======

Tested on Qcom X1E based Lenovo Thinkpad T14s laptop with WLAN device.

Merge Strategy
==============

Since this series modifies many subsystem drivers, I'd like to get acks from
relevant subsystem maintainers and take the series through MHI tree.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v2:
- Used mhi_get_free_desc_count() to queue the buffers
- Collected tags
- Link to v1: https://lore.kernel.org/r/20251217-qrtr-fix-v1-0-f6142a3ec9d8@oss.qualcomm.com

---
Manivannan Sadhasivam (2):
      net: qrtr: Drop the MHI auto_queue feature for IPCR DL channels
      bus: mhi: host: Drop the auto_queue support

 drivers/accel/qaic/mhi_controller.c   | 44 -------------------
 drivers/bus/mhi/host/init.c           | 10 -----
 drivers/bus/mhi/host/internal.h       |  3 --
 drivers/bus/mhi/host/main.c           | 81 +----------------------------------
 drivers/bus/mhi/host/pci_generic.c    | 20 +--------
 drivers/net/wireless/ath/ath11k/mhi.c |  4 --
 drivers/net/wireless/ath/ath12k/mhi.c |  4 --
 include/linux/mhi.h                   | 14 ------
 net/qrtr/mhi.c                        | 69 ++++++++++++++++++++++++-----
 9 files changed, 62 insertions(+), 187 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251217-qrtr-fix-c058251d8d1a

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

