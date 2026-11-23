From: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
Date: Mon, 23 Nov 2026 13:03:46 +0200
Subject: [PATCH v2] x86/apic: Use the physical address for the local APIC
 resource
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-x86-apic-lapic-resource-v2-1-4474a572aaaf@ahmedabdelfattah.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6DIBREr2JYl0Zoo6Sr3qNx8YFP+Y1VA0hsj
 Hcv2gN0M8lLZuatLGIgjOxWrSxgpkjjUECeKmY8DE/kZAszWctGiLrli2o4TGR4f2TAOM7BIEf
 plAILqmlbVtZTQEfL8fzofhxn/UKT9ru94SmmMXwOdRZ7778lCy64VBavRl+cFngH/0YL2mLvI
 CXwZ4uZddu2fQFRb2fD2wAAAA==
X-Change-ID: 20261107-x86-apic-lapic-resource-e2f88ada8677
To: Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 "Peter Zijlstra (Intel)" <peterz@infradead.org>
Cc: Chao Gao <chao.gao@intel.com>, linux-kernel@vger.kernel.org, 
 Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795431826; l=3170;
 i=me@ahmedabdelfattah.dev; s=20261106; h=from:subject:message-id;
 bh=p400VXiAp13U+yYuNFSSnKSaZgbslssngT6wil6wIzw=;
 b=2VnWAHyFn4bRSQqUqBq272f3f0aqF0rnYaPnO+bTpi3hzRguU1BCUmjeLyHFKBowiGaApwyQn
 Pin5t8PR8dpC8QTErelHwpZ+rjI/RM/Re9KzHJuZLN4H/ZLE4dKJYBk
X-Developer-Key: i=me@ahmedabdelfattah.dev; a=ed25519;
 pk=DHEHKU4PddrkJ/iYMZpwyyXsFyIQ6ySjTttKLrt9YqI=
X-Endpoint-Received: by B4 Relay for me@ahmedabdelfattah.dev/20261106 with auth_id=1438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since v6.6 the "Local APIC" entry is missing from /proc/iomem whenever
the kernel maps the xAPIC itself.

lapic_insert_resource() takes the start of the resource from apic_phys,
which used to hold mp_lapic_addr. Commit 81287ad65da5 ("x86/apic:
Sanitize APIC address setup") moved that assignment to
apic_set_fixmap(), where it became the fixmap virtual address:

	apic_phys = apic_mmio_base = APIC_BASE;

Commit 78c32000848c ("x86/apic: Get rid of apic_phys") then replaced
apic_phys with apic_mmio_base, which holds the same value:

  APIC: Mapped APIC to ffffffffff5fc000 (        fee00000)

insert_resource() rejects that range because it lies outside
iomem_resource, and as the return value is not checked, the failure
goes unnoticed.

Without the resource the local APIC page is no longer marked busy. So
apart from the line missing in /proc/iomem, CONFIG_IO_STRICT_DEVMEM
does not stop /dev/mem from mapping the page any more, and in xAPIC
mode the APIC registers can be read and written through it.

Use mp_lapic_addr, which is the address apic_set_fixmap() maps. Keep
the apic_mmio_base check, so the resource is still only added when the
APIC was actually mapped.

Fixes: 81287ad65da5 ("x86/apic: Sanitize APIC address setup")
Signed-off-by: Ahmed Abdelfattah <me@ahmedabdelfattah.dev>
---
This showed up while comparing /proc/iomem with the memory map of a
QEMU guest.

Tested on QEMU q35 with KVM (x86_64_defconfig + kvm_guest.config),
booting with and without nox2apic. Without the patch there is no
"Local APIC" entry in either case; with it both show

  fee00000-fee00fff : Local APIC

For the /dev/mem part I used v7.4-rc3+ (4405c18c95d2) with a
distribution config that has CONFIG_IO_STRICT_DEVMEM=y, and a small
program that maps one page of /dev/mem. Without the patch the page at
0xfee00000 can be mapped. Booted with nox2apic, the APIC version
register reads 0x00050014 through it and a write to the task priority
register is accepted. With the patch the mmap() fails with EPERM in
both boots, as it does for the IOAPIC page.
---
Changes in v2:
- Fixes: now names the commit that made apic_phys a virtual address
  (Chao Gao)
- Say what the missing resource changes for users (Chao Gao)
- Link to v1: https://patch.msgid.link/20261107-x86-apic-lapic-resource-v1-1-28de4cb3fb1e@ahmedabdelfattah.dev
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

