From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 25 Jul 2026 10:59:15 +0200
Subject: [PATCH 3/6] PCI/pwrctrl: tc9563: Power off only the external ports
 in tc9563_pwrctrl_disable_port()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tc9563-fix-v1-3-ec4286e31331@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1339;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=zLYATUwqJ3rAN0h7YuF5xAqQqTi6vwxszqFTr4nRMsA=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr7A2DEm6RUDhHmyToj3odcB1cKnGmF9o5z9
 kfsCC8tQruJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR6+wAKCRBVnxHm/pHO
 9d4WB/9yg3CA07T7iVSwySkVOdD4XhS+kDBwzPz2a/p0JMMRNgNkiMYw4Ar6PnY4QvX2Usp4B4u
 QhQ/uWrT3fdre9DpIMTe7CdGEfZmIpY1PhChddS/qL+W0aW3oqi/30Ovlz1jzwnmYWcQXCMXatr
 k1WXlFYrLP0DaBTIbUFGS5hobqe2VBgGDV3vZ+ne+BbRe4XEK+NQRM/Mwh7Y8Yqq1pP338bbRVv
 7VJfNDxOWYXXYcSm3GPISLknXQyNJPFuNQJBxhFXGNEGwgHI51w4TRLDKhf0Hiyy46g6dM9K1Bj
 2sn+vG0GMQKFprISPs2GEAmeh/Zu1Hw7GAq/9rNtbOesjkVd
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TC9563 supports powering off only the external facing ports like DSP1 and
DSP2. It is not recommended to power off USP and DSP3 as they have fixed
ports/endpoint connected.

Hence, fix tc9563_pwrctrl_disable_port() to power off only DSP1 and DSP2.

Fixes: 4c9c7be47310 ("PCI: pwrctrl: Add power control driver for TC9563")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
index 482e82e433dd..ca19bf60d290 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
@@ -241,12 +241,18 @@ static int tc9563_pwrctrl_disable_port(struct tc9563_pwrctrl *tc9563,
 	if (!cfg->disable_port)
 		return 0;
 
-	if (port == TC9563_DSP1) {
+	switch (port) {
+	case TC9563_DSP1:
 		seq = dsp1_pwroff_seq;
 		len = ARRAY_SIZE(dsp1_pwroff_seq);
-	} else {
+		break;
+	case TC9563_DSP2:
 		seq = dsp2_pwroff_seq;
 		len = ARRAY_SIZE(dsp2_pwroff_seq);
+		break;
+	default:
+		/* Only external downstream ports DSP1/DSP2 can be powered off */
+		return 0;
 	}
 
 	ret = tc9563_pwrctrl_i2c_bulk_write(tc9563->client, seq, len);

-- 
2.43.0

