From: Sven Peter <sven@kernel.org>
Subject: [PATCH v3 0/3] Apple Silicon Type-C PHY
Date: Sun, 14 Dec 2025 11:51:33 +0000
Message-Id: <20251214-b4-atcphy-v3-0-ba82b20e9459@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMWkPmkC/1WOzQqDMBAGX0X23JTsxp+mp75H6SHGqKHFSCKhI
 r57oxRqj/OxM+wCwXhrAlyzBbyJNlg3JBCnDHSvhs4w2yQG4lQgR8HqnKlJj/3MmlJVWgrZ5Fh
 Buh+9ae17b90fiXsbJufnPR1xW78VKg+ViIyz9oI1EhWt1OXtafxgXmfnO9gykX4q0vGBSEkVu
 dYVl1QTqT91XdcPQOtkWt4AAAA=
X-Change-ID: 20251013-b4-atcphy-d6a7c939d417
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-hardening@vger.kernel.org, 
 linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3216; i=sven@kernel.org;
 h=from:subject:message-id; bh=A9b5Y7XPAJ4q0XUe8bUjFOzSiI/pDmxH2l9xPh4oLjE=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ6bdkst/lq6P4gyc+M3nktzcrkdJ0QuzeOenTZIqmbwn2
 13kU3ZjRykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAimaEM/3R9e4t/qBib3pAT
 LfXYuTcwqck7zzpHls/bq3C29xINXkaGne8/z1KU8c1nkTxy4dX2SI8N1ybtifynoL9Eo8MsMiy
 EAQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds support for the combined Type-C PHY found in Apple
Silicon machines and required for USB3, DP-AltMode, and Thunderbolt/USB4
support. As in the previous versions, this is limited to USB3 support so
far since the other modes need further work in different subsystems.
With the dwc3 glue driver being upstream this is however the last part
required for upstream USB3 support.

The generic tunable support inside driver/soc/apple will also be re-used
for Thunderbolt later but it's fine to take it through the PHY tree
since thunderbolt will depend on that anyway.

Changes in v3:
- Link to v2: https://patch.msgid.link/20251123-b4-atcphy-v2-0-34cc7092b22a@kernel.org
- Rebased on 6.19-rc1

Changes in v2:
- Link to v1: https://patch.msgid.link/20251026-b4-atcphy-v1-0-f81b1225f9c6@kernel.org
- Picked up tags from Rob and Janne, thanks!
- Added additional sanity checks for the tunables to guard against bugs
  in our bootloader (Janne)
- Used struct_size from overflow.h instead of open-coding it inside
  tunables.c (Janne)
- Fixed a bunch of typos in atc.c pointed out by Mark Kettenis via IRC

Changes since v2 of the combined series:
- Link to v2: https://lore.kernel.org/asahi/20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org/
- atc.c:
  - Removed a bunch of outdated safety checks from atc.c that were only
    required in a previous version that did not rely on the dwc3-glue
    driver
  - Addressed Philipp's review comments:
    - Added documentation for struct apple_atcphy (and a bunch of other
      things while I was at it)
    - Moved the mutex guard from atcphy_dpphy_configure to atcphy_dp_configure
      since the first one doesn't touch any shared structures or MMIO
- apple,atcphy.yaml:
  - Added a generic apple,tunable definition that uses uint32-matrix
    and refer to that one from the individual tunable properties
  - Adjust the tunable description to make it easier to understand
  - Limited all lines to 80 chars
  - Used > for longer descriptions
  - Fixed some typos
- Picked up r-b tags (thanks!)

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (3):
      soc: apple: Add hardware tunable support
      dt-bindings: phy: Add Apple Type-C PHY
      phy: apple: Add Apple Type-C PHY

 .../devicetree/bindings/phy/apple,atcphy.yaml      |  222 ++
 MAINTAINERS                                        |    2 +
 drivers/phy/Kconfig                                |    1 +
 drivers/phy/Makefile                               |    1 +
 drivers/phy/apple/Kconfig                          |   14 +
 drivers/phy/apple/Makefile                         |    4 +
 drivers/phy/apple/atc.c                            | 2294 ++++++++++++++++++++
 drivers/soc/apple/Kconfig                          |    4 +
 drivers/soc/apple/Makefile                         |    3 +
 drivers/soc/apple/tunable.c                        |   80 +
 include/linux/soc/apple/tunable.h                  |   62 +
 11 files changed, 2687 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251013-b4-atcphy-d6a7c939d417

Best regards,
-- 
Sven Peter <sven@kernel.org>

