From: George Chan <gchan9527@gmail.com>
Subject: [PATCH RFC/RFT 0/3] Add support to Novatek's touch IC nt36xxx
Date: Tue, 15 Oct 2024 20:53:28 +0800
Message-Id: <20241015-nt36xxx-v1-0-3919d0bffee6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMhlDmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDA0NT3bwSY7OKigpdA/NUE1OLpEQjC3NzJaDqgqLUtMwKsEnRsbW1AFr
 uf6xZAAAA
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Del Regno <kholk11@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728996810; l=2271;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=ZKf9/CxVREmj132u1cKYBcG4ddSqcH0nUrjmlXb6ajg=;
 b=S7DiFUAoX5Tavd4PRUkeZlzJGf/fPE5DU3MYMBVaHeQCigqYlYYD5vEs5HinxCLbv3MgupxqE
 9XZQcrs3z+tCypOMVonTRvFsy9GHySqSNuW27mOhh5rqCGptG1iH31T
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Initially support for nt36xxx series spi device. Below 
list all supported varients:

 - NT36675
 - NT36672A
 - NT36772(?)
 - NT36525
 - NT36676F

I had tested it with Redmi note 9 pro, aka NT36675 chip.

This series is based on my repo below:
https://github.com/99degree/linux/tree/nt36xxx

There is a boot-and-functional tree for miatoll device:
https://github.com/99degree/linux/tree/working-20241015

And the older dev history:
https://github.com/99degree/linux/tree/nt36xxx_old
https://github.com/99degree/linux/tree/working-20230528/drivers/input/touchscreen

This driver is based on 
AngeloGioacchino Del Regno for i2c based drive
https://patchwork.kernel.org/project/linux-input/cover/20201028221302.66583-1-kholk11@gmail.com/#24831734

_AND_
Neil Armstrong for the spi device codes
https://patchwork.kernel.org/project/linux-input/patch/20231213-topic-goodix-berlin-upstream-initial-v13-2-5d7a26a5eaa2@linaro.org/

Download fw function is adapted from original vendor driver
https://github.com/LineageOS/android_kernel_xiaomi_sm6250/tree/lineage-21/drivers/input/touchscreen/nt36xxx_spi/

Panel follower functionality is finally added.

Since the driver is split into core+spi so i2c function is relatively
easily to add.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
George Chan (3):
      dt-bindings: touchscreen: Add binding for Novatek NT36xxx series driver
      [RFC/RFT]Input: Add Novatek NT36xxx touchscreen driver
      dts: sm7125-xiaomi-joyeuse: Sample device tree for reference

 .../bindings/input/touchscreen/nt36xxx.yaml        |   70 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../boot/dts/qcom/sm7125-xiaomi-joyeuse-touch.dts  |  183 +++
 drivers/input/touchscreen/Kconfig                  |   13 +
 drivers/input/touchscreen/Makefile                 |    2 +
 drivers/input/touchscreen/nt36xxx.h                |  142 ++
 drivers/input/touchscreen/nt36xxx_core.c           | 1422 ++++++++++++++++++++
 drivers/input/touchscreen/nt36xxx_spi.c            |  256 ++++
 8 files changed, 2089 insertions(+)
---
base-commit: b852e1e7a0389ed6168ef1d38eb0bad71a6b11e8
change-id: 20241015-nt36xxx-07e458ba2877

Best regards,
-- 
George Chan <gchan9527@gmail.com>

