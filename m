From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 10 Apr 2026 08:07:12 -0500
Subject: [PATCH 02/23] MAINTAINERS: Add entry for SDXI driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-sdxi-base-v1-2-1d184cb5c60a@amd.com>
References: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
In-Reply-To: <20260410-sdxi-base-v1-0-1d184cb5c60a@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Jonathan Cameron <jonathan.cameron@huawei.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, PradeepVineshReddy.Kodamati@amd.com, 
 John.Kariuki@amd.com, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org, 
 Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775826467; l=957;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=tqnIKUQ/EyLmPhjhcEIOb2dPPBxNHEJNAOATM/Xpro4=;
 b=CWe5mwrd2PJa7wLdnOmVyBrciLI3IiIUPOqT+6YgXzYTQ16BNNSjKI6Cd5+CS/WT5F3XAtFMG
 i5fq/eAIO7ADCuz0sq3F5fv+igtAwI9pup/ECs94DNbPDvVVVwOfZVl
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an entry for the SDXI driver to MAINTAINERS. Wei and I will
maintain the driver.

The SDXI specification and other materials may be found at:

  https://www.snia.org/sdxi

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index b38452804a2d..5aa7b6cd93f9 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -23831,6 +23831,13 @@ L:	sdricohcs-devel@lists.sourceforge.net (subscribers-only)
 S:	Maintained
 F:	drivers/mmc/host/sdricoh_cs.c
 
+SDXI (Smart Data Accelerator Interface) DRIVER
+M:	Nathan Lynch <nathan.lynch@amd.com>
+M:	Wei Huang <wei.huang2@amd.com>
+L:	dmaengine@vger.kernel.org
+S:	Supported
+F:	drivers/dma/sdxi/
+
 SECO BOARDS CEC DRIVER
 M:	Ettore Chimenti <ek5.chimenti@gmail.com>
 S:	Maintained

-- 
2.53.0

