From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH v2 0/5] PCI/pwrctl: Ensure that the pwrctl drivers are
 probed before PCI client drivers
Date: Fri, 25 Oct 2024 13:24:50 +0530
Message-Id: <20241025-pci-pwrctl-rework-v2-0-568756156cbe@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMpOG2cC/32NQQqDMBBFryKz7pQkGKpd9R7iIk1HHSpGJhJbx
 Ls3eoAu3//89zeIJEwR7sUGQokjhymDuRTgBzf1hPzKDEaZUitjcPaM8yp+GVFoDfJGp59HaSt
 rLeTdLNTx53Q2beaB4xLke14kfaT/bEmjwrp0N6pVZytvHyNPTsI1SA/tvu8/7mwmobMAAAA=
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Krishna chaitanya chundru <quic_krichai@quicinc.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1932;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=/P9q2KbiK+vcSshfBjILffb3hynuvF5fiM7tfFtChPU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnG07Swl0G4ixBGpbr+vGMdccGZh0t6UayFam6Z
 lb+jRhARDOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxtO0gAKCRBVnxHm/pHO
 9ULRCACW7PS0HfebJvSt6rB4hkHg2sIdTDJJxVgdVvmfX0motvf7zRQpEVsBhCBakf83kuwdNh/
 +wiKL2PimBQbnxReXcmmQjCqRufHCSPxaPdl4KnnNCPr0fNxigeXBcU1WUJctymADBjSIS6T6yZ
 eG8r1IeyCmoq2lQWSwsEykPRg11bTyDzQ02810G26b4x7c5V3jQrQWE4GLzKgJxjeqIStwj7XL7
 M3pYz4hPauk0aHMqvhB6b/FfutLh1VdwTD9Gje+zLj9yHTp8U6RKOCq3bFxlLiXniUh2UcFddsx
 /4ml60f5t44g+dPvAUYYkoRBkqdMS8soTXSfT98GaOjRZtmA
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series reworks the PCI/pwrctl integration to ensure that the pwrctl drivers
are always probed before the PCI client drivers. This series addresses a race
condition when both pwrctl and pwrctl/pwrseq drivers probe parallely (even when
the later one probes last). One such issue was reported for the Qcom X13s
platform with WLAN module and fixed with 'commit a9aaf1ff88a8 ("power:
sequencing: request the WLAN enable GPIO as-is")'.

Though the issue was fixed with a hack in the pwrseq driver, it was clear that
the issue is applicable to all pwrctl drivers. Hence, this series tries to
address the issue in the PCI/pwrctl integration.

- Mani

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
Changes in v2:
- Used for_each_available_child_of_node_scoped() to iterate over child nodes
  (Bartosz)
- Collected tags
- Link to v1: https://lore.kernel.org/r/20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org

---
Manivannan Sadhasivam (5):
      PCI/pwrctl: Use of_platform_device_create() to create pwrctl devices
      PCI/pwrctl: Create pwrctl devices only if at least one power supply is present
      PCI/pwrctl: Ensure that the pwrctl drivers are probed before the PCI client drivers
      PCI/pwrctl: Move pwrctl device creation to its own helper function
      PCI/pwrctl: Remove pwrctl device without iterating over all children of pwrctl parent

 drivers/pci/bus.c         | 64 +++++++++++++++++++++++++++++++++++++++++------
 drivers/pci/of.c          | 27 ++++++++++++++++++++
 drivers/pci/pci.h         |  5 ++++
 drivers/pci/pwrctl/core.c | 10 --------
 drivers/pci/remove.c      | 17 ++++++-------
 5 files changed, 96 insertions(+), 27 deletions(-)
---
base-commit: 48dc7986beb60522eb217c0016f999cc7afaf0b7
change-id: 20241022-pci-pwrctl-rework-a1b024158555

Best regards,
-- 
Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>

