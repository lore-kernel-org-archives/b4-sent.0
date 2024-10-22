From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Subject: [PATCH 0/5] PCI/pwrctl: Ensure that the pwrctl drivers are probed
 before PCI client drivers
Date: Tue, 22 Oct 2024 15:57:28 +0530
Message-Id: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABB+F2cC/x2MQQqAIBAAvxJ7bkElIfpKdCjbailM1sgg+nvWc
 RhmbogkTBGa4gahkyPvPoMuC3BL72dCHjODUabSyhgMjjEkcceGQmmXFXs9fNLW1lrIXRCa+Pq
 fbfc8L9a+InxjAAAA
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1703;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=6ZLo//vlVw/cpstTFieW8KdXJ1ymTE0OxNpZC2aia6w=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnF34u2ysVPAWfHEd/oykozMn0K7bPPcLmD1CXs
 49HCtvqZkqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxd+LgAKCRBVnxHm/pHO
 9XOkB/0U5taKt3+UYFHDZ7AaIxuqZpxsuNgJyD4TemD9BXMfO8b5ZhURh3kpeEo0q5SKlYWKfgt
 75N0oGi0QbnToJckFFljdF63od9c1xvrTCZmjpZdxTRqlWFReDA/6oZfr6tDcvyHNl5KQOLC239
 5eDPFCfz/B3W72ok8eQlQ4qni3syMszntnus75F/hloPO3sFMB8bJsvUa0Qk11oMfHLSQ/hRIn5
 FTaUnWhhL7AhJgLG0NDJsYRUPcZY869hJbdL36AYIsCPxNrxN6kWJstAetGiJDhexAXQeN4eQxX
 u/oPbiH7WfGVsrnzzXybcx6uabQBH5F10BDfdh/4TOquU+4R
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

