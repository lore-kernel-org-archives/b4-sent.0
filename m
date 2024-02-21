From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 22 Feb 2024 00:41:05 +0800
Subject: [PATCH v3 2/8] ARM: dts: hisilicon: add missing compatibles to CRG
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-clk-mv200-v3-2-f30795b50318@outlook.com>
References: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
In-Reply-To: <20240222-clk-mv200-v3-0-f30795b50318@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708533664; l=766;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=tSrn3Xx19dNkcc4kh+ZnlOdA9N28v4ji6ZA0jvly4RQ=;
 b=5BCNDQfT7CjgnN2jJMO2HjSM6j0VK6bm+CdCgzfdrrknvjWDL3zs2VSGfNMtjj3l0/lNw+ty2
 W9EU7FpZ9GMATHftPFrA4bNKEeHKJq62DDrU2GSkptjMtbKGq9kDWxK
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add "syscon" and "simple-mfd" compatibles to CRG node due to recent
binding changes.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm/boot/dts/hisilicon/hi3519.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/hisilicon/hi3519.dtsi b/arch/arm/boot/dts/hisilicon/hi3519.dtsi
index a42b71cdc5d7..da46e01b8fdc 100644
--- a/arch/arm/boot/dts/hisilicon/hi3519.dtsi
+++ b/arch/arm/boot/dts/hisilicon/hi3519.dtsi
@@ -35,7 +35,7 @@ clk_3m: clk_3m {
 	};
 
 	crg: clock-reset-controller@12010000 {
-		compatible = "hisilicon,hi3519-crg";
+		compatible = "hisilicon,hi3519-crg", "syscon", "simple-mfd";
 		#clock-cells = <1>;
 		#reset-cells = <2>;
 		reg = <0x12010000 0x10000>;

-- 
2.43.0

