From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 15 Jan 2026 12:59:00 +0530
Subject: [PATCH v5 08/15] PCI/pwrctrl: pwrseq: Factor out power on/off code
 to helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-pci-pwrctrl-rework-v5-8-9d26da3ce903@oss.qualcomm.com>
References: <20260115-pci-pwrctrl-rework-v5-0-9d26da3ce903@oss.qualcomm.com>
In-Reply-To: <20260115-pci-pwrctrl-rework-v5-0-9d26da3ce903@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Jingoo Han <jingoohan1@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Chen-Yu Tsai <wens@kernel.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Alex Elder <elder@riscstar.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2150;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=JHrbYm0MBMvXv/ITz+NZpdT3DemZUsxJlhMJ+bLoqgI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpaJdCLg0hv0wiCQQY+RrdABbaInR/UH4Tr6q28
 Rz0i3rRUlGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaWiXQgAKCRBVnxHm/pHO
 9WZqCACp7B8c29oI68xxUbwuzdig4zsUerAKiA8nHS4Sss8isxZkq1Zwa3ciXn7YroEnovDGY+/
 WsVPO0oyACmZi8mM5BsU3ieMxX9aG2clktFWzaQxMDHRTxs4L7rlGOAErWta1LPlOdJ49XuJJ96
 5+E5iEnSjSX1l1axWfZPNDq+a9uRy6LeLc/rj7qeGAoMcb6CCyHfm0pb7Gqdyh33RzK6jtllZ59
 4IG+6HU/gVCk9ggO2LfDX6k8y5a26+bqxQXYOGWeFuzcMakn7rjDQ9T1C0otSNo1SmL0HjtfP12
 tiDPPOQxtL0iyof5EGTy5MpQygd0EUUL1S+3Wa2VEizBZG8D
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to allow the pwrctrl core to control the power on/off logic of the
pwrctrl pwrseq driver, move the power on/off code to
pci_pwrctrl_pwrseq_power_{off/on} helper functions.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c | 24 ++++++++++++++++++++----
 1 file changed, 20 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
index c0d22dc3a856..d2c261b09030 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
@@ -52,11 +52,27 @@ static const struct pci_pwrctrl_pwrseq_pdata pci_pwrctrl_pwrseq_qcom_wcn_pdata =
 	.validate_device = pci_pwrctrl_pwrseq_qcm_wcn_validate_device,
 };
 
+static int pci_pwrctrl_pwrseq_power_on(struct pci_pwrctrl *pwrctrl)
+{
+	struct pci_pwrctrl_pwrseq *pwrseq = container_of(pwrctrl,
+					    struct pci_pwrctrl_pwrseq, pwrctrl);
+
+	return pwrseq_power_on(pwrseq->pwrseq);
+}
+
+static int pci_pwrctrl_pwrseq_power_off(struct pci_pwrctrl *pwrctrl)
+{
+	struct pci_pwrctrl_pwrseq *pwrseq = container_of(pwrctrl,
+					    struct pci_pwrctrl_pwrseq, pwrctrl);
+
+	return pwrseq_power_off(pwrseq->pwrseq);
+}
+
 static void devm_pci_pwrctrl_pwrseq_power_off(void *data)
 {
-	struct pwrseq_desc *pwrseq = data;
+	struct pci_pwrctrl_pwrseq *pwrseq = data;
 
-	pwrseq_power_off(pwrseq);
+	pci_pwrctrl_pwrseq_power_off(&pwrseq->pwrctrl);
 }
 
 static int pci_pwrctrl_pwrseq_probe(struct platform_device *pdev)
@@ -85,13 +101,13 @@ static int pci_pwrctrl_pwrseq_probe(struct platform_device *pdev)
 		return dev_err_probe(dev, PTR_ERR(pwrseq->pwrseq),
 				     "Failed to get the power sequencer\n");
 
-	ret = pwrseq_power_on(pwrseq->pwrseq);
+	ret = pci_pwrctrl_pwrseq_power_on(&pwrseq->pwrctrl);
 	if (ret)
 		return dev_err_probe(dev, ret,
 				     "Failed to power-on the device\n");
 
 	ret = devm_add_action_or_reset(dev, devm_pci_pwrctrl_pwrseq_power_off,
-				       pwrseq->pwrseq);
+				       pwrseq);
 	if (ret)
 		return ret;
 

-- 
2.48.1

