From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Jun 2026 19:02:04 -0500
Subject: [PATCH v3 01/23] PCI: Add SNIA SDXI accelerator sub-class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-sdxi-base-v3-1-4d38ca2bdffe@amd.com>
References: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
In-Reply-To: <20260605-sdxi-base-v3-0-4d38ca2bdffe@amd.com>
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780704140; l=1441;
 i=nathan.lynch@amd.com; s=20260410; h=from:subject:message-id;
 bh=OwdioeWEQcxJLVaFYqBTlKzpo10yCo7NwekOCC/At7U=;
 b=9kwewPyVlVZHqx4QMSTGgh3csIXnMQl80YqCwZI/mMFGfRce66vPzr9fMKonYJTZ4LK5wOWLE
 v68SjNI/wN/CieUMRBpaR1/FmLqdFSFWRFU4a6449acS3/mpBWJ3V+A
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=PK4ozhq+/z9/2Jl5rgDmvHa9raVomv79qM8p1RAFpEw=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20260410 with auth_id=728
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
index 24cb42f66e4b..83ab3f27eb5a 100644
--- a/include/linux/pci_ids.h
+++ b/include/linux/pci_ids.h
@@ -154,6 +154,7 @@
 
 #define PCI_BASE_CLASS_ACCELERATOR	0x12
 #define PCI_CLASS_ACCELERATOR_PROCESSING	0x1200
+#define PCI_CLASS_ACCELERATOR_SDXI		0x120100
 
 #define PCI_CLASS_OTHERS		0xff
 
diff --git a/rust/kernel/pci/id.rs b/rust/kernel/pci/id.rs
index 50005d176561..d5e006cd6641 100644
--- a/rust/kernel/pci/id.rs
+++ b/rust/kernel/pci/id.rs
@@ -292,6 +292,7 @@ fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
     SP_OTHER                   = bindings::PCI_CLASS_SP_OTHER,                   // 0x118000
 
     ACCELERATOR_PROCESSING     = bindings::PCI_CLASS_ACCELERATOR_PROCESSING,     // 0x120000
+    ACCELERATOR_SDXI           = bindings::PCI_CLASS_ACCELERATOR_SDXI,           // 0x120100
 
     OTHERS                     = bindings::PCI_CLASS_OTHERS,                     // 0xff0000
 }

-- 
2.54.0

