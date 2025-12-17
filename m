From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/2] net: qrtr: Drop the MHI 'auto_queue' feature
Date: Wed, 17 Dec 2025 22:46:50 +0530
Message-Id: <20251217-qrtr-fix-v1-0-f6142a3ec9d8@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAILlQmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0Nz3cKikiLdtMwK3WQDUwugWIpFimGiElB5QVEqUBhsVHRsbS0AovM
 Jm1oAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1833;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=nCNmapLXVkzx5G0AMg0w1rDB82qxLQX+MYjj3DhiKp4=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpQuWLGsKVi00BM9j9k2fzmDyfhFZKHkWaVpwxL
 mEyD11ffiGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaULliwAKCRBVnxHm/pHO
 9dflCACJcSVT7YDyfd1eVp65ty6CysudUmNCdkpwxqBUbCrnGNo3J5HA5Hjn0fxfolTcFBBLQ07
 NeDnBv7hbBbeyy/YGPc7B2nWrkzT2oE/O6mX1dmUEBSjUBVMBq+M2qerwQHpjy3mT6EmN+lLYuk
 EoZKz4737MjFD7GJoeu4mMQuQOXQ86hQRcwpELNcqSYNc+8fep+/5IiIPQ2NgkCKu4cKF+CAANE
 NmFlrFhiohovN3SfcwHdt4M3dZd2Klsd1aCphMoU9i8/gw1xIHR1cGHhWU1Y6+l7SUkLrL6jBh+
 YTWv2owV7o/wUYhLImCgqMf3xtU5X3/Kt/L/XHl60z1w9ez8
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
 net/qrtr/mhi.c                        | 67 ++++++++++++++++++++++++-----
 9 files changed, 60 insertions(+), 187 deletions(-)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251217-qrtr-fix-c058251d8d1a

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

