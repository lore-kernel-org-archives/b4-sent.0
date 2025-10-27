From: Aaron Kling <webgeek1234@gmail.com>
Date: Mon, 27 Oct 2025 13:55:15 -0500
Subject: [PATCH v4 1/5] dt-bindings: memory: tegra186-mc: Add dummy client
 IDs for Tegra186
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-tegra186-icc-p2-v4-1-e4e4f57e2103@gmail.com>
References: <20251027-tegra186-icc-p2-v4-0-e4e4f57e2103@gmail.com>
In-Reply-To: <20251027-tegra186-icc-p2-v4-0-e4e4f57e2103@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761591315; l=816;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=PmMpfHWG2+f6l6AbTUSHWT7B2d2RhnPduQ58vW6+634=;
 b=DCAwwKCHzR6IuPhDAK5nK2GwE6NsD/XvQZiVIDxHGKZ9oSdjCJGUfI213KG24/chyyZg4nCuX
 UR41CgG/sFuAeePi2WuDQxhZj9ZflKFML4Om+Zwkb+JxvdZjcFBrwuK
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
2.51.0

