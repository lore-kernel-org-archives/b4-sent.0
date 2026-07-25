From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 25 Jul 2026 10:59:14 +0200
Subject: [PATCH 2/6] PCI/pwrctrl: tc9563: Fix parsing the integrated
 Ethernet MAC Endpoint node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tc9563-fix-v1-2-ec4286e31331@oss.qualcomm.com>
References: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
In-Reply-To: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alex Elder <elder@riscstar.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1699;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=/ecxH7WNWbI7kGxlGTagbRtkJaVRNHl2xR/seTMJO/c=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr7jKmdMtuHO0GC8dPK2xrKIW1K+ct1FcSAw
 yx2meup4AiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR6+wAKCRBVnxHm/pHO
 9WdgCACM1InRnx+D0thXR+EDXhVP/VoRB6w6hNq0SBHArGqWSgpISTRvzDU51mRZnmq2X3QhvbK
 RWYrHo+L2skFvfEWrqBDmtDIhvZzBFKtaGVlCJe0CoUKrPcwvvpLCnFsKjDVU0jaH+GOVSZZ7b3
 AXypsK9hLOU0i8HHYFkjDJ+4CSlI50/l8jbzOpGmwO+boNp65OMir0uT3/l3+W27EGnFtpRobpS
 Bh/NGPKjdteGVNxk+yFTkWyHFV8NGszw6beJ/dAX3QUh32zcOFkeIxxPcPDQmLfJj4OBuE2LuXc
 pVpBS2gI3yx9/qWvSZSonVkbog6pbr3IacOuueNQzQ0bxvgP
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DSP3 has an integrated Ethernet MAC Endpoint which has its own set of
config registers for configuring settings such as ASPM. The Endpoint
device has 2 physical functions and those 2 functions share the same
settings.

Hence, parse the Endpoint node under DSP3 instead of parsing both the
functions. The existing parsing logic also has one OOB issue as parsing
both functions will result in accessing past the tc9563_pwrctrl->cfg array.

Fixes: 4c9c7be47310 ("PCI: pwrctrl: Add power control driver for TC9563")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
index 488e1ec34a7f..482e82e433dd 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
@@ -596,12 +596,17 @@ static int tc9563_pwrctrl_probe(struct platform_device *pdev)
 		ret = tc9563_pwrctrl_parse_device_dt(tc9563, child, port);
 		if (ret)
 			break;
-		/* Embedded ethernet device are under DSP3 */
+
+		/*
+		 * The integrated Ethernet MAC Endpoint under DSP3 is a single
+		 * device whose functions share the same config registers.
+		 */
 		if (port == TC9563_DSP3) {
-			for_each_child_of_node_scoped(child, child1) {
-				port++;
+			struct device_node *eth __free(device_node) =
+					of_get_next_available_child(child, NULL);
+			if (eth) {
 				ret = tc9563_pwrctrl_parse_device_dt(tc9563,
-								child1, port);
+								eth, TC9563_ETHERNET);
 				if (ret)
 					break;
 			}

-- 
2.43.0

