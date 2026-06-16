From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Tue, 16 Jun 2026 09:07:25 +0200
Subject: [PATCH] PCI: dwc: meson: Fix reset GPIO initial state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-fix-meson-pcie-reset-gpio-v1-1-fca404b4c8be@aliel.fr>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MwQqDMBAFf0X27IIJdEn7K+JB49PuoUnIliKI/
 97gcWBmTjJUhdGrO6nip6Y5NXB9R/E9px2sa2Pyg5dBnPCmB39gOXGJCq4wfHkvmtkvT7gQREJ
 8UOtLRZPv9zhd1x/wr4sXawAAAA==
X-Change-ID: 20260616-fix-meson-pcie-reset-gpio-2b9e188668c5
To: Yue Wang <yue.wang@Amlogic.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Remi Pommarel <repk@triplefau.lt>
Cc: linux-pci@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1981;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=7kvkuPDfnNo3RE26T6/4WDZzxv1opTuPQg33oMuoPoI=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQ5bBt8iN7xYkGjz9k3/Q4LBC+svHf2ZG82SwRvv8+qxrP
 uHg7J0CHaUsDGJcDLJiiiz9cy1PvLt89MzXPeopMHNYmUCGMHBxCsBEzp5kZFgsZmWhufqRu+TS
 f+fmXmrY9OFF+xKJmwd6J02ZtCHQyMmA4b+f1oLDa9vKjvUVXWPQFejIeei0+jJ3dve9Ob5VVYG
 qFVwA
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 4d3186a525b3 ("PCI: amlogic: Fix reset assertion via gpio
descriptor") inverted the reset assertion logic to use proper gpio
descriptor semantics, and moved the polarity configuration to the
device tree as GPIO_ACTIVE_LOW. However, the initial GPIO state
"GPIOD_OUT_LOW" was not updated accordingly.

Change GPIOD_OUT_LOW to GPIOD_OUT_HIGH to get the right behaviour.

With GPIOD_OUT_LOW:

    ahci 0000:01:00.0: enabling device (0000 -> 0002)
    ahci 0000:01:00.0: SSS flag set, parallel bus scan disabled
    ahci 0000:01:00.0: Controller reset failed (0xffffffff)
    ahci 0000:01:00.0: probe with driver ahci failed with error -5

With this fix:

    ahci 0000:01:00.0: enabling device (0000 -> 0002)
    ahci 0000:01:00.0: AHCI vers 0001.0300, 32 command slots, 6 Gbps,
                       SATA mode
    ahci 0000:01:00.0: 1/1 ports implemented (port mask 0x1)
    ahci 0000:01:00.0: flags: 64bit ncq led clo only pio ccc

Fixes: 4d3186a525b3 ("PCI: amlogic: Fix reset assertion via gpio descriptor")
Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 drivers/pci/controller/dwc/pci-meson.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/pci/controller/dwc/pci-meson.c b/drivers/pci/controller/dwc/pci-meson.c
index 0694084f612b7..15ed59b8764fb 100644
--- a/drivers/pci/controller/dwc/pci-meson.c
+++ b/drivers/pci/controller/dwc/pci-meson.c
@@ -400,7 +400,7 @@ static int meson_pcie_probe(struct platform_device *pdev)
 		return PTR_ERR(mp->phy);
 	}
 
-	mp->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_LOW);
+	mp->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
 	if (IS_ERR(mp->reset_gpio)) {
 		dev_err(dev, "get reset gpio failed\n");
 		return PTR_ERR(mp->reset_gpio);

---
base-commit: abe651837cb394f76d738a7a747322fca3bf17ba
change-id: 20260616-fix-meson-pcie-reset-gpio-2b9e188668c5

Best regards,
-- 
Ronald Claveau <linux-kernel-dev@aliel.fr>

