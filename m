From: Rohan Joshi <rohan1sj@cadence.com>
Subject: [PATCH v2 0/2] CQE support for cadence eMMC host controller
Date: Wed, 06 May 2026 14:34:45 +0530
Message-Id: <20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC0E+2kC/3WNyw6CMBBFf4XM2pq2UCSu+A9DCE4HqYktdoBoC
 P8uj7XLk9x7zgxM0RHDNZkh0uTYBb+CPiWAXeMfJJxdGbTUuTTSCLSea7YduhrfJHjs+xAHkRa
 FyXSLZA3Beu4jte6zi2/VwTzen4TDZtsWneMhxO9entS2OyKZvPyLTEpIoVJqURZK5qkqsbHkk
 c4YXlAty/IDq85a2NAAAAA=
X-Change-ID: 20260505-cdns_sdhci_cqe-support-388542fced5e
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778058298; l=1274;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=R86z2z5X9Mizw0diYfbrN06l7sl3ZC0OUD+cdNlUl40=;
 b=r+1ZTkjKRPlzKq26xTqTJhOSdtEBKFton2eI/H8NdLS09Q9FRDEHItz5BF5U+lv+t/xDO7Vlf
 5Y3hPXw+WoUDraYZmxSx5oOgVm2MSLC8jIiFfW9YAGJ7KuSIMoo7zOb
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds CQE (Command Queue Engine) support for cadence
eMMC host controller. The Cadence controller can support CQE which
is determined by reading a non standard capability register.
Updates to devicetree are also made to identify CQE register space
which may be used by the driver.

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
Changes in v2:
- Use dev_err_probe() for error messages when in probe path
- Updated commit messages as per subsystem naming conventions
- Select MMC_CQHCI in Kconfig for MMC_SDHCI_CADENCE
- Drop new dt-binding example and corrected existing one
- Link to v1: https://patch.msgid.link/20260407-cdns_sdhci_cqe-support-v1-0-13efc0810631@cadence.com

---
Rohan Joshi (2):
      dt-bindings: mmc: cdns,sdhci: Add CQE support
      mmc: sdhci-cadence: add CQE support

 .../devicetree/bindings/mmc/cdns,sdhci.yaml        | 41 +++++++---------------
 drivers/mmc/host/Kconfig                           |  1 +
 drivers/mmc/host/sdhci-cadence.c                   | 13 +++----
 3 files changed, 17 insertions(+), 38 deletions(-)
---
base-commit: 6d32b7db25329b4492f35a79fed6b1eef48959d2
change-id: 20260505-cdns_sdhci_cqe-support-388542fced5e

Best regards,
--  
Rohan Joshi <rohan1sj@cadence.com>

