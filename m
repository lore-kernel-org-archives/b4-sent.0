From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v3 0/5] Upstreaming Pinephone Pro Patches
Date: Sun, 21 Sep 2025 14:05:53 -0700
Message-Id: <20250921-ppp_light_accel_mag_vol-down-v3-0-7af6651f77e4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALFo0GgC/43NQQ6CMBCF4auQrq0pBaG68h7GkDIdyiSFEiBVQ
 7i7hRU7Xf5v8b2FTTgSTuyWLGzEQBP5PkZ2Shi0urfIycRmUsiLuErBh2GoHNl2rjQAuqrTtgr
 eceNfPVdpCSpvjEZlWCSGERt67/zjGbulafbjZ38L6bb+CYeUCw6qrsFkKPGa322nyZ3Bd2yDg
 zxi6Q9MRgyLGqAAXeYaj9i6rl8CYUdAFQEAAA==
X-Change-ID: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 "Leonardo G. Trombetta" <lgtrombetta@gmx.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758488760; l=2092;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=p36wcFyPQqlAAPFV8kif2hBbqmR6V3mP2tc/m/CbJ/4=;
 b=khC8t4v1Xu2EYfXP+DQY1VBR1+l0j/G7ns8n+3Uvymukxh1d3LQBBOqQmCJhHs7Fu9juXzzqq
 YjcenQ0Ge0WDV1e1PLp2Plg2a/OL903KHrvnQARvu9wQ3uhqCRbw8r8
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
  - https://codeberg.org/megi/linux/commit/f171bc7013bc7ad3de9af817bfbcbfa548ebe01c
- Add accelerometer sensor support
  - https://codeberg.org/megi/linux/commit/b0bb7633e073a6760fa213b8c4a78ea2e73c7bf1
- Add magnetometer sensor support
  - https://codeberg.org/megi/linux/commit/2f7e67f451f16eaf15b81aa1dbdf126d54927d35
- Add mount-matrix for magnetometer
  - https://codeberg.org/megi/linux/commit/d7cd2eab931e32fa94408a96d73b4e6c0616107a
- Fix voltage threshold for volume down key
  - https://codeberg.org/megi/linux/commit/7c496a5cc27ed4e38b740f36c2d8b2c62f80ae54

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v3:
- change magnetometer mount matrix
- update volume button threshold
- Link to v2: https://lore.kernel.org/r/20250921-ppp_light_accel_mag_vol-down-v2-0-e6bcc6ca74ae@gmail.com

Changes in v2:
- remove usb-typec node in dts from light/proximity sensor patch
- Link to v1: https://lore.kernel.org/r/20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com

---
Leonardo G. Trombetta (1):
      arm64: dts: rk3399-pinephone-pro: Add mount-matrix for magnetometer

Ondrej Jirman (4):
      arm64: dts: rk3399-pinephone-pro: Add light/proximity sensor support
      arm64: dts: rk3399-pinephone-pro: Add accelerometer sensor support
      arm64: dts: rk3399-pinephone-pro: Add magnetometer sensor support
      arm64: dts: rk3399-pinephone-pro: Fix voltage threshold for volume keys

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 42 ++++++++++++++++++++--
 1 file changed, 40 insertions(+), 2 deletions(-)
---
base-commit: f83ec76bf285bea5727f478a68b894f5543ca76e
change-id: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

