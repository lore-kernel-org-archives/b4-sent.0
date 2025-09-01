From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 31 Aug 2025 22:33:49 -0500
Subject: [PATCH 1/8] dt-bindings: tegra: Add ICC IDs for dummy memory
 clients for Tegra186
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250831-tegra186-icc-v1-1-607ddc53b507@gmail.com>
References: <20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com>
In-Reply-To: <20250831-tegra186-icc-v1-0-607ddc53b507@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756697663; l=816;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=68sWGSUz7jYX5/edcY0jO4D+Q2zCiMMqrwxxXnLD9fA=;
 b=wP7+4iyKDGsDRFbZSmrt5J8akn4Ol66dV2LyX6lOR6za+KQEXYuq225AesWmVSOnfNCT7G4/v
 cgzlDXY3jB9DhkusGEln32ClWkN7k+zC0jLzLQ6tgvR0l1VyRGtd/SC
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

