From: Rohan Joshi <rohan1sj@cadence.com>
Subject: [PATCH v3 0/2] CQE support for cadence eMMC host controller
Date: Wed, 22 Jul 2026 16:18:36 +0530
Message-Id: <20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAASgYGoC/62NsQ6CMBRFf4V0tqZUKMbJ/zCGwOurdLCFPmg0h
 H+3wODk5nhucs+ZGWGwSOySzSxgtGS9S3A6ZAy6xj2QW52YSSGVqGTOQTuqSXdgaxiQ09T3Poy
 8NQUW2oBBVbF07gMa+9rEt/vOAYcp+cfv2FkafXhv8Ziv694phfrViZILXpWFSTU8t6q8QqPRA
 R7BP9kqjfIfomVZPgjdpLgcAQAA
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, mparab@cadence.com, pawell@cadence.com, 
 sjakhade@cadence.com, mpillai@cadence.com, rohan1sj@cadence.com, 
 razb@mobileye.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784717318; l=2000;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=+E9mnDrkm85YIgkx4FFzIzmVAnYNeA+fffZMlwscomM=;
 b=ufAs3iZyBRmr7cwS50TwNCYnlbwMi0lE/0qhV+pli+qgGSg7Oofoyfva5onS58AIQX7aQG7tK
 2sBpF2L+02ADiNbZh5ybVg+YIUSfs+GmDP5F4jEJ5gD7bE4/M4sdYLc
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds CQE (Command Queue Engine) support for cadence
eMMC host controller. the driver enables CQE when both the
conditions mentioned below are met
        1. Hardware reports the presence of CQE
        2. DT provides a "cqhci" register space

The driver handles amd,pensando-elba platform separately
since it requires an additional byte-lane control
register space. The space is mapped via index "1".
The cqhci-core function "cqhci_pltfm_init" maps CQE
via a named resource "cqchi" and hence DT needs to define
the same if the CQE needs to be enabled

The patch adds three named resources to cater for the
above mentioned requirement. It creates the two possible
combinations for amd,pensando-elba platform,
        [hc, bctl] or [hc, bctl, cqhci]
and the other platforms,
        [hc] or [hc, cqhci]

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
Changes in v3:
- Device Tree updates to account for multiple platforms supporting CQE
- Link to v2: https://patch.msgid.link/20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com

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

 .../devicetree/bindings/mmc/cdns,sdhci.yaml        |  28 ++++-
 drivers/mmc/host/Kconfig                           |   1 +
 drivers/mmc/host/sdhci-cadence.c                   | 124 ++++++++++++++++++++-
 3 files changed, 146 insertions(+), 7 deletions(-)
---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260721-cdns_sdhci_cqe-support-bf4e4dfcfe67

Best regards,
-- 
Rohan Joshi <rohan1sj@cadence.com>

