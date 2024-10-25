From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 25 Oct 2024 13:24:55 +0530
Subject: [PATCH v2 5/5] PCI/pwrctl: Remove pwrctl device without iterating
 over all children of pwrctl parent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241025-pci-pwrctl-rework-v2-5-568756156cbe@linaro.org>
References: <20241025-pci-pwrctl-rework-v2-0-568756156cbe@linaro.org>
In-Reply-To: <20241025-pci-pwrctl-rework-v2-0-568756156cbe@linaro.org>
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
 Krishna chaitanya chundru <quic_krichai@quicinc.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2043;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ZMmwlwCRSzjhOUE5z4PNfZQoS9fl60qTZUGrmIa0oTI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnG07UrEI+ygFFYRiJquOhxF3/HIbsroWH7tQhL
 aK5AVibzrqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxtO1AAKCRBVnxHm/pHO
 9RnwB/0Wzu1JRJdjBTy8WSMsnT+5odUgmGM2uRrgVJHOE75GND9wNiKEqdu3tffLo3uQIe4l+QN
 q2huoKlgRmUe88U77wsCXrHnZBdLjwByElTa4uP1CoSJfC7RJvx9a+2+BtWVezy4ufj0FYN/Ca/
 kC75FJPe4y8bCWDgA20i2nbRfZ1kUi56iOGrhN9QOUg4UHPaa7bewh0WAyDGsp5TcIE/Bz8gg41
 PbB0Q+ucWngtUGqsttOdjhn+CMjo+udGDfJgdC+aI2VdRbd1OYdgUe4xbMSuKwgkd65wmEXq1g2
 V+n8/BxngjXH+alX4zivvBwsnFiU42THzJRmBsptvG0Dk3b9
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no need to iterate over all children of the pwrctl device parent
to remove the pwrctl device. Since the pwrctl device associated with the
PCI device can be found using of_find_device_by_node() API, use it directly
instead.

If any pwrctl devices lying around without getting associated with the PCI
devices, then those will be removed once their parent device gets removed.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Tested-by: Krishna chaitanya chundru <quic_krichai@quicinc.com>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/remove.c | 17 ++++++++---------
 1 file changed, 8 insertions(+), 9 deletions(-)

diff --git a/drivers/pci/remove.c b/drivers/pci/remove.c
index e4ce1145aa3e..3dd9b3024956 100644
--- a/drivers/pci/remove.c
+++ b/drivers/pci/remove.c
@@ -17,16 +17,16 @@ static void pci_free_resources(struct pci_dev *dev)
 	}
 }
 
-static int pci_pwrctl_unregister(struct device *dev, void *data)
+static void pci_pwrctl_unregister(struct device *dev)
 {
-	struct device_node *pci_node = data, *plat_node = dev_of_node(dev);
+	struct platform_device *pdev;
 
-	if (dev_is_platform(dev) && plat_node && plat_node == pci_node) {
-		of_device_unregister(to_platform_device(dev));
-		of_node_clear_flag(plat_node, OF_POPULATED);
-	}
+	pdev = of_find_device_by_node(dev_of_node(dev));
+	if (!pdev)
+		return;
 
-	return 0;
+	of_device_unregister(pdev);
+	of_node_clear_flag(dev_of_node(dev), OF_POPULATED);
 }
 
 static void pci_stop_dev(struct pci_dev *dev)
@@ -34,8 +34,7 @@ static void pci_stop_dev(struct pci_dev *dev)
 	pci_pme_active(dev, false);
 
 	if (pci_dev_is_added(dev)) {
-		device_for_each_child(dev->dev.parent, dev_of_node(&dev->dev),
-				      pci_pwrctl_unregister);
+		pci_pwrctl_unregister(&dev->dev);
 		device_release_driver(&dev->dev);
 		pci_proc_detach_device(dev);
 		pci_remove_sysfs_dev_files(dev);

-- 
2.25.1

