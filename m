From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 08 May 2025 01:07:39 -0500
Subject: [PATCH v2 2/4] dt-bindings: memory-controllers: tegra210: Allow
 fallback compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-tegra210-emc-dt-v2-2-d33dc20a1123@gmail.com>
References: <20250508-tegra210-emc-dt-v2-0-d33dc20a1123@gmail.com>
In-Reply-To: <20250508-tegra210-emc-dt-v2-0-d33dc20a1123@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 devicetree@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746684461; l=1131;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=5IbR1bmo6NLdZ9+ATxenwM0aRIdwm6/TcE2oX1FSILI=;
 b=uBUYKRVk2hA7/8KefqSsKjzmXcReRWWGodF8KPbEmLzvsiEG/GsU0LUyg5Ix+wD9tUlaLvEKO
 1AxodFDoXUIBULjrjc1nNLgXLxPto/QPazlqIhal/GEPCOb79gneVLK
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nvidia,tegra21-emc compatible is required by the Nvidia Android
bootloader to copy emc training value into the kernel dt. So allow this
as a fallback compatible to avoid needing to change the driver.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 .../devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
index 78e3417d273a329b77bf2f61de41b29017be56d3..acae6c8a6c0ab9ceaddf00342c933499350568eb 100644
--- a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
+++ b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra210-emc.yaml
@@ -16,7 +16,11 @@ description: |
 
 properties:
   compatible:
-    const: nvidia,tegra210-emc
+    oneOf:
+      - const: nvidia,tegra210-emc
+      - items:
+          - const: nvidia,tegra210-emc
+          - const: nvidia,tegra21-emc
 
   reg:
     maxItems: 3

-- 
2.48.1

