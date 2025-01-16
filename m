From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Thu, 16 Jan 2025 19:39:12 +0530
Subject: [PATCH v3 2/5] PCI/pwrctrl: Move pci_pwrctrl_unregister() to
 pci_destroy_dev()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-pci-pwrctrl-slot-v3-2-827473c8fbf4@linaro.org>
References: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
In-Reply-To: <20250116-pci-pwrctrl-slot-v3-0-827473c8fbf4@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Lukas Wunner <lukas@wunner.de>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1293;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=R/h8mRffg4ftb0mSxAjhuMkQ2AXNpRy+KTjYeuy7GyY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBniRMMOWMQy8+n9GIwCMLzD7wUlVwcsEa099OMM
 3k4LrMp4qSJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ4kTDAAKCRBVnxHm/pHO
 9fz3B/41s7dYud9Tcx8ri0aE9DFjyc7ivSLEw3hvTLDaM5fCfyUm/2yHb7XvUmp3DbMBB3lZW/n
 AHWZ+8yyUFj0CY74T9LbYWvmkJ0cQr4iwEf3yFJ7gsdCFb1upPxEtmshzWE5EhOiPDkmzlvXyGv
 EmYs4d2VTZaPEHS01+zStRE0JiFQp7TXu9INhxhvfa/NDshfkppWi1OcXcmm9nPhCHHWaroFWM3
 Nw3A+/d8Z5TsWHBj0SQHaCUiN+xQP+zbPzCM0/1UHrIFoE+Ae0o1TEvh56WZO/k9Uk+8moIEZC6
 AzBd5h4ih3U9xKPDJSbnUu4GxPoefXlr5OHoLpT6+/xrtPti
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PCI core will try to access the devices even after pci_stop_dev() for
things like Data Object Exchange (DOE), ASPM etc... So move
pci_pwrctrl_unregister() to the near end of pci_destroy_dev() to make sure
that the devices are powered down only after the PCI core is done with
them.

Suggested-by: Lukas Wunner <lukas@wunner.de>
Reviewed-by: Lukas Wunner <lukas@wunner.de>
Tested-by: Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/remove.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pci/remove.c b/drivers/pci/remove.c
index efc37fcb73e2..58859f9d92f7 100644
--- a/drivers/pci/remove.c
+++ b/drivers/pci/remove.c
@@ -41,7 +41,6 @@ static void pci_stop_dev(struct pci_dev *dev)
 	if (!pci_dev_test_and_clear_added(dev))
 		return;
 
-	pci_pwrctrl_unregister(&dev->dev);
 	device_release_driver(&dev->dev);
 	pci_proc_detach_device(dev);
 	pci_remove_sysfs_dev_files(dev);
@@ -64,6 +63,7 @@ static void pci_destroy_dev(struct pci_dev *dev)
 	pci_doe_destroy(dev);
 	pcie_aspm_exit_link_state(dev);
 	pci_bridge_d3_update(dev);
+	pci_pwrctrl_unregister(&dev->dev);
 	pci_free_resources(dev);
 	put_device(&dev->dev);
 }

-- 
2.25.1

