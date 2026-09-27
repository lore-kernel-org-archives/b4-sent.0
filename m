From: Daniel Drake <dan@reactivated.net>
Date: Sun, 27 Sep 2026 14:09:00 +0100
Subject: [PATCH v7 1/6] iommu_pt: Fix test_pgsize_boundary() failure on
 narrow-OA formats
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-bcm2712-iommu-submit-v7-1-dfa2b975cbc9@reactivated.net>
References: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
In-Reply-To: <20260927-bcm2712-iommu-submit-v7-0-dfa2b975cbc9@reactivated.net>
To: "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Daniel Drake <dan@reactivated.net>
Cc: iommu@lists.linux.dev, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-rpi-kernel@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, nick.hollinghurst@raspberrypi.com, 
 james.quinlan@broadcom.com, Jason Gunthorpe <jgg@ziepe.ca>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1340; i=dan@reactivated.net;
 h=from:subject:message-id; bh=JFow46Vnz8reduVDvIc0YSORwX6vyQZXYpGoWC0l8YY=;
 b=kA0DAAoBw+aPsVMUR7sByyZiAGq5FYShEQEKIjovVnD1hOPwEinZcQ0OYFUbR7fJ9dJFV2SiT
 IkCMwQAAQoAHRYhBDpF/SxQ/WISFd9V+MPmj7FTFEe7BQJquRWEAAoJEMPmj7FTFEe7Qv8P/i1o
 7q0v4JhmkVXw0zJ3ay5fArpJIAHgLXLRffJNLdwrOa9YfVsn+D0/FX3kLS9tAdMVGBNbT5Z1hR8
 RjUtf+wj18jGAjjsE1d99HDuEFI5fVUlA9QR5QIgtnHTx07FYUITqCMHnYwLv88NlS29vqJESlQ
 C6/6j+RRAkWz0ce+mDMwXwW/QBwZx8SCrfCkLoJa/7NGbIRXFMwa3EEL6bA4tCGYZqc+1kFBYqo
 2qcesp1j3zUAUPwgnb+0x16mD0jHaboMIDNqUT0lk+oUrSXbr8rHERHdv0Rrc8UDXEHGIKFzo98
 82IHDfIv/4Zuf7JXFrHMHtqhnYSdyucJP1qUffTeWok5vsADncPF0Yn+uHz6xyU38oIKnShjs7x
 VyhC8bYCe1HpStUZVRdl2hSnWGErXQ3ndXMaZwt5JpAYiHa4feODm7rSowu0aMzLsOEPooWjsZG
 B97JQ6SZZLzQO5dhLZWRO9Saaxz+2SGBtTaV6z04u1DNKyU9n+nd4rgVgwqCD3TVjTcrpQpNQB+
 DhIWRvGUuIGcZvzgzFehHyztrPx3uxMLUiZiGJ1gBpdeYbFB5AMqogfYGkneIe9tk910cs+Pxpu
 6UYDWUNWbhkufG01535W/S2IAYLEPd5o/eQHcwtkVAek+lz+Bah1PpxaPXFU3DqhqfS+jQw3/vq
 dU0yA
X-Developer-Key: i=dan@reactivated.net; a=openpgp;
 fpr=3A45FD2C50FD621215DF55F8C3E68FB1531447BB
X-Endpoint-Received: by B4 Relay for dan@reactivated.net/default with auth_id=1070
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

test_pgsize_boundary() tests boundary mapping with a hardcoded physical
address that requires 38 bits of physical address space. However, the
upcoming page table format for the Broadcom BCM2712 IOMMU only supports
37 bits of output address space.

This causes a test failure as iommu_map() rejects the large address
with -ERANGE.

Drop the high bits of the address (they are not relevant to the
boundary calculations being tested) so that it fits into 32 bits.

Reviewed-by: Jason Gunthorpe <jgg@nvidia.com>
Signed-off-by: Daniel Drake <dan@reactivated.net>
---
 drivers/iommu/generic_pt/kunit_iommu_pt.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iommu/generic_pt/kunit_iommu_pt.h b/drivers/iommu/generic_pt/kunit_iommu_pt.h
index ece1c9b8c55d..9fc71db74234 100644
--- a/drivers/iommu/generic_pt/kunit_iommu_pt.h
+++ b/drivers/iommu/generic_pt/kunit_iommu_pt.h
@@ -403,7 +403,7 @@ static void test_pgsize_boundary(struct kunit *test)
 	    priv->smallest_pgsz != SZ_4K)
 		kunit_skip(test, "Format does not have the required range");
 
-	do_map(test, 0xfef80000, 0x208b95d000, 0xfef9ffff - 0xfef80000 + 1);
+	do_map(test, 0xfef80000, 0x8b95d000, 0xfef9ffff - 0xfef80000 + 1);
 }
 
 /* See https://lore.kernel.org/r/20250826143816.38686-1-eugkoira@amazon.com */

-- 
2.55.0

