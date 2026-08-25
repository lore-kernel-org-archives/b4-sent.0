From: Rohan Joshi <rohan1sj@cadence.com>
Subject: [PATCH v4 0/2] CQE support for cadence eMMC host controller
Date: Tue, 25 Aug 2026 16:40:56 +0530
Message-Id: <20260825-cdns_sdhci_cqe-support-v4-0-e9f72e338373@cadence.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEB4jWoC/63NvQ6CMBSG4Vsxna2B0h/i5H0YQ6A9lQ620EKjI
 dy7BQbiwOb4neQ874QCeAMBXU8T8hBNMM6mQc8nJNvaPgEblTYiGeGZIDmWyoYqqFaaSvaAw9h
 1zg+40RSo0lIDFyg9dx60ea/w/bFtD/2Y/GE/tiYMzn/WeMyX69ZhGT/qRIIzLBjVqQZlw9lN1
 gqshIt0L7SgkfwLKnZIEHIIFQmiNCcl4zWlZfkLzfP8BUOEINdlAQAA
X-Change-ID: 20260721-cdns_sdhci_cqe-support-bf4e4dfcfe67
To: Ulf Hansson <ulfh@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Masahiro Yamada <yamada.masahiro@socionext.com>, 
 Adrian Hunter <adrian.hunter@intel.com>
Cc: Rohan Joshi <rohan1sj@cadence.com>, linux-mmc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mparab@cadence.com, pawell@cadence.com, sjakhade@cadence.com, 
 mpillai@cadence.com, razb@mobileye.com, blarson@amd.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787656261; l=3115;
 i=rohan1sj@cadence.com; s=20260406; h=from:subject:message-id;
 bh=dZEbc9Abi2x+UTPvpEHftXVxRd1ym08XU5Shg8fX5uM=;
 b=BpsGK8WXA3uupR57BQ8IAGkrFZJaal31ytdOaozX0imBIxxA+7WPJYMeIlmkfbVYoarqqcXj6
 A65UTtYO+h2AKKzqOe5yyvedJoP/E8kA0DCPGYyytI0ao1oVU0TRoAk
X-Developer-Key: i=rohan1sj@cadence.com; a=ed25519;
 pk=YuwylizMVlVj8I4+VPMZ6xrFR2wyqJAWZyj90OVZgD0=
X-Endpoint-Received: by B4 Relay for rohan1sj@cadence.com/20260406 with auth_id=723
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds CQE (Command Queue Engine) support for cadence
eMMC host controller. The driver enables CQE when both the
conditions mentioned below are met
        1. Hardware reports the presence of CQE
        2. DT provides a "cqhci" register space

The sdhci-cadence driver currently maps the host register
space (index 0). On the amd,pensando-elba platform, an
additional register space (byte-lane control) is present
at index 1, which the driver already handles separately.
The original author for Elba, Brad Larson(blarson@amd.com)
has confirmed that Elba does support CQE!
In this case, total 3 register spaces are mapped in the
order [hc, bctl, cqhci].

The CQHCI core expects the CQE region to be provided as
a named resource ("cqhci") via DT rather than by index.
The driver has never wired up CQE initialization for any
platform and the feature remains unused.

This series adds the support to look up the "cqhci" named
resource from the DT and when present, initializes the
CQHCI engine. This allows platforms to enable Command
Queuing simply by adding the named resource to the DT node
without requiring any platform-specific driver changes.

Signed-off-by: Rohan Joshi <rohan1sj@cadence.com>
---
Changes in v4:
- On cqhci_resume() failure, emit a dev_warn and continue rather than
  disabling the clock and halting the operation
- Link to v3: https://lore.kernel.org/r/20260722-cdns_sdhci_cqe-support-v3-0-4412856a4488@cadence.com

Changes in v3:
- Device Tree updates to account for multiple platforms supporting CQE
- Link to v2: https://patch.msgid.link/20260506-cdns_sdhci_cqe-support-v2-0-754fe4de8b65@cadence.com

Changes in v2:
- Use dev_err_probe() for error messages when in probe path
- Updated commit messages as per subsystem naming conventions
- Select MMC_CQHCI in Kconfig for MMC_SDHCI_CADENCE
- Drop new dt-binding example and corrected existing one
- Link to v1: https://patch.msgid.link/20260407-cdns_sdhci_cqe-support-v1-0-13efc0810631@cadence.com

To: Ulf Hansson <ulfh@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Masahiro Yamada <yamada.masahiro@socionext.com>
To: Adrian Hunter <adrian.hunter@intel.com>
Cc: linux-mmc@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: mparab@cadence.com
Cc: pawell@cadence.com
Cc: sjakhade@cadence.com
Cc: mpillai@cadence.com
Cc: rohan1sj@cadence.com
Cc: razb@mobileye.com
Cc: blarson@amd.com

---
Rohan Joshi (2):
      dt-bindings: mmc: cdns,sdhci: Add CQE support
      mmc: sdhci-cadence: Add CQE support

 .../devicetree/bindings/mmc/cdns,sdhci.yaml        |  28 ++++-
 drivers/mmc/host/Kconfig                           |   1 +
 drivers/mmc/host/sdhci-cadence.c                   | 125 ++++++++++++++++++++-
 3 files changed, 147 insertions(+), 7 deletions(-)
---
base-commit: 66498c75b4f8017f62d720d9b59675bdf3abce91
change-id: 20260721-cdns_sdhci_cqe-support-bf4e4dfcfe67

Best regards,
--  
Rohan Joshi <rohan1sj@cadence.com>

