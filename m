From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 10 Dec 2024 15:25:25 +0530
Subject: [PATCH 2/4] PCI/pwrctrl: Move pci_pwrctrl_unregister() to
 pci_destroy_dev()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241210-pci-pwrctrl-slot-v1-2-eae45e488040@linaro.org>
References: <20241210-pci-pwrctrl-slot-v1-0-eae45e488040@linaro.org>
In-Reply-To: <20241210-pci-pwrctrl-slot-v1-0-eae45e488040@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Lukas Wunner <lukas@wunner.de>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1183;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=AayP0uLiPqt9crxsUCoYXhcBPjoCZ1TdOHW8vyCvx84=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnWBAo0ccwM9RwPmxonJZbhJqQZ/aygLDUZl/ho
 zzelFF38iaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ1gQKAAKCRBVnxHm/pHO
 9ZRSB/9NkA7rMJDFCACTjRyMDLunQF78A/Py/7vGsmzIRWlriF3rwvg8Zn59bTAyFjcrmPezP2j
 iglCPGrVcbwDjDuCGb0rInMbEBj/hwFyITq6FQEeZjE3ryXMqZZwjKXFBi6qhLIYY11Ias4y2M1
 Le3mJBEigq9t0wOZVmrIkYVoUokAfHTtDJ6HWlyXRabI2pzKNETFu61qCgVmdHAjsTyf98TV340
 iXVA6tsUnm3ZWk9NvLG740865eD7uTK73FsZ44XRFxeWey/60+05stSiNAL8Uzq/y9SvCGeOCvA
 R2GQ+y7DVlO61DKQu80mpbj8uDWTLdyIlebhFN7mTAjw4BVk
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

