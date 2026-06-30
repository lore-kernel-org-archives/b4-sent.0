From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/6] target/loongarch: Fixes for endianness problems in
 vector instruction emulation
Date: Wed, 01 Jul 2026 06:15:54 +0800
Message-Id: <20260701-loong64-be-v1-0-9c7d65e00697@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABpARGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcwND3Zz8/Lx0MxPdpFTdxJQ0i0RDUzNz0zRDJaCGgqLUtMwKsGHRsbW
 1AKAknoVcAAAA
X-Change-ID: 20260701-loong64-be-adf8a15675f1
To: qemu-devel@nongnu.org
Cc: Song Gao <gaosong@loongson.cn>, 
 Richard Henderson <richard.henderson@linaro.org>, 
 Miao Wang <shankerwangmiao@gmail.com>, b4-sent@feeds.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2079;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=Jnac3Vd6PcQZNcrRe2BiSO47pzYJgNbV2+RTOfGAG7I=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqREAex2BVC3kw/lfZqZlNNiDPz2E4t0UUuggLg
 NFVv1+819WJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCakRAHgAKCRCwMePKe/7Z
 buKhEAC8Z3FQm8oLIiC2K4tfioKYidmkdwU+AoJpNEl6sJfxtMIaymRjl8h+bDkTAnUPXbHVBcL
 kDdlzs6gQdqxQbVLS+jhuRC2KX9MaS9zhzjmSgkFa/E37toERta3iWnhCJ7kerxupnUUm7oFx61
 lalPS6ElXxa7HLCVkBOkBFmdnwKduMuRUt4LffNHYQ37i3bPua797t2ks7W3CtXl+CtofpxQ6u0
 J6hv814ZfFdJuKqUD1pAw+S4ZNfoAA7EiS9BGsbgZA4m9H7W77O4oVQ0g/p0+dbnOwwEFIIUP6q
 DwN4ciUmhWXwsU8RY5cLdposqr6afEUs0e7exOl8J9JpAlszd0tIF73taJ9dgc9er/MQylPe9pM
 XpsSAOiAH4LOKVELZ48CvxSSwmc1nP//GzxOm1j5U0CP84e5rYzVrpAeebKngCkj3aI050OKPrW
 z7ZLyEsvGFGLnkrHvN3bCiy+ViQl4wpypki0hazjubdV91xzNoTStoDZPdhn3M3QF4b+cfrdTB7
 +t6cwqQLBiI0LKIODEjsxDVLCe1kpUT7bi+weCC6Fz52bS7HzbscxZGvDYzvXlmVzPVkgLGgUex
 R3KOq00Sg2oLKOcWzA6FUpC6TNYhKehtvxwZvSrFziezdWS67YLr7u4Ywxn4qAdkQMeKngV9Esu
 vjQe2h2uzYW3W0A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The current implementation of vector instruction emulation in loongarch
target works illy on big endianness hosts. It can be reproduced using
the test cases from gcc [1]. One can cross-compile the target
loongarch64-linux-user for s390x and use qemu-s390x to run the compiled
qemu to test loongarch64 emulation on big endian hosts.

Possible reproduce steps are:

1. Install s390x cross toolchains and qemu-s390x
2. Compile qemu using ./configure --target-list=loongarch64-linux-user --cross-prefix=s390x-linux-gnu-
3. Install loongarch64 cross toolchains to compile the test cases. To
   get an accurate result, the test cases should be compiled using -O0.
   To make the error output of the test cases readable and meaningful,
   printf() should be replaced with a version without any vectorization
   optimizations, since the endianness problems will prevent printf()
   with lsx optimizations from working correctly
4. Use qemu-s390x ./qemu-loongarch64 /path/to/test_case.exe to test the
   cases on big endianness hosts.

With this patch series, all the tests in [1] can pass.

[1]: under gcc/testsuite/gcc.target/loongarch/vector in the gcc source

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Miao Wang (6):
      target/loongarch: make VReg aligned to 16 bytes
      target/loongarch: Fix offset calculation in vector registers
      target/loongarch: gen_vreplve: Fix offset calculation
      target/loongarch: gen_xvreplve0: Fix elem0 offset calculation
      target/loongarch: do_vldrepl_vl: Fix endianness when reading from guest memory
      target/loongarch: vstelm: Fix reading from vector registers

 target/loongarch/cpu.h                          |  2 +-
 target/loongarch/tcg/insn_trans/trans_vec.c.inc | 39 +++++++++++++------------
 target/loongarch/tcg/translate.c                |  6 ++--
 3 files changed, 25 insertions(+), 22 deletions(-)
---
base-commit: 30e8a06b64aa58a3990ba39cb5d09531e7d265e0
change-id: 20260701-loong64-be-adf8a15675f1

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

