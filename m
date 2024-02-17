From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 17 Feb 2024 20:52:09 +0800
Subject: [PATCH RFC v2 4/5] dt-bindings: mfd: syscon: Add
 hisilicon,sdmmc-sap-dll compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240217-clk-mv200-v2-4-b782e4eb66f7@outlook.com>
References: <20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com>
In-Reply-To: <20240217-clk-mv200-v2-0-b782e4eb66f7@outlook.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708174332; l=904;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=hib8+Rqu7vbvM/wf1lKjdv6MYEK2HbXcsYxRmMDXhQ8=;
 b=TbKhd4smlf4/y17TROgnbw6vhFb4reum+h1UK3DTNNalQKvaZIeuQOlGKC8YwkciwyqNv68OV
 C7ldoY7k6UaBsftg8OQkEKyg4sn69Vygm+RdKlNM9gg6j6eSlSN5HGM
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add hisilicon,sdmmc-sap-dll compatible. This is a 8 bytes range with two
registers. Mainly used for precise sample phase selection during eMMC
tuning.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/mfd/syscon.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/mfd/syscon.yaml b/Documentation/devicetree/bindings/mfd/syscon.yaml
index 084b5c2a2a3c..c685d4b36ea4 100644
--- a/Documentation/devicetree/bindings/mfd/syscon.yaml
+++ b/Documentation/devicetree/bindings/mfd/syscon.yaml
@@ -47,6 +47,7 @@ properties:
               - hisilicon,hi6220-sramctrl
               - hisilicon,pcie-sas-subctrl
               - hisilicon,peri-subctrl
+              - hisilicon,sdmmc-sap-dll
               - hpe,gxp-sysreg
               - intel,lgm-syscon
               - loongson,ls1b-syscon

-- 
2.43.0

