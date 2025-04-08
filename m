From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 07 Apr 2025 23:39:48 -0500
Subject: [PATCH 1/4] media: dt-bindings: Document Tegra186 and Tegra194 cec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250407-tegra-cec-v1-1-e25dd9577b5f@gmail.com>
References: <20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com>
In-Reply-To: <20250407-tegra-cec-v1-0-e25dd9577b5f@gmail.com>
To: Hans Verkuil <hverkuil@xs4all.nl>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-tegra@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744087203; l=869;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=1LwAlwBIrxvyrSHNHTaA4FD6ANtCDiiKoFzrjcG+iF0=;
 b=BkXp7FZHAp75/VkFExYSoFSW9H4qv3hZDcLpOkXp7q2vPZTFSzPUG9IYIR3xZMvj97+Sk1Tv+
 6gbBU9V+E1JAM/Bg/RH/j8zq90awjVFB9mwgI9ddybjU9D0RjUVOc04
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are already used in device trees, so describe them here.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
index a6b73498bc217a2e884e31af91e9d8845c9b1d76..27987bc428ea1a0db8dba4910727e1ce3fa3dab3 100644
--- a/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
+++ b/Documentation/devicetree/bindings/media/cec/nvidia,tegra114-cec.yaml
@@ -18,6 +18,8 @@ properties:
       - nvidia,tegra114-cec
       - nvidia,tegra124-cec
       - nvidia,tegra210-cec
+      - nvidia,tegra186-cec
+      - nvidia,tegra194-cec
 
   clocks:
     maxItems: 1

-- 
2.48.1

