From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/2] PCI/pwrctrl: A couple of fixes
Date: Mon, 23 Feb 2026 20:15:58 +0530
Message-Id: <20260223-pwrctrl-fixes-7-0-v2-0-97566dfb1809@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACZonGkC/32NQQ6CMBREr0L+2pK2CBVW3sOwoPUjTYBiP1YN6
 d0tHMDNJG8mM7MBobdI0GQbeAyWrJsTyFMGZujmBzJ7TwySy4pLodjy9mb1I+vtB4kpxpmuOeq
 Ca92jgtRbPB5hqt3axIOl1fnvcRHE7v5bC2KfLCslsLzUxbm/OqL8+epG46YpTwJtjPEH5dUs/
 7kAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1760;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=0oOacB7wekfab+QGwcpYIGrgFEdHi1JQuMOHXuEbmYE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpnGgpmt4euzNlq9RltGhY8m2X7sgkRa8vB45wV
 NBkzXb+7K2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaZxoKQAKCRBVnxHm/pHO
 9Y48B/wJzuwMEfa6vNHi9r0Gd95e9L7tbzABDyDIZDY+B76k4pE95SFkhRhQz8IOwgk0Wp5k6lc
 ++WYLoIiw5YGqnaHbq9+grzTVygO1oQQqiqVQme+EWNBmhfn3kzf71H1qMgBn/N5dEoX7jkCbys
 yf4tdRILk+rR2C7MkvhljuiGYlETnXmRsI0bp2qDyToud2FwpFh9BR0eUlBql7B9NTMnMYTR7KP
 hd4kQUaw2B110rsfLncxb7mbpDfDhwwLYH3VNqIpz5pcfnEZH6W/mMmc0d/dQ8NQ6X243TE3eJn
 n3k+P9DK6wk1tzXr96oeICdXYu7V7Siz2ZZy572hFUsZ9or3
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

Note for Bjorn H
================

Even though only patch 1 is fixing a regression on the IPQ board which was not
part of the testbed of the pwrctrl rework went in for v7.0, patch 2 is also
fixing an actual issue, but it is not impacting any of the current upstream
supported platforms. But I'd like to get these two patches merged for v7.0 so
that both the issues are fixed in the same major release where the issues
originated.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v2:
- Used the compatible match for detecting the PCI devices in DT
- Link to v1: https://lore.kernel.org/r/20260217-pwrctrl-fixes-7-0-v1-0-b5671e58934f@oss.qualcomm.com

---
Manivannan Sadhasivam (2):
      PCI/pwrctrl: Ensure that the remote endpoint node parent has the supply requirement
      PCI/pwrctrl: Only create pwrctrl device if the device node belongs to a PCI device

 drivers/pci/pwrctrl/core.c | 54 +++++++++++++++++++++++++++++++++++-----------
 1 file changed, 41 insertions(+), 13 deletions(-)
---
base-commit: 1c2b4a4c2bcb950f182eeeb33d94b565607608cf
change-id: 20260217-pwrctrl-fixes-7-0-b90eb30bbfe7

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

