From: rohan1sj <rohan1sj@cadence.com>
Subject: [PATCH 0/2] CQE support for cadence eMMC host controller
Date: Tue, 07 Apr 2026 16:48:19 +0530
Message-Id: <20260407-cdns_sdhci_cqe-support-v1-0-13efc0810631@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPzn1GkC/yXMQQqDMBBA0avIrBtIokTsVUqRdmas00VMM1oE8
 e6NdvkW/2+gnIUVrtUGmb+iMsUCd6kAx0d8sREqBm99sI0NBilqrzSi9Phho0tKU55N42rfWhe
 oowFKnDIPsp7j2/1vXZ5vxvm4wb7/AIwmb3J6AAAA
X-Change-ID: 20260406-cdns_sdhci_cqe-support-41327016d9df
To: Ulf Hansson <ulf.hansson@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Milind Parab <mparab@cadence.com>, 
 Swapnil Jakhade <sjakhade@cadence.com>, 
 Manikandan Pillai <mpillai@cadence.com>, rohan1sj <rohan1sj@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775560710; l=683;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=f9rJgEDeBXdkiLlUJYzj5FIGQ7eAGGBKP3aOjp3S/LU=;
 b=432Rs2W5eB5m41kztGx+gFDsAfvIwUFnaqjxxkMe+OVIhO8ftsmmauRwYMEFfG82VRMrtc6si
 QM+qaStNeoMC7fNrm62sMkgDkf6heFcsBpCeE++xwYDY5CtWIEe/IxA
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Command Queuing Engine(CQE) feature. Supported in
cadence controller but driver lacks the support for it

Signed-off-by: rohan1sj <rohan1sj@cadence.com>
---
rohan1sj (2):
      mmc: cqe: Add CQE DT support for cadence controller
      mmc: cqe: Add CQE support for cadence mmc driver

 .../devicetree/bindings/mmc/cdns,sdhci.yaml        |  32 +++++-
 drivers/mmc/host/sdhci-cadence.c                   | 118 ++++++++++++++++++++-
 2 files changed, 146 insertions(+), 4 deletions(-)
---
base-commit: 05f7e89ab9731565d8a62e3b5d1ec206485eeb0b
change-id: 20260406-cdns_sdhci_cqe-support-41327016d9df

Best regards,
--  
rohan1sj <rohan1sj@cadence.com>

