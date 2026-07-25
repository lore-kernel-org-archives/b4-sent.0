From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 25 Jul 2026 10:59:16 +0200
Subject: [PATCH 4/6] PCI/pwrctrl: tc9563: Skip Tx amplitude and DFE tuning
 for DSP3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tc9563-fix-v1-4-ec4286e31331@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1891;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=EGn5tsg1B9QVm91PpLmPy5u1U7n/Z+bnKmRxSSYCALc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr7SNsPHW/XY2MtS+D+0iYl7FOL7fzBOEsDv
 nuI8tToBCiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR6+wAKCRBVnxHm/pHO
 9aiIB/9oVyGHq7cs4RtEXJTvESJLfesplg08buYt36fnlVhHANez0x/wXJRmYJYLQskwdAbN+GP
 QMJFGGCfr5lCKA0FPbvNhOGee5iHjcJ28Ro1n7FyAHRZ1cMWRqmieXzhzpFYcDssFEYUXh+hWN+
 49F+GUWuTXBVz6PZ3XnGeErlLw1EsBclbJb5kKQ/00WgI2AXv43Ohg9m7bELF3nE2AlNk55D//N
 JNMN60F4MdyEnjYImcKMa261HpflEY6Deoz+XueZowKjJb+x22GFOREhFyGHEWUL4zMWa3VIYYW
 jXW3RZEzgJsH6jBXrC3POjtASr/UWcdvPo/AqUxMD5JlnzxE
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DSP3 doesn't support tuning Tx amplitude and DFE settings. So just skip
the setting if DT has passed the tuning properties. There is no need to
error out the whole driver because of it.

Fixes: 4c9c7be47310 ("PCI: pwrctrl: Add power control driver for TC9563")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
index ca19bf60d290..28e9ec3e172a 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
@@ -308,6 +308,7 @@ static int tc9563_pwrctrl_set_l0s_l1_entry_delay(struct tc9563_pwrctrl *tc9563,
 static int tc9563_pwrctrl_set_tx_amplitude(struct tc9563_pwrctrl *tc9563,
 					   enum tc9563_pwrctrl_ports port)
 {
+	struct device *dev = tc9563->pwrctrl.dev;
 	u32 amp = tc9563->cfg[port].tx_amp;
 	int port_access;
 
@@ -327,6 +328,9 @@ static int tc9563_pwrctrl_set_tx_amplitude(struct tc9563_pwrctrl *tc9563,
 	case TC9563_DSP2:
 		port_access = 0x8;
 		break;
+	case TC9563_DSP3:
+		dev_dbg(dev, "Tx amplitude tuning not supported for DSP3\n");
+		return 0;
 	default:
 		return -EINVAL;
 	}
@@ -345,6 +349,7 @@ static int tc9563_pwrctrl_disable_dfe(struct tc9563_pwrctrl *tc9563,
 				      enum tc9563_pwrctrl_ports port)
 {
 	struct tc9563_pwrctrl_cfg *cfg = &tc9563->cfg[port];
+	struct device *dev = tc9563->pwrctrl.dev;
 	int port_access, lane_access = 0x3;
 	u32 phy_rate = 0x21;
 
@@ -363,6 +368,9 @@ static int tc9563_pwrctrl_disable_dfe(struct tc9563_pwrctrl *tc9563,
 		port_access = 0x8;
 		lane_access = 0x1;
 		break;
+	case TC9563_DSP3:
+		dev_dbg(dev, "DFE tuning not supported for DSP3\n");
+		return 0;
 	default:
 		return -EINVAL;
 	}

-- 
2.43.0

