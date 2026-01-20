From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 20 Jan 2026 23:17:43 +0530
Subject: [PATCH v4 4/5] PCI: dwc: Rework the error print of
 dw_pcie_wait_for_link()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260120-pci-dwc-suspend-rework-v4-4-2f32d5082549@oss.qualcomm.com>
References: <20260120-pci-dwc-suspend-rework-v4-0-2f32d5082549@oss.qualcomm.com>
In-Reply-To: <20260120-pci-dwc-suspend-rework-v4-0-2f32d5082549@oss.qualcomm.com>
To: Jingoo Han <jingoohan1@gmail.com>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 vincent.guittot@linaro.org, zhangsenchuan@eswincomputing.com, 
 Shawn Lin <shawn.lin@rock-chips.com>, Niklas Cassel <cassel@kernel.org>, 
 Richard Zhu <hongxing.zhu@nxp.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1220;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Rybke+Ur+gqq01x6BcV5V2xkaSwi4rJ9Q7iHSJqNsh0=;
 b=owGbwMvMwMUYOl/w2b+J574ynlZLYsjM338gqCWV5XC1qfOXGMYLN5nOZ65fOn/7/AZRtpX2i
 YnCmflenYzGLAyMXAyyYoos6UudtRo9Tt9YEqE+HWYQKxPIFAYuTgGYyLf17H+FzJhuNidPbUxo
 yr67LEHtWWOsoZGDsI8bb5bBi7ynXJq5XhXvvIpzNHf9tQiW3Xfr4A0xnVOrl+r5VB8VNXkxMbX
 lY5dySvwlk4S9b50OJHHtq6xuV1ge6e+n77OJ+ek225OZ9gZNa6ON6owatRdr+AUKzZx31eAwy7
 +beZnMk9Xux83cvFWMgVMhySxkfuh37fnlKyMSH3i71ZTecLJ8E1ufuFf7c4xceM+UKv6TTRzLu
 iyeCOs0uNax/bK1yEubvYKrNqfpWA23M6ei/TGH9WEH/cTWVRea361Yt052apacwfSKyjkBhvtY
 GZgbJk9dfFU99da5GQbPtn1Wfml6uoHT/1ykz6b5icEA
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the link fails to come up even after detecting the device on the bus
i.e., if the LTSSM is not in Detect.Quiet and Detect.Active states, then
dw_pcie_wait_for_link() should log it as an error.

So promote dev_info() to dev_err(), reword the error log to make it clear
and also print the LTSSM state to aid debugging.

Tested-by: Richard Zhu <hongxing.zhu@nxp.com>
Tested-by: Vincent Guittot <vincent.guittot@linaro.org>
Reviewed-by: Shawn Lin <shawn.lin@rock-chips.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/controller/dwc/pcie-designware.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.c b/drivers/pci/controller/dwc/pcie-designware.c
index f74eae79cca4..2fa9f6ee149e 100644
--- a/drivers/pci/controller/dwc/pcie-designware.c
+++ b/drivers/pci/controller/dwc/pcie-designware.c
@@ -787,7 +787,8 @@ int dw_pcie_wait_for_link(struct dw_pcie *pci)
 			return -EIO;
 		}
 
-		dev_info(pci->dev, "Phy link never came up\n");
+		dev_err(pci->dev, "Link failed to come up. LTSSM: %s\n",
+			dw_pcie_ltssm_status_string(ltssm));
 		return -ETIMEDOUT;
 	}
 

-- 
2.51.0

