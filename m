From: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
Date: Tue, 18 Mar 2025 22:22:56 -0500
Subject: [PATCH 1/2] phy: qcom: phy-qcom-snps-eusb2: Make repeater optional
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-xps13-fingerprint-v1-1-fbb02d5a34a7@oss.qualcomm.com>
References: <20250318-xps13-fingerprint-v1-0-fbb02d5a34a7@oss.qualcomm.com>
In-Reply-To: <20250318-xps13-fingerprint-v1-0-fbb02d5a34a7@oss.qualcomm.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Aleksandrs Vinarskis <alex.vinarskis@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354576; l=1783;
 i=bjorn.andersson@oss.qualcomm.com; s=20250318; h=from:subject:message-id;
 bh=F7hjgKZGyX/2eLEjN8svonHsIEOir26AqogeCcUlWcE=;
 b=rYdWDRbOX/8sX0ywyxFrEIdhuYcea6Fgdn0JHBSHBmXVsYtepF/Etfb/31gQk04mSVN6QgPpc
 fkCi2bLlQ6fDEq3EejcttGvRSFjO2pPHKcYGnSYCJIVFBXUolthYW3u
X-Developer-Key: i=bjorn.andersson@oss.qualcomm.com; a=ed25519;
 pk=rD3O9C9Erg+mUPBRBNw91AGaIaDVqquHZbnn6N6xh6s=
X-Endpoint-Received: by B4 Relay for bjorn.andersson@oss.qualcomm.com/20250318 with auth_id=362
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In a multiport configuration based on the SNPS eUSB2 PHY it's not
necessary that all ports are connected to something.

While this is allowed by the Devicetree binding, the implementation
current fails probing for such PHYs, which also prevents the multiport
controller from probing.

The lack of repeater does not alter the fact that the PHY is there and
attempts at describing only the used PHYs in Devicetree results in
failures to initialize the USB controller.

Make the repeater optional, to allow the these PHYs to be described in
the DeviceTree and for the associated multiport controller to operate
the other ports.

Signed-off-by: Bjorn Andersson <bjorn.andersson@oss.qualcomm.com>
---
 drivers/phy/qualcomm/phy-qcom-snps-eusb2.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-snps-eusb2.c b/drivers/phy/qualcomm/phy-qcom-snps-eusb2.c
index 1484691a41d59a7eaf257ef44300827c668bf7e0..8897d2072ccfcaa5b4a510c17761dcdeed5bad0f 100644
--- a/drivers/phy/qualcomm/phy-qcom-snps-eusb2.c
+++ b/drivers/phy/qualcomm/phy-qcom-snps-eusb2.c
@@ -401,9 +401,13 @@ static int qcom_snps_eusb2_hsphy_probe(struct platform_device *pdev)
 				     "failed to get regulator supplies\n");
 
 	phy->repeater = devm_of_phy_get_by_index(dev, np, 0);
-	if (IS_ERR(phy->repeater))
-		return dev_err_probe(dev, PTR_ERR(phy->repeater),
-				     "failed to get repeater\n");
+	if (IS_ERR(phy->repeater)) {
+		if (PTR_ERR(phy->repeater) == -ENODEV)
+			phy->repeater = NULL;
+		else
+			return dev_err_probe(dev, PTR_ERR(phy->repeater),
+					     "failed to get repeater\n");
+	}
 
 	generic_phy = devm_phy_create(dev, NULL, &qcom_snps_eusb2_hsphy_ops);
 	if (IS_ERR(generic_phy)) {

-- 
2.48.1

