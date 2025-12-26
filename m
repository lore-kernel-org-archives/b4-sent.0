From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v6 0/2] Upstreaming Pinephone Pro Patches
Date: Thu, 25 Dec 2025 19:43:18 -0800
Message-Id: <20251225-ppp_light_accel_mag_vol-down-v6-0-8c79a4e87001@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFYETmkC/5XOTW6DMBCG4atEXteVbfxHV71HFaHBHoMlwAgiN
 1XE3etkUaF0Qbt8Z/F8cyMrLhFX8na6kQVzXGOaSuiXE3E9TB3S6EsTwYRitWB0nudmiF1/acA
 5HJoRuiangfr0OVHLjbMyeEDrSSHmBUO8PviPc+k+rpe0fD3WMr9f/whnThl1tm2dr1BgLd+7E
 eLw6tJI7nAWe4wfYKJgqFvntAMjAZ+x6j9YVTADQWvFgzH46zO5x+oDTBZMq9oGIXwlFX/G1A/
 GuZAHmCpYqIEzYKAYtnts27Zv3tJQ4fwBAAA=
X-Change-ID: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 Ondrej Jirman <megi@xff.cz>, "Leonardo G. Trombetta" <lgtrombetta@gmx.com>, 
 Pavel Machek <pavel@ucw.cz>, Martijn Braam <martijn@brixit.nl>, 
 =?utf-8?q?Kamil_Trzci=C5=84ski?= <ayufan@ayufan.eu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766720655; l=3050;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=Ou87PO0R/OWNEEu0ns8K1kPWQXC2moP4qrOtG3wy9A4=;
 b=NXdEf3OwQcE6VqJFKTxbvswHHnjmSS571lQw4+wcJjV7dCkSrwcycAfoIy/SeSYs2l/L/RQHz
 UIJaYULe4ggBZNaMuVIc+OofOTaJ3ywvj5163p+kmRPRtxgWsCzU5VE
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
- Add magnetometer sensor support
  - Link: https://codeberg.org/megi/linux/commit/2f7e67f451f16eaf15b81aa1dbdf126d54927d35
- Add mount-matrix for magnetometer
  - Link: https://codeberg.org/megi/linux/commit/d7cd2eab931e32fa94408a96d73b4e6c0616107a

Already upstreamed:
- Add accelerometer sensor support
  - Link: https://codeberg.org/megi/linux/commit/b0bb7633e073a6760fa213b8c4a78ea2e73c7bf1
- Fix voltage threshold for volume down key
  - Link: https://codeberg.org/megi/linux/commit/7c496a5cc27ed4e38b740f36c2d8b2c62f80ae54

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v6:
- rebased to 6.18
- sorted nodes alphabetically in compass and light/proximity
- added pinctrl to compass
- dropped accelerometer and volume patches as they are merged
- Link to v5: https://lore.kernel.org/r/20251124-ppp_light_accel_mag_vol-down-v5-0-f9a10a0a50eb@gmail.com

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
Ondrej Jirman (2):
      arm64: dts: rockchip: Add magnetometer sensor to Pinephone Pro
      arm64: dts: rockchip: Add light/proximity sensor to Pinephone Pro

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 39 ++++++++++++++++++++++
 1 file changed, 39 insertions(+)
---
base-commit: 7d0a66e4bb9081d75c82ec4957c50034cb0ea449
change-id: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

