From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 22 Jul 2026 21:46:47 -0500
Subject: [PATCH v3 1/2] dt-bindings: soc: tegra: pmc: Document Tegra210B01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-t210b01-pmc-v3-1-1c5b970788f2@gmail.com>
References: <20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com>
In-Reply-To: <20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784774814; l=1197;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=yRm/f+3SzoxTxtTfaa81bdhigcB8fmUxP2kKtIxqiLM=;
 b=txDgun87iW4pToVMkZEvm8YopArM8oO+f50PpeF8biTV95ViyEE7XvT9I6nUWP/ozsclF39i6
 Q5IQYDRPiukAEjtGdgx35w3Nw3lP5VVX0dZyhwlTIdArN9wwRrvYSdR
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PMC in Tegra210B01 is very similar to the one in the original
Tegra210, but has a few powergate differences. Document this soc.

Acked-by: Rob Herring (Arm) <robh@kernel.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/soc/tegra/nvidia,tegra20-pmc.yaml | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/soc/tegra/nvidia,tegra20-pmc.yaml b/Documentation/devicetree/bindings/soc/tegra/nvidia,tegra20-pmc.yaml
index f516960dbbefb..8ec36c49f9594 100644
--- a/Documentation/devicetree/bindings/soc/tegra/nvidia,tegra20-pmc.yaml
+++ b/Documentation/devicetree/bindings/soc/tegra/nvidia,tegra20-pmc.yaml
@@ -18,6 +18,7 @@ properties:
       - nvidia,tegra114-pmc
       - nvidia,tegra124-pmc
       - nvidia,tegra210-pmc
+      - nvidia,tegra210b01-pmc
 
   reg:
     maxItems: 1
@@ -346,7 +347,9 @@ allOf:
       properties:
         compatible:
           contains:
-            const: nvidia,tegra210-pmc
+            enum:
+              - nvidia,tegra210-pmc
+              - nvidia,tegra210b01-pmc
     then:
       properties:
         pinmux:

-- 
2.54.0

