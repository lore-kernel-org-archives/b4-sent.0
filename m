From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 21 Oct 2025 22:09:26 -0500
Subject: [PATCH v5] dt-bindings: devfreq: tegra30-actmon: Add Tegra124
 fallback for Tegra210
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-t210-actmon-p1-v5-1-1bc8f9221917@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOVK+GgC/x3MPQqAMAxA4atIZgNJsIJeRRz8iZrBKq2IULy7x
 fEb3ksQNZhGaIsEQW+LdvgMVxYwbYNfFW3OBiFxTMJ4CRMO07UfHk9GXWRsuK6I3Aw5OoMu9vz
 Drn/fDx9QEj9gAAAA
X-Change-ID: 20251021-t210-actmon-p1-ef2b9164005d
To: MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chanwoo Choi <cw00c.choi@samsung.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761102585; l=2361;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=mg8XT9vcS48SE8URDi3TR+Wy+mQQFKQFXQRT3zUHsb0=;
 b=mZx+g9VaQ/AsA+KvIG57AVILTDDkK1rY9Hsjnu4uds6noRNEOI4n7Ahs955iTc0FLF1yOPed9
 Oe1DAewlGE2BjBWI2ikc0sssC7WV59ThWK0tx3j8IyvZ+X4tsBVmUKR
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra210 actmon is compatible with the existing Tegra124 driver.
Describe the compatibles as such.

Acked-by: Chanwoo Choi <cw00c.choi@samsung.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v5:
- Split series
- Link to v4: https://lore.kernel.org/r/20250923-t210-actmon-v4-0-442d1eb6377c@gmail.com

Changes in v4:
- Various cleanups in patch 5 as requested by review
- Fix a couple typos in patch 4
- Link to v3: https://lore.kernel.org/r/20250906-t210-actmon-v3-0-1403365d571e@gmail.com

Changes in v3:
- In patch 5, don't fail mc probe if opp tables are missing
- Add more mc bindings to patch 1
- Add patch to use tegra210-mc bindings in the mc driver
- Re-order series to align patches within a subsystem to each other
- Link to v2: https://lore.kernel.org/r/20250903-t210-actmon-v2-0-e0d534d4f8ea@gmail.com

Changes in v2:
- Assume 64-bit dram bus width in patch 4
- Add dt-bindings patch to document the new properties on the
  tegra210-emc node.
- Link to v1: https://lore.kernel.org/r/20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com
---
 .../devicetree/bindings/devfreq/nvidia,tegra30-actmon.yaml  | 13 ++++++++-----
 1 file changed, 8 insertions(+), 5 deletions(-)

diff --git a/Documentation/devicetree/bindings/devfreq/nvidia,tegra30-actmon.yaml b/Documentation/devicetree/bindings/devfreq/nvidia,tegra30-actmon.yaml
index e3379d1067283e36d1bee303187c0205b410f610..ea1dc86bc31f635f91a0e36f908f5c0c4f9a804c 100644
--- a/Documentation/devicetree/bindings/devfreq/nvidia,tegra30-actmon.yaml
+++ b/Documentation/devicetree/bindings/devfreq/nvidia,tegra30-actmon.yaml
@@ -19,11 +19,14 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - nvidia,tegra30-actmon
-      - nvidia,tegra114-actmon
-      - nvidia,tegra124-actmon
-      - nvidia,tegra210-actmon
+    oneOf:
+      - enum:
+          - nvidia,tegra30-actmon
+          - nvidia,tegra114-actmon
+          - nvidia,tegra124-actmon
+      - items:
+          - const: nvidia,tegra210-actmon
+          - const: nvidia,tegra124-actmon
 
   reg:
     maxItems: 1

---
base-commit: 211ddde0823f1442e4ad052a2f30f050145ccada
change-id: 20251021-t210-actmon-p1-ef2b9164005d

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

