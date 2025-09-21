From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH 0/5] Upstreaming Pinephone Pro Patches
Date: Sat, 20 Sep 2025 23:41:02 -0700
Message-Id: <20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP6dz2gC/x3MQQqEIBQA0KvEXyeYTOR0lQgR/eoHR0WHZiC6e
 9Lybd4JDSthg3U4oeJBjXLqmMYBTNDJIyPbDYKLmb8FZ6UUFcmHr9LGYFQf7dWRI7P5l5icFiN
 fzmqUFnpRKjr6P/22X9cNCKWy5m4AAAA=
X-Change-ID: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Ondrej Jirman <megi@xff.cz>, 
 "Leonardo G. Trombetta" <lgtrombetta@gmx.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758436863; l=1279;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=Gpfoi+txALgRhI206tlvm8/xAq4M/UZUJ6YgK5XGaYc=;
 b=H+bXwIwkxn8Ao42UiF3krOmUE1zTnaFt42PKrB9qR1FNOkjde318DvAeJAsg1ROzBO3ok981k
 JzlX1V3OaJIAeP1gpeKsQlucOP8fuBuWbeECsRzKcrj+WllofRT7NOY
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Throughout the years, many have contributed to the Pinephone Pro (pro)
development. Unfortunately, these patches are scattered around various
repositories in different states.

I will be attempting to upstream these patches. I will start off with the
following small series:
- Add light/proximity sensor support
- Add accelerometer sensor support
- Add magnetometer sensor support
- Add mount-matrix for magnetometer
- Fix voltage threshold for volume down key

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Leonardo G. Trombetta (1):
      arm64: dts: rk3399-pinephone-pro: Add mount-matrix for magnetometer

Ondrej Jirman (4):
      arm64: dts: rk3399-pinephone-pro: Add light/proximity sensor support
      arm64: dts: rk3399-pinephone-pro: Add accelerometer sensor support
      arm64: dts: rk3399-pinephone-pro: Add magnetometer sensor support
      arm64: dts: rk3399-pinephone-pro: Fix voltage threshold for volume down key

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 46 +++++++++++++++++++++-
 1 file changed, 45 insertions(+), 1 deletion(-)
---
base-commit: f83ec76bf285bea5727f478a68b894f5543ca76e
change-id: 20250920-ppp_light_accel_mag_vol-down-817c84fdae8d

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

