From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Sat, 07 Nov 2026 00:08:07 +0200
Subject: [PATCH] x86/apic: Use the physical address for the local APIC
 resource
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-x86-apic-lapic-resource-v1-1-28de4cb3fb1e@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMBCE4VeRPXfB5JCEvkrpIY1jXSkqu7UI4
 rs3tZeB7zD/TgYVGF2bnRQfMZmnCndpqAx5eoKlqybf+uBcG3lLgfMihV/nKmxetYDh+5Ryl1O
 Ikep7UfSyneXb/W9bHyPK+5ej4/gC/Gn7NXsAAAA=
X-Change-ID: 20261107-x86-apic-lapic-resource-e2f88ada8677
To: Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 "Peter Zijlstra (Intel)" <peterz@infradead.org>
Cc: linux-kernel@vger.kernel.org, 
 Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794002892; l=1942;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=SomVT+8jY+UWMuch1Im0ts42WOl22oH4Ih7Wd2VbXQ0=;
 b=u1CCahQz+RJLuoJ9j4aVIhSv13Vg6bc6UrD7LZzgeQj4YcS9hwmx83Dr2MrUk8KMDEDunoPbL
 5V+9+wE+MYMA2a60CQhiAlDQX/MHJ1aRTIbnKrKw13m91RitqqqKKhq
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since v6.6 the "Local APIC" entry is missing from /proc/iomem whenever
the kernel maps the xAPIC itself.

lapic_insert_resource() used to take the address from apic_phys. When
apic_phys went away it was switched to apic_mmio_base, but that holds
the fixmap virtual address, not the physical one:

  APIC: Mapped APIC to ffffffffff5fc000 (        fee00000)

insert_resource() rejects that range because it lies outside
iomem_resource, and as the return value is not checked, the failure
goes unnoticed.

Use mp_lapic_addr, which is the address apic_set_fixmap() maps. Keep
the apic_mmio_base check, so the resource is still only added when the
APIC was actually mapped.

Fixes: 78c32000848c ("x86/apic: Get rid of apic_phys")
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
This showed up while comparing /proc/iomem with the memory map of a
QEMU guest.

Tested on QEMU q35 with KVM (x86_64_defconfig + kvm_guest.config),
booting with and without nox2apic. Without the patch there is no
"Local APIC" entry in either case; with it both show

  fee00000-fee00fff : Local APIC

as before 78c32000848c.
---
 arch/x86/kernel/apic/apic.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/x86/kernel/apic/apic.c b/arch/x86/kernel/apic/apic.c
index 90025451ace2..17525b5daa0d 100644
--- a/arch/x86/kernel/apic/apic.c
+++ b/arch/x86/kernel/apic/apic.c
@@ -2667,7 +2667,7 @@ static int __init lapic_insert_resource(void)
 		return -1;
 
 	/* Put local APIC into the resource map. */
-	lapic_resource.start = apic_mmio_base;
+	lapic_resource.start = mp_lapic_addr;
 	lapic_resource.end = lapic_resource.start + PAGE_SIZE - 1;
 	insert_resource(&iomem_resource, &lapic_resource);
 

---
base-commit: d48723711bae9b8cdc56719c448ba42fef28cbee
change-id: 20261107-x86-apic-lapic-resource-e2f88ada8677

Best regards,
--  
Ahmed Abdelfattah <me@ahmedabdelfattah.dev>

