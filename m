From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 11 Apr 2025 20:42:44 +0800
Subject: [PATCH 2/7] dt-bindings: soc: amlogic: C3 supports clk-measure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250411-clk-measure-v1-2-cb46a78d019a@amlogic.com>
References: <20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com>
In-Reply-To: <20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744375372; l=828;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=R+VgfvEaPoAKSQB5hn3wQA0opSipq/Yo223lp8X4HAc=;
 b=7xdBRMtyfW2OTwf09OOs3HozL9VTvwFUEDptXFUHha3noZ/r6nUSO8mWRz+q8JXRYnEpxc1Bx
 IHf08TbR3j7Buz5fiFIKwY5dqELdrl7Ap98uMszISFjBMdF9fsaIloU
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

C3 adds support for clk-measure.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 .../devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml    | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
index 77c281153010..275afe7fe374 100644
--- a/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
+++ b/Documentation/devicetree/bindings/soc/amlogic/amlogic,meson-gx-clk-measure.yaml
@@ -22,6 +22,7 @@ properties:
       - amlogic,meson-axg-clk-measure
       - amlogic,meson-g12a-clk-measure
       - amlogic,meson-sm1-clk-measure
+      - amlogic,c3-clk-measure
 
   reg:
     maxItems: 1

-- 
2.42.0

