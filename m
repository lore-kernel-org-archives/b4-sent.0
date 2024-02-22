From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 23 Feb 2024 03:40:15 +0800
Subject: [PATCH v4 5/7] dt-bindings: clock:
 hisilicon,clock-reset-controller: add Hi3798MV200 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-clk-mv200-v4-5-3e37e501d407@outlook.com>
References: <20240223-clk-mv200-v4-0-3e37e501d407@outlook.com>
In-Reply-To: <20240223-clk-mv200-v4-0-3e37e501d407@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708630834; l=875;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=gv2xXV2PHkOmWiSsfnHxLP0K9i/ux85MGELzPj9FllI=;
 b=+jf7ao5QN80YG7oizQRY6/67M5d7pTHi916Qvz3LG2uMbbsCM9BOs5gy33kanq12qiKnHQFry
 uCvI6sBVzF7BwNXweipxYeUp7rSAXXCiSU4tXN5htron68OH2B5xyxi
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
index 251156905a7b..a4af12aa3f08 100644
--- a/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
+++ b/Documentation/devicetree/bindings/clock/hisilicon,hisi-crg.yaml
@@ -23,6 +23,8 @@ properties:
               - hisilicon,hi3798cv200-sysctrl
               - hisilicon,hi3516cv300-crg
               - hisilicon,hi3516cv300-sysctrl
+              - hisilicon,hi3798mv200-crg
+              - hisilicon,hi3798mv200-sysctrl
           - const: syscon
           - const: simple-mfd
 

-- 
2.43.0

