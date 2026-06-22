From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Subject: [PATCH v2 00/16] riscv: Generate riscv instruction functions
Date: Sun, 21 Jun 2026 21:01:18 -0700
Message-Id: <20260621-riscv_insn_table-v2-0-7f0810ee2274@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNQQqDMBREryJ/3ZTERNN21XsUkWi++kGTkkhoE
 e/e1C4Ls3kD82aDiIEwwq3YIGCiSN5lKE8F9JNxIzKymaHkZc2FUCxQ7FNLLrp2Nd2MTF7Utcq
 xg5WQZ8+AA70O5aPJPFFcfXgfD0l8259Mcf0vS4JxVqlOaVkbgVrfx8XQfO79As2+7x81PW/7s
 AAAAA==
X-Change-ID: 20260114-riscv_insn_table-38495495dfd3
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Nam Cao <namcao@linutronix.de>, Alexandre Ghiti <alex@ghiti.fr>, 
 Anup Patel <anup@brainfault.org>, Atish Patra <atish.patra@linux.dev>, 
 Conor Dooley <conor@kernel.org>, Paolo Bonzini <pbonzini@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>, 
 =?utf-8?q?Radim_Kr=C4=8Dm=C3=A1=C5=99?= <radim.krcmar@oss.qualcomm.com>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kvm@vger.kernel.org, kvm-riscv@lists.infradead.org, 
 linux-kselftest@vger.kernel.org, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=5328;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=2Ue0OQWnzEfJvkx9yKoYjaChcgTBWEXuzcW+rzKXsR8=;
 b=ne5wljDoG4zphFx5l9ULUKiRBpeUuwuxY2AbZ2BeN3QgGMMOIAhW6sy1FiM117AEx+Bc6kL8v
 lqEFZx/bszkD8yBFpdr3oY3ukUz9KPteAWALGmMar+HG5pTqTeSTnDX
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is a lot of code that is manually manipulating riscv instructions.
Constructing these headers for new instructions is time consuming and
error prone.

The first patch in this series introduces the instruction definition
table along with a script that runs at compile time to create all of the
associated instruction manipulation functions. The remaining patches
migrate all of the manual instruction code to use these generated
functions.

The instruction definition table is generated from the
riscv-unified-db[1], an open source RVI project for instruction
specifications. I got this table generation merged into
riscv-unified-db, that PR can be accessed on github [2].

A lot of the validation for these changes is from running all possible
32-bit or 16-bit integers through these functions to see that any given
instruction will produce to expected result. I give more detail on the
test cases in the notes of the first couple of patches.

For the KVM patches, I also introduce two test cases to ensure that the
instruction manipulation is working as expected.

[1] https://github.com/riscv/riscv-unified-db
[2] https://github.com/riscv/riscv-unified-db/pull/1780

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
Changes in v2:
- rebased on v7.1
- I dropped the patch fixing the mmio bug in kvm because in the
  meantime that bug has been fixed in a different patch
- Calls to panic() for instructions not support on current hardware have
  been changed into BUG_ON()
- Fixed incorrect handling of branches in simulate_*()
- Added CONFIG_RISCV_KPROBES_SIMULATE_KUNIT for more detailed
  simulate_*() testing
- Updated insn.tbl based on new merged in changes to riscv-unified-db
- Link to v1: https://lore.kernel.org/r/20260407-riscv_insn_table-v1-0-54b4736a1e77@gmail.com

---
Charlie Jenkins (16):
      riscv: Introduce instruction table generation
      riscv: alternatives: Use generated instruction headers for patching code
      riscv: kgdb: Use generated instruction headers
      riscv: Add kprobes instruction simulation KUnit
      riscv: kprobes: Use generated instruction headers
      riscv: cfi: Use generated instruction headers
      riscv: Use generated instruction headers for misaligned loads/stores
      riscv: kvm: Use generated instruction headers for csr code
      KVM: device: Add test device
      KVM: riscv: selftests: Add mmio test
      riscv: kvm: Use generated instruction headers for mmio emulation
      riscv: kvm: Add emulated test csr
      KVM: riscv: selftests: Add csr emulation test
      riscv: kvm: Use generated instruction headers for csr emulation
      riscv: kexec: Use generated instruction headers for kexec relocations
      riscv: Remove unused instruction headers

 arch/riscv/Kconfig.debug                           |    1 +
 arch/riscv/Makefile                                |    3 +
 arch/riscv/include/asm/Kbuild                      |    1 +
 arch/riscv/include/asm/insn.h                      |  563 +-------
 arch/riscv/include/asm/kvm_host.h                  |   10 +
 arch/riscv/include/asm/kvm_vcpu_insn.h             |    5 +-
 arch/riscv/include/asm/kvm_vcpu_test_csr.h         |   15 +
 arch/riscv/kernel/alternative.c                    |   23 +-
 arch/riscv/kernel/cfi.c                            |    6 +-
 arch/riscv/kernel/kgdb.c                           |  102 +-
 arch/riscv/kernel/machine_kexec_file.c             |   55 +-
 arch/riscv/kernel/probes/decode-insn.c             |    7 +-
 arch/riscv/kernel/probes/simulate-insn.c           |  253 ++--
 arch/riscv/kernel/probes/simulate-insn.h           |    7 +-
 arch/riscv/kernel/tests/Kconfig.debug              |   13 +
 arch/riscv/kernel/tests/kprobes/Makefile           |    2 +
 .../kernel/tests/kprobes/test-kprobes-simulate.c   |  250 ++++
 arch/riscv/kernel/tests/kprobes/test-kprobes.h     |    6 +
 arch/riscv/kernel/traps_misaligned.c               |  183 ++-
 arch/riscv/kvm/Kconfig.debug                       |   16 +
 arch/riscv/kvm/Makefile                            |    1 +
 arch/riscv/kvm/vcpu_insn.c                         |  232 ++--
 arch/riscv/kvm/vcpu_test_csr.c                     |   21 +
 arch/riscv/tools/Makefile                          |   22 +
 arch/riscv/tools/insn.tbl                          | 1392 ++++++++++++++++++++
 arch/riscv/tools/insn_tbl.sh                       |  256 ++++
 include/uapi/linux/kvm.h                           |    2 +
 lib/Kconfig.debug                                  |    6 +
 tools/testing/selftests/kvm/Makefile.kvm           |    2 +
 tools/testing/selftests/kvm/riscv/csr_test.c       |  126 ++
 tools/testing/selftests/kvm/riscv/mmio_test.c      |  184 +++
 virt/kvm/Kconfig.debug                             |   16 +
 virt/kvm/Makefile.kvm                              |    1 +
 virt/kvm/kvm_main.c                                |    8 +
 virt/kvm/mmio_test.c                               |   95 ++
 virt/kvm/mmio_test.h                               |   18 +
 36 files changed, 2897 insertions(+), 1006 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260114-riscv_insn_table-38495495dfd3

Best regards,
--  
Charlie Jenkins <thecharlesjenkins@gmail.com>

