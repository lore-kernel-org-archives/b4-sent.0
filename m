From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 11 Jun 2025 13:53:37 -0500
Subject: [PATCH v2 1/2] dt-bindings: arm: tegra: Document Jetson Nano
 Devkits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250611-p3452-v2-1-fd2679706c63@gmail.com>
References: <20250611-p3452-v2-0-fd2679706c63@gmail.com>
In-Reply-To: <20250611-p3452-v2-0-fd2679706c63@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749668025; l=966;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Mf60xnJQd3ZVdGzSrZSW00tSIcBNG74s7GMDdM+0Kik=;
 b=Xe068+lWKL4lGkaMLThe2Yderci7TkHRZdiLjhgEWE4TX+Soqt1G5+9RUNHZKCMIpsT6Z5A8E
 H3Upl2W5Bt7A2XLViaJQAW8mQD92+bYd4tlNTLcTwm19dM0N0YcWP7S
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatibles for the Tegra210 Jetson Nano Developer Kits

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/arm/tegra.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/tegra.yaml b/Documentation/devicetree/bindings/arm/tegra.yaml
index 9cae3268a8274fd3a38580939c79a6f21de48a3f..d06d6474776ec679080aed62cab729af73ade53a 100644
--- a/Documentation/devicetree/bindings/arm/tegra.yaml
+++ b/Documentation/devicetree/bindings/arm/tegra.yaml
@@ -173,6 +173,11 @@ properties:
               - nvidia,p2371-2180
               - nvidia,p2571
               - nvidia,p2894-0050-a08
+              - nvidia,p3450-0000
+          - const: nvidia,tegra210
+      - items:
+          - const: nvidia,p3541-0000
+          - const: nvidia,p3450-0000
           - const: nvidia,tegra210
       - description: Jetson TX2 Developer Kit
         items:

-- 
2.49.0

