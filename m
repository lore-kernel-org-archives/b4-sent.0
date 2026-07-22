From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/3] bus: mhi: ep: Implement flush_async() callback to
 flush async read/write
Date: Wed, 22 Jul 2026 07:54:43 +0200
Message-Id: <20260722-mhi-ep-flush-v3-0-d855e715264e@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACRbYGoC/23O0Q6CIBQG4FdpXIcDCtCueo/WhegxaCoGymrOd
 w9srdW6Odu//ec7Z0YenAGPDpsZOQjGG9vHsNtuUKXL/gLY1DEjRpgggkncaYNhwE07eY0VJ5w
 wSfOyqFFcGRw05r5yp/Mr+0ldoRqTkRra+NG6x3ov0NR708U3HSgmWNI9kJoLyGV1tN5nt6lsK
 9t1WRwoXQjsY8T2j8GioUR8ThFKIed/jGVZnqiiB70FAQAA
X-Change-ID: 20260627-mhi-ep-flush-b50502718a9d
To: Manivannan Sadhasivam <mani@kernel.org>, Frank Li <Frank.Li@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-kernel@vger.kernel.org, mhi@lists.linux.dev, 
 linux-arm-msm@vger.kernel.org, linux-pci@vger.kernel.org, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1910;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Lhh0pqvxZoxlABvQd8zbDNaeva+7Z1BTwO8UUZ1oIrw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqYFspGU0BzEtM5HB3eyjwS5mMq6xKzReuGhSoo
 Yw9Y/POS2SJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamBbKQAKCRBVnxHm/pHO
 9TtqCACDRwgBzyex4JmTeNdB2W2tKUwwjAvK0laFYJMUjiX80/1+PT+QFZcqrZ4kTUPTXB0OuAB
 4dfOJmv/qFbkAQdWzEC24QTLXXBPKPuxcycVka5FpnhF9df4NXuU/e1tt95yR90ACGuN1ct/NlV
 2qE7vbeJWEoni2fv5w230AUqnoFbbCLUjePCmRITz2n/FtwC4CUe6SXpzmlM5M+GJjzF+qzy0iF
 gqV3Dgd+KBK8/QIdmuFAHzxLpTrXqive2tW9b6SrV24cqSHhHExtXp+PiHHqUOmFEKHqZCTPD0d
 tYL0Oy0/ygdIrigH0yWMYfZIhlCgu92lsDAHu7wvWqwyEqle
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series introduces a new mhi_cntrl->flush_async() callback to flush the
async read/write operations performed by the MHI controller using offload
mechanisms such as DMA.

The MHI EPF driver implements this callback by flushing the DMA wq. With this
series, the MHI EP stack can guarnatee that the channel specific xfer_cb() won't
be run after calling mhi_ep_remove() and mhi_ep_abort_transfer().

Merge Strategy
==============

Both MHI and PCI EP changes should go together. So I'm planning to take both
MHI and PCI EP patches through MHI tree.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v3:
- Dropped the dmaengine patch as a variant of it already got merged into
  dmaengine tree
- Move flush_async() callback before triggering ENOTCONN
- Link to v2: https://patch.msgid.link/20260714-mhi-ep-flush-v2-0-b6a9db011e85@oss.qualcomm.com

Changes in v2:
- Switched to read_poll_timeout() in dw_edma_device_synchronize()
- Switched to dmaengine_synchronize() in pci_epf_mhi_edma_flush_async()
- Link to v1: https://patch.msgid.link/20260629-mhi-ep-flush-v1-0-714e0d56e87c@oss.qualcomm.com

---
Manivannan Sadhasivam (3):
      bus: mhi: ep: Add mhi_cntrl->flush_async() callback to flush the async read/write
      bus: mhi: ep: Flush async transfers before notifying disconnect in mhi_ep_abort_transfer()
      PCI: epf-mhi: Implement mhi_cntrl->flush_async() to flush DMA read/write

 drivers/bus/mhi/ep/main.c                    | 41 +++++++++++++++++++++++-----
 drivers/pci/endpoint/functions/pci-epf-mhi.c | 10 +++++++
 include/linux/mhi_ep.h                       |  2 ++
 3 files changed, 46 insertions(+), 7 deletions(-)
---
base-commit: 4549871118cf616eecdd2d939f78e3b9e1dddc48
change-id: 20260627-mhi-ep-flush-b50502718a9d

Best regards,
--  
மணிவண்ணன் சதாசிவம்

