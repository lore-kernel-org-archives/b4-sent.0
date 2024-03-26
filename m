From: Folker Schwesinger <dev@folker-schwesinger.de>
Date: Tue, 26 Mar 2024 19:54:37 +0100
Subject: [PATCH 3/3] arm64: dts: rockchip: Remove enable-strobe-pulldown
 for NanoPi4 boards
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-rk-default-enable-strobe-pulldown-v1-3-f410c71605c0@folker-schwesinger.de>
References: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
In-Reply-To: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Chris Ruehl <chris.ruehl@gtsys.com.hk>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Christopher Obbard <chris.obbard@collabora.com>, 
 Alban Browaeys <alban.browaeys@gmail.com>, 
 Doug Anderson <dianders@chromium.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Jensen Huang <jensenhuang@friendlyarm.com>, linux-phy@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Folker Schwesinger <dev@folker-schwesinger.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=724;
 i=dev@folker-schwesinger.de; h=from:subject:message-id;
 bh=fmO1sP9nAwWwIfDKXcaV6YI0IH/hcl1UfJExvs0KGtI=;
 b=owGbwMvMwCXG5FBoZNu1u5bxtFoSQxqz1KSLdfclJe/cdDUz+/2kl+1vlNncrZtWMwXdsI2zz
 Obt51PvKGVhEONikBVTZGHNy9jCnFm+1Lrr52uYOaxMIEMYuDgFYCJlxowMUxteL/2zjlHg1162
 50fY9v/3D+Q+G9j4zG9K5kYTttqjXowMV2buML48c6NI60+fT5tf/Q9o/dhVHZW/LE7hbpPWpuD
 v7AA=
X-Developer-Key: i=dev@folker-schwesinger.de; a=openpgp;
 fpr=056E68B4036977A53B8AF9EB024071323D8ABB7D
X-Endpoint-Received: by B4 Relay for dev@folker-schwesinger.de/default with auth_id=144
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip eMMC PHY driver enables the internal strobe pulldown by
default. So, remove the enable-strobe-pulldown property from the
NanoPi4 series boards DTS.

Signed-off-by: Folker Schwesinger <dev@folker-schwesinger.de>
---
 arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi b/arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi
index b7f1e47978a6..38af91b9e756 100644
--- a/arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi
@@ -168,7 +168,6 @@ &cpu_l3 {
 };
 
 &emmc_phy {
-	rockchip,enable-strobe-pulldown;
 	status = "okay";
 };
 

-- 
2.44.0

