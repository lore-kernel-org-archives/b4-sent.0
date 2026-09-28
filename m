From: Vincent Jardin <vjardin@free.fr>
Date: Mon, 28 Sep 2026 15:48:09 +0200
Subject: [PATCH] PCI: layerscape: async probe by default
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260928-for-upstream-pci-layerscape-async-probe-v1-1-76412d887baa@free.fr>
X-B4-Tracking: v=1; b=H4sIABhwumoC/x3NTQrCQAxA4auUrA3EwZ/Wq4iLmKYa0JkhUbGU3
 t3B5bd5b4FQNw04dQu4fiys5IbtpgO5c74p2tgMidKBhtTjVBzfNV6u/MQqhg+e1UO4KnLMWbB
 6uSpSvxPW/UgDHaHVqutk3//pfFnXH+yB0fl5AAAA
To: Minghuan Lian <minghuan.Lian@nxp.com>, Mingkai Hu <mingkai.hu@nxp.com>, 
 Roy Zang <roy.zang@nxp.com>, Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Ioana Ciornei <ioana.ciornei@nxp.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-pci@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, imx@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Vincent Jardin <vjardin@free.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790603298; l=1374;
 i=vjardin@free.fr; s=20260525; h=from:subject:message-id;
 bh=FiRn9OiNUjwkWfk6TfzHBQosBVCt2Ztr46nw5buAh4w=;
 b=61ATACnDyWjW6rV7RTXwL9RyAdZDzlU6eY1kSxfh9+/akDvP2PLaEXFhAq3GqnDqV6ZPd/ELZ
 2Cg7PafmqWID96UsYC+Ox031k8ImTNnycQ3by9yvKvgRkTiJ4assXMc
X-Developer-Key: i=vjardin@free.fr; a=ed25519;
 pk=hppgLeFpGpKOi7LNwGEZ4jOYofJCoGd4Jf1ltAabiLw=
X-Endpoint-Received: by B4 Relay for vjardin@free.fr/20260525 with auth_id=871
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dw_pcie_wait_for_link() polls for up to
  PCIE_LINK_WAIT_MAX_RETRIES x PCIE_LINK_WAIT_SLEEP_MS (10 x 90 ms)
per controller.

The controllers are probed one after the other, so, it leads to slow
boot time.

On an LX2160A board with 4 enabled controllers and no link on any
of them, ls_pcie_driver_init took almost 4s.

Probing the 4 in parallel allows to have it down to 1s.

The controllers are independent, other DWC based drivers are already
using async probing such as qcom, imx6, s32g, rcar-gen4 or stm32.

Signed-off-by: Vincent Jardin <vjardin@free.fr>
---
 drivers/pci/controller/dwc/pci-layerscape.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pci/controller/dwc/pci-layerscape.c b/drivers/pci/controller/dwc/pci-layerscape.c
index 14d6ac4fc53f..7f37a0537159 100644
--- a/drivers/pci/controller/dwc/pci-layerscape.c
+++ b/drivers/pci/controller/dwc/pci-layerscape.c
@@ -419,6 +419,7 @@ static struct platform_driver ls_pcie_driver = {
 		.of_match_table = ls_pcie_of_match,
 		.suppress_bind_attrs = true,
 		.pm = &ls_pcie_pm_ops,
+		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
 	},
 };
 module_platform_driver(ls_pcie_driver);

---
base-commit: 94e8d4e94266bb9737a5963810a3f9365cb2f39d
change-id: 20260928-for-upstream-pci-layerscape-async-probe-084cae5d0907

Best regards,
-- 
Vincent Jardin <vjardin@free.fr>

