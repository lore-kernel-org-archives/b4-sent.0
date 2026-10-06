From: Viorel Cernateanu <vrilutza@gmail.com>
Subject: [PATCH 0/2] x86/kmsan: Fix two bugs in the metadata lookup
Date: Tue, 06 Oct 2026 21:10:21 +0300
Message-Id: <20261006-kmsan-serie-v1-0-07fa860ef3de@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCQAxFr1KyNpBpoVCvIi6SMW2jOMpERSy9u
 zPt8n3+ewu4ZlOHY7NA1o+5PVKBcGggzpwmRbsUhpbaPhD1eLs7J9ws1K4jIgnDEBWK8cw62ne
 rnc47+1uuGl81UR/CriiZU5zrtGeEfwzr+gcPNXc9jAAAAA==
X-Change-ID: 20261006-kmsan-serie-e33000b199ce
To: Alexander Potapenko <glider@google.com>, Marco Elver <elver@google.com>, 
 Dmitry Vyukov <dvyukov@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Peter Zijlstra <peterz@infradead.org>, Kees Cook <kees@kernel.org>
Cc: Borislav Petkov <bp@suse.de>, kasan-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, Viorel Cernateanu <vrilutza@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791310224; l=2125;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=WbGqaRbHtRgJ7moLMo1R8LVauqCNwfX6lnHlo7d/wis=;
 b=9a6NKEvMM7PCqPWjHR2uysMAJTSxRxcLisc4RrF/odFeZH8WJ8orNUKVDt+pfdzOii8EJVrSU
 Bw3gv4UegMPBYc7kV1UcSddHYndcrDwFHaX75IRcczp6yErXUPTGGHZ
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes in arch/x86/include/asm/kmsan.h, found while running KMSAN
kernels with KASLR and with CONFIG_DEBUG_PREEMPT.

Patch 1 fixes the CPU lookup for addresses in the CPU entry area, which
is wrong with KASLR, and for the last page of each area without it.

Patch 2 fixes a recursion with CONFIG_DEBUG_PREEMPT: the metadata lookup
ends up in the instrumented preempt_count_add(), and the kernel hangs
right after KMSAN is enabled.

Both were tested on v7.3-rc6 in QEMU/KVM, with x86_64_defconfig plus
x86_debug.config (without LOCK_STAT, LOCKDEP, PROVE_LOCKING, GCOV and
DWARF), KMSAN and UBSAN_BOUNDS, and with a module that poisons and then
checks the KMSAN metadata at the start and at the end of the current
CPU's entry area, so a KMSAN report means the metadata was found.

Patch 1: without it, the end of the area is missed without KASLR, and
the lookup oopses with KASLR. With it, both are found, with and without
KASLR (three boots each). On an Ivy Bridge laptop, v7.3-rc6 with this
patch and KASLR gets past the hard lockup detector setup, and the same
check finds the metadata on all four CPUs. The lookup now scans up to
nr_cpu_ids entries for addresses in the CPU entry area; I have not
measured the cost on machines with many CPUs.

Patch 2, with CONFIG_DEBUG_PREEMPT added: without it, three boots out of
three with KASLR stop after the "ATTENTION: KMSAN is a debugging tool!"
banner and never reach init. With both patches, six boots out of six
reach init, with and without KASLR, and the module above still gets its
KMSAN reports. Not tested with lockdep, PROVE_RCU or
TRACE_PREEMPT_TOGGLE, and not on hardware.

---
Viorel Cernateanu (2):
      x86/kmsan: Fix CPU entry area metadata lookup
      x86/kmsan: Don't call instrumented code from kmsan_virt_addr_valid()

 arch/x86/include/asm/kmsan.h | 76 ++++++++++++++++++++++++++++++--------------
 1 file changed, 52 insertions(+), 24 deletions(-)
---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261006-kmsan-serie-e33000b199ce

Best regards,
--  
Viorel Cernateanu <vrilutza@gmail.com>

