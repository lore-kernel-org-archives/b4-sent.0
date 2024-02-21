From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 22 Feb 2024 00:41:09 +0800
Subject: [PATCH v3 6/8] dt-bindings: clock:
 hisilicon,clock-reset-controller: add Hi3798MV200 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-clk-mv200-v3-6-f30795b50318@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708533664; l=838;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=loFK3Ng4KJm9y+N05vI2yM21cRI/NAqIUEkGNGWtP4Y=;
 b=RE3IgR4NkTHq8jI65Vbtpjsp+Mb81PnG6e02E5loAnlQCbCQ+3BGgQxeJejJjpWTgvhLIPGKJ
 XT30dX1tsfdDvnjuZJTOEarmYcyO8wDtkAGq9qZZwYC44VFMBP8JnMG
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
index 2cf21cb5ff27..41d35de47252 100644
--- a/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
+++ b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
@@ -22,6 +22,8 @@ properties:
           - hisilicon,hi3519-crg
           - hisilicon,hi3798cv200-crg
           - hisilicon,hi3798cv200-sysctrl
+          - hisilicon,hi3798mv200-crg
+          - hisilicon,hi3798mv200-sysctrl
       - const: syscon
       - const: simple-mfd
 

-- 
2.43.0

