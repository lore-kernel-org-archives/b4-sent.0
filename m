From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 03 Sep 2025 12:43:24 +0530
Subject: [PATCH v2 2/5] PCI/pwrctrl: Move pci_pwrctrl_init() before turning
 ON the supplies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-pci-pwrctrl-perst-v2-2-2d461ed0e061@oss.qualcomm.com>
References: <20250903-pci-pwrctrl-perst-v2-0-2d461ed0e061@oss.qualcomm.com>
In-Reply-To: <20250903-pci-pwrctrl-perst-v2-0-2d461ed0e061@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Saravana Kannan <saravanak@google.com>
Cc: linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Brian Norris <briannorris@chromium.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2110;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=R+1x069ihDCZtvKq09JWHM41uYbGfvNk9pQz/Px8wHE=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBot+qbO/xAACNP9KEFSGn85ypDyLWrklnda6PLW
 A/JAA7/dF2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaLfqmwAKCRBVnxHm/pHO
 9a/oB/9cLJ/bC8+2232mXn53qeplk4yY1tuKr3ytZ4bABj//fCdG3P3vCCRDdcK1h/cEJTaTwFe
 WFo8qg4ztA2dZ44hYfAsMTuBxQevynq+o3D3aCZFFBgfNka4o79kUljSLOgw8PiBmgtaCIo5KQf
 PkpV0pWqoLid6lJyjGzEYLUCFi5XLwBNH8/Rjhxh7nO/i6Mt0XRPFGgBwSxY7PMftEg1EWmUBo6
 u3tHO73tWhyPNIn0ni6o4NW2pGXKfTl9z8a8gy5+ea4tGN4w9Jlrj0xRGI0weKG+FTvosjGtrPF
 fZ0uT7oIiuOiFd+9B5SYQuu7HpaRXLncvPkJDdAOj3YVrtjv
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To allow pwrctrl core to parse the generic resources such as PERST# GPIO
before turning on the supplies.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c | 4 ++--
 drivers/pci/pwrctrl/slot.c               | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
index 4e664e7b8dd23f592c0392efbf6728fc5bf9093f..b65955adc7bd44030593e8c49d60db0f39b03d03 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-pwrseq.c
@@ -80,6 +80,8 @@ static int pci_pwrctrl_pwrseq_probe(struct platform_device *pdev)
 	if (!data)
 		return -ENOMEM;
 
+	pci_pwrctrl_init(&data->ctx, dev);
+
 	data->pwrseq = devm_pwrseq_get(dev, pdata->target);
 	if (IS_ERR(data->pwrseq))
 		return dev_err_probe(dev, PTR_ERR(data->pwrseq),
@@ -95,8 +97,6 @@ static int pci_pwrctrl_pwrseq_probe(struct platform_device *pdev)
 	if (ret)
 		return ret;
 
-	pci_pwrctrl_init(&data->ctx, dev);
-
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &data->ctx);
 	if (ret)
 		return dev_err_probe(dev, ret,
diff --git a/drivers/pci/pwrctrl/slot.c b/drivers/pci/pwrctrl/slot.c
index 6e138310b45b9f7e930b6814e0a24f7111d25fee..b68406a6b027e4d9f853e86d4340e0ab267b6126 100644
--- a/drivers/pci/pwrctrl/slot.c
+++ b/drivers/pci/pwrctrl/slot.c
@@ -38,6 +38,8 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 	if (!slot)
 		return -ENOMEM;
 
+	pci_pwrctrl_init(&slot->ctx, dev);
+
 	ret = of_regulator_bulk_get_all(dev, dev_of_node(dev),
 					&slot->supplies);
 	if (ret < 0) {
@@ -63,8 +65,6 @@ static int pci_pwrctrl_slot_probe(struct platform_device *pdev)
 				     "Failed to enable slot clock\n");
 	}
 
-	pci_pwrctrl_init(&slot->ctx, dev);
-
 	ret = devm_pci_pwrctrl_device_set_ready(dev, &slot->ctx);
 	if (ret)
 		return dev_err_probe(dev, ret, "Failed to register pwrctrl driver\n");

-- 
2.45.2

