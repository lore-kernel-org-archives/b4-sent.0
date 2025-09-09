From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 09 Sep 2025 01:21:30 -0500
Subject: [PATCH v2 2/8] dt-bindings: memory: tegra186-mc: Add dummy client
 IDs for Tegra186
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250909-tegra186-icc-v2-2-09413724e781@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757398893; l=816;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=68sWGSUz7jYX5/edcY0jO4D+Q2zCiMMqrwxxXnLD9fA=;
 b=mvAyvsFOy2n0FwXJSnneawdexs0XZv6RZZeag9Qn7pJTitpp2x2xwnAt8idRCMpnxX4A4yavH
 JMQEsNyKQWvCKJz5WgX7etI0kAjslKURC3a/kEpL8bc0FOmYKj2une6
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ICC IDs for dummy software clients representing CCPLEX clusters.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 include/dt-bindings/memory/tegra186-mc.h | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/include/dt-bindings/memory/tegra186-mc.h b/include/dt-bindings/memory/tegra186-mc.h
index 82a1e27f73576212bc227c74adff28c5f33c6bb1..8abbc26f3123aad2dffaec6be21f99f8de1ccf89 100644
--- a/include/dt-bindings/memory/tegra186-mc.h
+++ b/include/dt-bindings/memory/tegra186-mc.h
@@ -247,4 +247,8 @@
 #define TEGRA186_MEMORY_CLIENT_VICSRD1 0xa2
 #define TEGRA186_MEMORY_CLIENT_NVDECSRD1 0xa3
 
+/* ICC ID's for dummy MC clients used to represent CPU Clusters */
+#define TEGRA_ICC_MC_CPU_CLUSTER0       1003
+#define TEGRA_ICC_MC_CPU_CLUSTER1       1004
+
 #endif

-- 
2.50.1

