From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 30 Dec 2025 20:37:34 +0530
Subject: [PATCH v3 3/4] PCI: dwc: Rework the error print of
 dw_pcie_wait_for_link()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251230-pci-dwc-suspend-rework-v3-3-40cd485714f5@oss.qualcomm.com>
References: <20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com>
In-Reply-To: <20251230-pci-dwc-suspend-rework-v3-0-40cd485714f5@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=7kXiC+5h1EOCvJw9bEDf4bWdlgkGwkMaGfwFegH0XMU=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpU+q6W7XiwNgYjeIJKO9/5oCTCTTpJXIWw4ERM
 GMjRyRL+TGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaVPqugAKCRBVnxHm/pHO
 9V3GB/9lz+R75Apz6yGZipqwoZk96F4W2VhtMJl8fr9rz2mdwHWme6XPl33nCqj/T1qPbn73B90
 cPZyekANCa7kPXk1vJxJw3vMcouc6DB0qQsyIwL4SG+fi71kwahO15YPu77mNS/GAKNORm9X78C
 CK5wwjS/E/hCfNQwp29qqGB5aaXc+MB+QE960T2ooiwHkSS4EzkWSsgFFi+WsjxgP2IHITt6K4z
 n/GYmnYw7OvO0pYe9Q5cFdNvUNM+CpW/oDxmtanaJ3oEWyxBHgxbGPSlk8elcS8Ce0Q4WK9yE4N
 Zn8VG9xluChkrtW6+pto4Ne8v1fdGon2PHZCz0MlfyJjr00Q
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the link fails to come up even after detecting the device on the bus
i.e., if the LTSSM is not in Detect.Quiet and Detect.Active states, then
dw_pcie_wait_for_link() should log it as an error.

So promote dev_info() to dev_err(), reword the error log to make it clear
and also print the LTSSM state to aid debugging.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index 87f2ebc134d6..c2dfadc53d04 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -776,7 +776,8 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 			return -ENODEV;
 		}
 
-		dev_info(pci->dev, "Phy link never came up\n");
+		dev_err(pci->dev, "Link failed to come up. LTSSM: %s\n",
+			dw_pcie_ltssm_status_string(ltssm));
 		return -ETIMEDOUT;
 	}
 

-- 
2.48.1

