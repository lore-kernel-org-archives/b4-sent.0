From: Rudraksha Gupta <guptarud@gmail.com>
Date: Sat, 20 Sep 2025 23:41:07 -0700
Subject: [PATCH 5/5] arm64: dts: rk3399-pinephone-pro: Fix voltage
 threshold for volume down key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-ppp_light_accel_mag_vol-down-v1-5-c8bbcd3e2e94@gmail.com>
References: <20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com>
In-Reply-To: <20250920-ppp_light_accel_mag_vol-down-v1-0-c8bbcd3e2e94@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Ondrej Jirman <megi@xff.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758436863; l=918;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=7iLC5O0dsn9zg2F9rKhLMzmaUzVCOfuKGE4Zt0swuq8=;
 b=MJylPNpnn+pwiXJ58hFB97Qz4rPkvEFoEZMVglpZ16MXoaVzkYwPs6YRstrJ1+oKN9yl4XSvR
 3McwS+qLyM6BUxB5XU1j/xe2r5pCpPbcWvnwxEoyczXHnpwcovrjq5O
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ondrej Jirman <megi@xff.cz>

U-Boot and Linux use different algorithms for determining voltage ranges
for comparison. Pick value that will work with both.

Signed-off-by: Ondrej Jirman <megi@xff.cz>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
index 9442ca4c9ae47d639ed6139c370bacf1bffa65b6..82e29e547fe25ea0c7fa681813514da6e06ecacd 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3399-pinephone-pro.dts
@@ -46,7 +46,7 @@ button-up {
 		button-down {
 			label = "Volume Down";
 			linux,code = <KEY_VOLUMEDOWN>;
-			press-threshold-microvolt = <600000>;
+			press-threshold-microvolt = <400000>;
 		};
 	};
 

-- 
2.51.0

