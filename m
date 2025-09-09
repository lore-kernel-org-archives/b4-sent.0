From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 09 Sep 2025 01:21:31 -0500
Subject: [PATCH v2 3/8] dt-bindings: memory: tegra194-mc: Add dummy client
 IDs for Tegra194
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-tegra186-icc-v2-3-09413724e781@gmail.com>
References: <20250909-tegra186-icc-v2-0-09413724e781@gmail.com>
In-Reply-To: <20250909-tegra186-icc-v2-0-09413724e781@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757398893; l=911;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=i1j7eBKUtkZ5vfUZNnts2xOfdyQGodjxO0KvmD0RhP4=;
 b=+mOk0b/i06ueK/P6P14ptBkfr5yTbG8HMcdyQKGcpH+I2u0LS+rwBeRpXVxqddJpsO5nb5YqH
 8bHBwpkPzIVDgf2dJP5K2aZy+M9muPafg1rXDEdMM8YNQjCcigGo+eK
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
2.50.1

