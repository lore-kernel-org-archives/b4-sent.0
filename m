From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 20 Jul 2026 01:31:15 -0500
Subject: [PATCH v2 1/2] dt-bindings: soc: tegra: pmc: Document Tegra210B01
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-t210b01-pmc-v2-1-ca5317f8507b@gmail.com>
References: <20260720-t210b01-pmc-v2-0-ca5317f8507b@gmail.com>
In-Reply-To: <20260720-t210b01-pmc-v2-0-ca5317f8507b@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784529079; l=1150;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=yw+m2fOBOYUMmvsIg1cUM1xOEdkHn5gdrf48UjW2H8k=;
 b=27TZwk3eilNkHuxizTrcGSCzkeKKTFvhxFV48HhzMR1bJ9B5+hw1tZZY8qi//lw1cRR+4dOCi
 Lg/chziQ9zPAL5pIqTUlpGW2nBcfmfDB3PHwZOw6OIefdPkSWu6LTT3
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PMC in Tegra210B01 is very similar to the one in the original
Tegra210, but has a few powergate differences. Document this soc.

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

