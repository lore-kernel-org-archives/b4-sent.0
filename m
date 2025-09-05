From: Nathan Lynch <nathan.lynch@amd.com>
Date: Fri, 05 Sep 2025 13:48:24 -0500
Subject: [PATCH RFC 01/13] PCI: Add SNIA SDXI accelerator sub-class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250905-sdxi-base-v1-1-d0341a1292ba@amd.com>
References: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
In-Reply-To: <20250905-sdxi-base-v1-0-d0341a1292ba@amd.com>
To: Vinod Koul <vkoul@kernel.org>
Cc: Wei Huang <wei.huang2@amd.com>, 
 Mario Limonciello <mario.limonciello@amd.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, linux-pci@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dmaengine@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757098128; l=1221;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=cLbH23/lVKsKayqAoeaUUitg+lat6CFljkhFBcYIeRM=;
 b=z9iadhwq4aD126u/pxl2+eSCYi+5s2XIYfBIZ0WB/TKWi1ktB0fifgdSB9s7gYkn25U3fmNN1
 QlPrDkwGK6PBcfvYKWduOxi3i5WNamHtWmlNveGYblcipp4gDeqSIL3
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This was added to the PCI Code and ID Assignment Specification in
revision 1.14 (2021). Refer to 1.19. "Base Class 12h" of that document
as well as the "SDXI PCI-Express Device Architecture" chapter of the
SDXI specification:

"""
  SDXI functions are expected to be identified through the SDXI class
  code.
  * SNIA Smart Data Accelerator Interface (SDXI) controller:
    * Base Class = 0x12
    * Sub Class = 0x01
    * Programming Interface = 0x0
"""

Information about SDXI may be found at the SNIA website:

  https://www.snia.org/sdxi

Co-developed-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Wei Huang <wei.huang2@amd.com>
Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 include/linux/pci_ids.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/pci_ids.h b/include/linux/pci_ids.h
index 92ffc4373f6de3dcf82226a50d0e36af366e888e..ac9bb3d64949919019d40d1f86cd3658bfb1c661 100644
--- a/include/linux/pci_ids.h
+++ b/include/linux/pci_ids.h
@@ -154,6 +154,7 @@
 
 #define PCI_BASE_CLASS_ACCELERATOR	0x12
 #define PCI_CLASS_ACCELERATOR_PROCESSING	0x1200
+#define PCI_CLASS_ACCELERATOR_SDXI		0x120100
 
 #define PCI_CLASS_OTHERS		0xff
 

-- 
2.39.5

