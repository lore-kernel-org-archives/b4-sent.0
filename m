From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 25 Sep 2026 23:43:36 +1000
Subject: [PATCH 01/13] wifi: brcmfmac: pcie: Report the detected chip ID to
 the bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-brcm4388-submit-v1-1-b5cbc2cde2fb@gmail.com>
References: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
In-Reply-To: <20260925-brcm4388-submit-v1-0-b5cbc2cde2fb@gmail.com>
To: Arend van Spriel <arend.vanspriel@broadcom.com>, 
 Pieter-Paul Giesberts <pieterpg@broadcom.com>, 
 "Franky Lin (Zhenhui)" <frankyl@broadcom.com>, 
 Mathy Vanhoef <vanhoefm@gmail.com>, Kalle Valo <kvalo@kernel.org>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>
Cc: linux-wireless@vger.kernel.org, brcm80211@lists.linux.dev, 
 brcm80211-dev-list.pdl@broadcom.com, asahi@lists.linux.dev, 
 Hector Martin <marcan@marcan.st>, Daniel Berlin <dberlin@dberlin.org>, 
 Janne Grunau <j@jannau.net>, linux-kernel@vger.kernel.org, 
 Hante Meuleman <meuleman@broadcom.com>, linux-hardening@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790343821; l=1357;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=xo79Yb7vk30hMCoIaipAzSFT9Tjr7JBPILevEoBadDU=;
 b=SI7IoQQUeVjnhBrbBG/gkpR9+TXFKTA/GE1/rM/SO/XsXOA7LZeYRdy2pdC+o6DqLeLar+8HQ
 QM3bJxTSuorC+WRkUr3fUPqgPddJ/j6WDSn5YvrObRzBwLaS2UgIi5f
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The devinfo->coreid field is never assigned, so bus->chip remains zero
and chip-specific feature checks cannot match. Assign bus->chip from
devinfo->ci->chip, which contains the detected chip ID.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
index 55f4d7b970..5d84526c96 100644
--- a/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
+++ b/drivers/net/wireless/broadcom/brcm80211/brcmfmac/pcie.c
@@ -342,7 +342,6 @@ struct brcmf_pciedev_info {
 	u32 ram_base;
 	u32 ram_size;
 	struct brcmf_chip *ci;
-	u32 coreid;
 	struct brcmf_pcie_shared_info shared;
 	wait_queue_head_t mbdata_resp_wait;
 	bool mbdata_completed;
@@ -2518,7 +2517,7 @@ brcmf_pcie_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	bus->bus_priv.pcie = pcie_bus_dev;
 	bus->ops = &brcmf_pcie_bus_ops;
 	bus->proto_type = BRCMF_PROTO_MSGBUF;
-	bus->chip = devinfo->coreid;
+	bus->chip = devinfo->ci->chip;
 	bus->wowl_supported = pci_pme_capable(pdev, PCI_D3hot);
 	bus->fwvid = drvdata[id->driver_data].vendor;
 	devinfo->fwseed = drvdata[id->driver_data].fw_seed;

-- 
2.55.0

