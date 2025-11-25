From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v5 0/4] Upstreaming Pinephone Pro Patches
Date: Mon, 24 Nov 2025 19:46:59 -0800
Message-Id: <20251124-ppp_light_accel_mag_vol-down-v5-0-f9a10a0a50eb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALMmJWkC/5XOTW6DMBCG4atEXtcVNv4jq9yjipAZj8ESYASRm
 yri7jWsULNIunxn8XzzIAvOARdyPj3IjCksIY455MeJQGfHFmlwuQkvuCwqXtBpmuo+tN2ttgD
 Y14Nt6xR76uL3SA3TYIR3Fo0jmZhm9OG+81/X3F1YbnH+2dcS265vwonRgoJpGnAlcqzEpR1s6
 D8hDmSDEz9i7AXGM4aqAVBgtbD4Fyv/g5UZ09YrJZnXGp8+E0eseoGJjClZGc+5K4VkR2xd11+
 3DErTrwEAAA==
X-Change-ID: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Ondrej Jirman <megi@xff.cz>, Martijn Braam <martijn@brixit.nl>, 
 =?utf-8?q?Kamil_Trzci=C5=84ski?= <ayufan@ayufan.eu>, 
 Pavel Machek <pavel@ucw.cz>, "Leonardo G. Trombetta" <lgtrombetta@gmx.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764042420; l=2902;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=JdG4DaI/Qc50V4Qsb7hZVw07NZj9J6447kSQIzMX7LQ=;
 b=ZVOBijytHHRZBAkav8KWxiESEsv4+3UqIouLDZVFE2LIPpDfdAhc9Gqwbh7exYG6mEgs3D4Zr
 9z0WFy8uQt0AFRgQKfktoGJInOqrXCWooH5fYvL9K3zLa6DJYldPJB2
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Throughout the years, many have contributed to the Pinephone Pro (ppp)
development. Unfortunately, these patches are scattered around various
repositories in different states.

I will be attempting to upstream these patches. I will start off with the
following small series:
- Add light/proximity sensor support
  - Link: https://codeberg.org/megi/linux/commit/f171bc7013bc7ad3de9af817bfbcbfa548ebe01c
- Add accelerometer sensor support
  - Link: https://codeberg.org/megi/linux/commit/b0bb7633e073a6760fa213b8c4a78ea2e73c7bf1
- Add magnetometer sensor support
  - Link: https://codeberg.org/megi/linux/commit/2f7e67f451f16eaf15b81aa1dbdf126d54927d35
- Add mount-matrix for magnetometer
  - Link: https://codeberg.org/megi/linux/commit/d7cd2eab931e32fa94408a96d73b4e6c0616107a
- Fix voltage threshold for volume down key
  - Link: https://codeberg.org/megi/linux/commit/7c496a5cc27ed4e38b740f36c2d8b2c62f80ae54

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v5:
- use monitor-sensor to verify accelerometer's mount-matrix, lux, proximity
- use Leonardo's compass add to verify the compass's mount matrix
- Link to v4: https://lore.kernel.org/r/20250929-ppp_light_accel_mag_vol-down-v4-0-6598f22d3451@gmail.com

Changes in v4:
- remove leda-supply and vdd-supply from dts to suppress warning
- credit Martijn and Kamil for the light sensor and accelerometer patches
  - Link: https://fosstodon.org/@martijnbraam/115272859701389599
  - Link: https://codeberg.org/megi/linux/commit/fc5660685ebe4ecf60226bfa27a1ce47c1c1d020
- combine the magnetometer related patches
- corrected accelerometer's mount matrix to Documentation/devicetree/bindings/iio/mount-matrix.txt
- filled out commit messages
- rebased onto v6.17
- Link to v3: https://lore.kernel.org/r/20250921-ppp_light_accel_mag_vol-down-v3-0-7af6651f77e4@gmail.com

Changes in v3:
- change magnetometer mount matrix
- update volume button threshold
- Link to v2: https://lore.kernel.org/r/20250921-ppp_light_accel_mag_vol-down-v2-0-e6bcc6ca74ae@gmail.com

Changes in v2:
- remove usb-typec node in dts from light/proximity sensor patch
- Link to v1: https://lore.kernel.org/r/20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com

---
Ondrej Jirman (4):
      arm64: dts: rockchip: Add light/proximity sensor to Pinephone Pro
      arm64: dts: rockchip: Add accelerometer sensor to Pinephone Pro
      arm64: dts: rockchip: Add magnetometer sensor to Pinephone Pro
      arm64: dts: rockchip: Fix voltage threshold for volume keys for Pinephone Pro

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 41 ++++++++++++++++++++--
 1 file changed, 39 insertions(+), 2 deletions(-)
---
base-commit: e5f0a698b34ed76002dc5cff3804a61c80233a7a
change-id: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

