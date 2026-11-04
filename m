From: Nathan Lynch <nathan.lynch@amd.com>
Date: Tue, 03 Nov 2026 20:49:42 -0600
Subject: [PATCH v4 01/25] PCI: Add SNIA SDXI accelerator sub-class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-sdxi-base-v4-1-3668ccc7aab8@amd.com>
References: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
In-Reply-To: <20261103-sdxi-base-v4-0-3668ccc7aab8@amd.com>
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: Bjorn Helgaas <bhelgaas@google.com>, 
 David Rientjes <rientjes@google.com>, John.Kariuki@amd.com, 
 Jonathan Cameron <jic23@kernel.org>, Kinsey Ho <kinseyho@google.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 PradeepVineshReddy.Kodamati@amd.com, Shivank Garg <shivankg@amd.com>, 
 Stephen Bates <Stephen.Bates@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Wei Huang <wei.huang2@amd.com>, Wei Xu <weixugc@google.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793760600; l=1441;
 i=nathan.lynch@amd.com; s=20260722; h=from:subject:message-id;
 bh=HRHBHsVrsPkhfleJt5OBxEfrKMfiC19WMsFKZuGKy20=;
 b=m5f++TxThWkgV2jkX4Aooxp6TSW96jcTFHmilmjD+IKhFsRoC3Q82tlJBBwMlU8WU8prKM6Ql
 sq2uuAVvLYPBTdJFVPu3wQcJvxw2nSchc8jt1eu1Usd9LuG47WXLqZr
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=pO5+BCw/TENGLvwX5NYZOZmZihcxjkxeFSMuk47erps=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260722 with auth_id=891
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make the class code for SNIA Smart Data Accelerator Interface (SDXI)
functions available to both C and Rust code.

See PCI Code and ID Assignment spec r1.14, sec 1.19.

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 include/linux/pci_ids.h | 1 +
 rust/kernel/pci/id.rs   | 1 +
 2 files changed, 2 insertions(+)

diff --git a/include/linux/pci_ids.h b/include/linux/pci_ids.h
index 030c86dd6d67..dcb26f52b5a1 100644
--- a/include/linux/pci_ids.h
+++ b/include/linux/pci_ids.h
@@ -154,6 +154,7 @@
 
 #define PCI_BASE_CLASS_ACCELERATOR	0x12
 #define PCI_CLASS_ACCELERATOR_PROCESSING	0x1200
+#define PCI_CLASS_ACCELERATOR_SDXI		0x120100
 
 #define PCI_CLASS_OTHERS		0xff
 
diff --git a/rust/kernel/pci/id.rs b/rust/kernel/pci/id.rs
index dbaf301666e7..d714e4b83852 100644
--- a/rust/kernel/pci/id.rs
+++ b/rust/kernel/pci/id.rs
@@ -292,6 +292,7 @@ fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
     SP_OTHER                   = bindings::PCI_CLASS_SP_OTHER,                   // 0x118000
 
     ACCELERATOR_PROCESSING     = bindings::PCI_CLASS_ACCELERATOR_PROCESSING,     // 0x120000
+    ACCELERATOR_SDXI           = bindings::PCI_CLASS_ACCELERATOR_SDXI,           // 0x120100
 
     OTHERS                     = bindings::PCI_CLASS_OTHERS,                     // 0xff0000
 }

-- 
2.56.0

