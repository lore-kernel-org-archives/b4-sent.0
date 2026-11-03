From: Igor Velkov <iav@iav.lv>
Date: Tue, 03 Nov 2026 06:07:35 +0000
Subject: [PATCH] PCI: rockchip-host: Enable async probe by default
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-rockchip-pcie-async-v1-1-4dcadb94af64@iav.lv>
X-B4-Tracking: v=1; b=H4sIACZ66WoC/x3MMQqAMAxA0atIZgOmlSpeRRwkRg1CLS2IIr27x
 fEN/7+QJKokGKoXolya9PQFVFfA++w3QV2KwTTGETUW48kH7xowsArO6fGMrWFi2zvrqINShii
 r3v91nHL+AHfeqAhlAAAA
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, linux-pci@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1786; i=iav@iav.lv;
 h=from:subject:message-id; bh=ZRf73Oh50c+9BYq7xVYrqoGA7KZ7hc21cjbuWcPTIPw=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkvq9Q33dNaILT/C3cxu8LL4tufGK5wVXIbLE/R5cpfP
 Pfm9ft5HaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAixo6MDG3aCrO1rvx1qGjM
 eiz3foPj60OBV5WOG39zNSifdVgg+g/D/7LIaF+1uw6CruuWzXr/+8X969VN935HTem6ILzj/b+
 OdD4A
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The probe waits for the link to come up, and with an empty slot it
holds the deferred-probe worker for about 0.7 s. On ROCK Pi 4 with
UHS-I enabled for the SD card, the I/O-domain driver then binds only
after the card has switched to 1.8 V, and tuning fails ("All phases
bad!").

Probe asynchronously, as commit c0e1eb441b1d ("PCI: qcom: Enable async
probe by default") does for the Qualcomm host driver. This does not
order the I/O domain before dw_mmc in general; an explicit dependency
was proposed in [1] and not merged.

Link: https://lore.kernel.org/all/20230904115816.1237684-1-s.hauer@pengutronix.de/ [1]
Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on v7.3.1 with the Armbian rockchip64 config (PCIE_ROCKCHIP_HOST=y):
- ROCK Pi 4A, empty slot, UHS-I DT change posted separately: SDR104 on
  3 of 3 cold boots; without this patch tuning fails.
- Kobol Helios64, JMB585 in the slot: link, SATA and disk reads OK
  over 3 cold boots and a reboot.
---
 drivers/pci/controller/pcie-rockchip-host.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pci/controller/pcie-rockchip-host.c b/drivers/pci/controller/pcie-rockchip-host.c
index 5b071bdc4f90..1e1556e436b8 100644
--- a/drivers/pci/controller/pcie-rockchip-host.c
+++ b/drivers/pci/controller/pcie-rockchip-host.c
@@ -1027,6 +1027,7 @@ static struct platform_driver rockchip_pcie_driver = {
 		.name = "rockchip-pcie",
 		.of_match_table = rockchip_pcie_of_match,
 		.pm = &rockchip_pcie_pm_ops,
+		.probe_type = PROBE_PREFER_ASYNCHRONOUS,
 	},
 	.probe = rockchip_pcie_probe,
 	.remove = rockchip_pcie_remove,

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-rockchip-pcie-async-42c1c3863617

Best regards,
-- 
Igor Velkov <iav@iav.lv>

