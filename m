From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Tue, 31 Dec 2024 15:13:44 +0530
Subject: [PATCH v2 3/6] PCI/pwrctrl: Move pci_pwrctrl_unregister() to
 pci_destroy_dev()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241231-pci-pwrctrl-slot-v2-3-6a15088ba541@linaro.org>
References: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
In-Reply-To: <20241231-pci-pwrctrl-slot-v2-0-6a15088ba541@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Qiang Yu <quic_qianyu@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Lukas Wunner <lukas@wunner.de>, 
 Bartosz Golaszewski <bartosz.golaszewski@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1293;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=R/h8mRffg4ftb0mSxAjhuMkQ2AXNpRy+KTjYeuy7GyY=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBnc7zqe/gxeg/v0jwc0tTdNPblhXylvQuh5P3pm
 uD8mA3Lzy2JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZ3O86gAKCRBVnxHm/pHO
 9Ym1B/4rWPv8lWQeEs4wVzLMvuKJ2+Bw9inpcseTx8Fp78JHx7SvU58LyUKncjTs5Zgql2CmBij
 TAjENRBZe4G/xUcAwFBxmbKUFB8beiO4YCV+Uar8NfEeQW4hb2zD83VRHJTHvglGxk48LI6kflQ
 +0Y1wGsOk42NLIAkimf/bhPZehhvTgiE1NRgFUH2LjjMJGqtzPtJ2N+QpqPVuQVUjJFqU5NMWok
 fpyP+ev3iDbwhZjjzJpspXbaYegoERYMcav0GZa31tq8WhYdm7en7AW492hNaS+JigrG5XDv1l1
 G2/RZRAuMZp/YLJkPFX2+5RMFima3rmybEt/boxIU0AbDNbB
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

