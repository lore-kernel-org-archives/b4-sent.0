From: Aaron Kling <webgeek1234@gmail.com>
Date: Thu, 28 Aug 2025 23:01:27 -0500
Subject: [PATCH RFC 1/7] dt-bindings: memory: tegra210: Add memory client
 IDs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250828-t210-actmon-v1-1-aeb19ec1f244@gmail.com>
References: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
In-Reply-To: <20250828-t210-actmon-v1-0-aeb19ec1f244@gmail.com>
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Kyungmin Park <kyungmin.park@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, Dmitry Osipenko <digetx@gmail.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-pm@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756440091; l=2616;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=u4jz33x6Ez21364iFx09PcoppaXBOvLz3qVMpDfajQM=;
 b=m1jxhHdKoPFZbeE5b5CEydY9vL/nIxb8kfbWqUxh9MIowUA0CJdPkGslCm5gcUgNNl2aZySSz
 1H0mjH3A0pKC2Z+L0pNc8GE+Wd4Ae1Okmq2rU5RvyUxl/hI658alIco
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Each memory client has unique hardware ID, add these IDs.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 include/dt-bindings/memory/tegra210-mc.h | 58 ++++++++++++++++++++++++++++++++
 1 file changed, 58 insertions(+)

diff --git a/include/dt-bindings/memory/tegra210-mc.h b/include/dt-bindings/memory/tegra210-mc.h
index 5e082547f1794cba1f72872782e04d8747863b6d..48474942a000e049142014e3bcc132b88bf1a92d 100644
--- a/include/dt-bindings/memory/tegra210-mc.h
+++ b/include/dt-bindings/memory/tegra210-mc.h
@@ -75,4 +75,62 @@
 #define TEGRA210_MC_RESET_ETR		28
 #define TEGRA210_MC_RESET_TSECB		29
 
+#define TEGRA210_MC_PTCR		0
+#define TEGRA210_MC_DISPLAY0A		1
+#define TEGRA210_MC_DISPLAY0AB		2
+#define TEGRA210_MC_DISPLAY0B		3
+#define TEGRA210_MC_DISPLAY0BB		4
+#define TEGRA210_MC_DISPLAY0C		5
+#define TEGRA210_MC_DISPLAY0CB		6
+#define TEGRA210_MC_AFIR		14
+#define TEGRA210_MC_AVPCARM7R		15
+#define TEGRA210_MC_DISPLAYHC		16
+#define TEGRA210_MC_DISPLAYHCB		17
+#define TEGRA210_MC_HDAR		21
+#define TEGRA210_MC_HOST1XDMAR		22
+#define TEGRA210_MC_HOST1XR		23
+#define TEGRA210_MC_NVENCSRD		28
+#define TEGRA210_MC_PPCSAHBDMAR		29
+#define TEGRA210_MC_PPCSAHBSLVR		30
+#define TEGRA210_MC_SATAR		31
+#define TEGRA210_MC_MPCORER		39
+#define TEGRA210_MC_NVENCSWR		43
+#define TEGRA210_MC_AFIW		49
+#define TEGRA210_MC_AVPCARM7W		50
+#define TEGRA210_MC_HDAW		53
+#define TEGRA210_MC_HOST1XW		54
+#define TEGRA210_MC_MPCOREW		57
+#define TEGRA210_MC_PPCSAHBDMAW		59
+#define TEGRA210_MC_PPCSAHBSLVW		60
+#define TEGRA210_MC_SATAW		61
+#define TEGRA210_MC_ISPRA		68
+#define TEGRA210_MC_ISPWA		70
+#define TEGRA210_MC_ISPWB		71
+#define TEGRA210_MC_XUSB_HOSTR		74
+#define TEGRA210_MC_XUSB_HOSTW		75
+#define TEGRA210_MC_XUSB_DEVR		76
+#define TEGRA210_MC_XUSB_DEVW		77
+#define TEGRA210_MC_ISPRAB		78
+#define TEGRA210_MC_ISPWAB		80
+#define TEGRA210_MC_ISPWBB		81
+#define TEGRA210_MC_TSECSRD		84
+#define TEGRA210_MC_TSECSWR		85
+#define TEGRA210_MC_A9AVPSCR		86
+#define TEGRA210_MC_A9AVPSCW		87
+#define TEGRA210_MC_GPUSRD		88
+#define TEGRA210_MC_GPUSWR		89
+#define TEGRA210_MC_DISPLAYT		90
+#define TEGRA210_MC_SDMMCRA		96
+#define TEGRA210_MC_SDMMCRAA		97
+#define TEGRA210_MC_SDMMCR		98
+#define TEGRA210_MC_SDMMCRAB		99
+#define TEGRA210_MC_SDMMCWA		100
+#define TEGRA210_MC_SDMMCWAA		101
+#define TEGRA210_MC_SDMMCW		102
+#define TEGRA210_MC_SDMMCWAB		103
+#define TEGRA210_MC_VICSRD		108
+#define TEGRA210_MC_VICSWR		109
+#define TEGRA210_MC_VIW			114
+#define TEGRA210_MC_DISPLAYD		115
+
 #endif

-- 
2.50.1

