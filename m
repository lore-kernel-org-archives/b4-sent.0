From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH 0/2] PCI/pwrctrl: A couple of fixes
Date: Tue, 17 Feb 2026 15:48:45 +0530
Message-Id: <20260217-pwrctrl-fixes-7-0-v1-0-b5671e58934f@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIVAlGkC/x3L0QpAQBBA0V/RPJsaq2z8ijzYNcuUlmaFkn+3e
 Tzd7gOJVThBVzygfEqSLWZUZQF+GePMKFM2GDINmcrifqk/dMUgNye0SOhaYleTc4Et5G9X/mP
 e+uF9P3EfxHtjAAAA
X-Change-ID: 20260217-pwrctrl-fixes-7-0-b90eb30bbfe7
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1121;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=mk61giFA4xV0eLiVM9N9Pk4Frb15EFC/PHziiymACBE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBplECJmIxMp8QWihoHmtHt2sppe24sig6aGRzb0
 zqu28jutDOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZRAiQAKCRBVnxHm/pHO
 9XEAB/4ygWviF5uNJoltOELiKg418BuWOKetvdb2DITohmc74t8Pd0vP8ZePWSbdMDyd+u9+SBA
 e9vSEaVWKWAxdwwuCykqjealjjb8Xa9k15nmVWYxuuKJ2kX9mWDSxpxRH4xq9AA1NUxDmAf+zgO
 NV3sXLWSczgSDRJdjbli/8iHAfOWWAfY3ljEBkPPBpA0JZAkGRf2kHUAmkljeTyVJrDsWiC3Cim
 Bk5rM6CZ3py8oBsYdPxDsoIYZAAkN6KAm2utZWwnEAAnxJIPiD00HV+ZAcF3B/GX5My1ki/p38v
 TymnfKFFDa3/u7EWh4Tcw7aaFVOVYyiwqz3DMRxnd9ArN+6l
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes a couple of issues introduced in the recent pwrctrl rework
for v7.0. Both issues are due to some incorrect assumptions on deciding when to
create pwrctrl devices. First issue is due to assuming that all OF graph nodes
require pwrctrl and another one is due to assuming that all PCI child nodes are
PCI devices.

Both issues are fixed by changing the pwrctrl device creation logic in
pwrctrl/core.

Testing
=======

This series is tested on Lenovo Thinkpad T14s.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Manivannan Sadhasivam (2):
      PCI/pwrctrl: Ensure that the remote endpoint node parent has the supply requirement
      PCI/pwrctrl: Only create pwrctrl device if the device node is of type "pci"

 drivers/pci/pwrctrl/core.c | 51 ++++++++++++++++++++++++++++++++++------------
 1 file changed, 38 insertions(+), 13 deletions(-)
---
base-commit: 1c2b4a4c2bcb950f182eeeb33d94b565607608cf
change-id: 20260217-pwrctrl-fixes-7-0-b90eb30bbfe7

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

