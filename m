From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 22 Oct 2024 15:57:33 +0530
Subject: [PATCH 5/5] PCI/pwrctl: Remove pwrctl device without iterating
 over all children of pwrctl parent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241022-pci-pwrctl-rework-v1-5-94a7e90f58c5@linaro.org>
References: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
In-Reply-To: <20241022-pci-pwrctl-rework-v1-0-94a7e90f58c5@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <dmitry.baryshkov@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Abel Vesa <abel.vesa@linaro.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1846;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=Fx4nsEA2QZpP1ERShZZ8bZw3IQBN6+Um75DdA2nrjyg=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnF34v/nlnaSD9lCRQmkUSbC0gN51VH+Ya8loNI
 VZhLq3xK7eJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZxd+LwAKCRBVnxHm/pHO
 9WpUCACKafJIXVlw/tZAI/sQS1x6dJE+i6hX9zJsxTo/DczSyuwA6FHOswiX8NHCLJZyYTyspGt
 rFNtE5+WOuWGABNRXUvTZLGAOJZljL1UHYFJMkPRzuLUfFhTPjuEJ2aXkYTFz6tJaaAoah74P8r
 hUrkZve4eH0d3qRD3NDeZuwBIhT0ZyGPN9j32ESnqYhBhyuY6vxemjBM38NAWSDFc5gUdSBufzA
 Lwa8k652Feas0X9FUPl+RrPjjq/Yot8oDfpSiKhAnPQNYLinqbLfb6vrAbphM9VMDRv35P01xNY
 lgPl05mHeyzVat+aw1w4oGVinO277ji4pUNpIEanlGGfbcHs
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

