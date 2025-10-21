From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 21 Oct 2025 13:29:41 -0500
Subject: [PATCH 2/5] dt-bindings: memory: tegra194-mc: Add dummy client IDs
 for Tegra194
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251021-tegra186-icc-p2-v1-2-39d53bdc9aab@gmail.com>
References: <20251021-tegra186-icc-p2-v1-0-39d53bdc9aab@gmail.com>
In-Reply-To: <20251021-tegra186-icc-p2-v1-0-39d53bdc9aab@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761071387; l=911;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=7znC8jN7FMo0ABLPSWxCMceZ2XZ3qZ4hFMoMP46i7rM=;
 b=zWJCmicg76VRVKZ6EChbYG3RAP7H+mKtBdGAUJoOUlcWWhieYyHCt4hINvVH4dOyqtlWWYLDJ
 ZpiV5v1W8ZIDbTRdhrKbtDrz0V9zm7KLsgpN/8KkXSBPdldo/0ViZ7N
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ICC IDs for dummy software clients representing CCPLEX clusters.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 include/dt-bindings/memory/tegra194-mc.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/dt-bindings/memory/tegra194-mc.h b/include/dt-bindings/memory/tegra194-mc.h
index eed48b746bc94072a6bd0af7f344dbb6f6618859..a7d97a1a470cd3cfb18c7ef45c421426ea3c7abf 100644
--- a/include/dt-bindings/memory/tegra194-mc.h
+++ b/include/dt-bindings/memory/tegra194-mc.h
@@ -407,4 +407,10 @@
 /* MSS internal memqual MIU6 write clients */
 #define TEGRA194_MEMORY_CLIENT_MIU6W 0xff
 
+/* ICC ID's for dummy MC clients used to represent CPU Clusters */
+#define TEGRA_ICC_MC_CPU_CLUSTER0       1003
+#define TEGRA_ICC_MC_CPU_CLUSTER1       1004
+#define TEGRA_ICC_MC_CPU_CLUSTER2       1005
+#define TEGRA_ICC_MC_CPU_CLUSTER3       1006
+
 #endif

-- 
2.51.0

