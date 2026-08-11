From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] thermal: Add support A9
Date: Tue, 11 Aug 2026 08:37:42 +0000
Message-Id: <20260811-a9-thermal-v2-0-7ddc33b11b9a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFbfemoC/03MQQ7CIBCF4as0sxZDIdLWlfcwXSAM7SSlGGiIp
 uHuYuPC5f+S9+2QMBImuDY7RMyUKKw1xKkBM+t1Qka2NgguFO+4ZHpg24zR64U5JQw6hXpoHdT
 DM6Kj14Hdx9ozpS3E92Hn9rv+GMn/mdwyzmzXKys789CX/qb9EiYyZxM8jKWUDziEbkimAAAA
X-Change-ID: 20260703-a9-thermal-f62cef6ea91f
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786437467; l=1143;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=GzrpcxMA0ZCgLTnY5svAVFOUAwdgmcNMnZmmZrgpe7E=;
 b=J8mpk+MyWgRnVu3Wfj1WokXKKyuzGuMqSa4ghIlfh3ClXhwwciNTisQqE31NKizW0NljKgqEo
 L1EWHuusJUvDMD1lwTeZDX60pILsjqMn6jzib0tg9w3RNeX1iq+NoTT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the thermal controller compatibles for the Amlogic A9 SoC
And add driver support for the Amlogic A9 thermal controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Fix the spelling mistakes (clock-names) and reset-temp properties is visible to old chips.
- Adjust the clock enable sequence in resume func and remove the clock disable in remove func.
- Add the judgment on the divisor zero.
- Add description of support for over-temperature reset for old chips in commit message.
- Link to v1: https://lore.kernel.org/r/20260730-a9-thermal-v1-0-d786d37cba58@amlogic.com

---
Xianwei Zhao (2):
      dt-bindings: thermal: amlogic: Add A9 thermal bindings
      thermal: amlogic: Add support for A9 thermal controller

 .../bindings/thermal/amlogic,thermal.yaml          |  28 +++++-
 drivers/thermal/amlogic_thermal.c                  | 108 ++++++++++++++++++++-
 2 files changed, 132 insertions(+), 4 deletions(-)
---
base-commit: 78bc8af4affb9a732504eb22eeac7d1e50883853
change-id: 20260703-a9-thermal-f62cef6ea91f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

