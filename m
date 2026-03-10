From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Subject: [PATCH v2 0/4] selftests: riscv: Fix compilation issues for
 v_ptrace and cfi
Date: Mon, 09 Mar 2026 18:52:09 -0700
Message-Id: <20260309-fix_selftests-v2-0-9d5a553a531e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEl5r2kC/13MTQrCMBCG4auUWRuZJm0EV95DirTptB3oj2RCU
 Erubiy4cfkO8z07CHkmgWuxg6fIwtuaQ58KcFO7jqS4zw0atUWDlRr49RCah0ASRDkzYEuV7Yy
 7QN48PeWHw7s3uSeWsPn3wcfye/1J9Z8US4XKlp3VvTY1Yncbl5bns9sWaFJKH8LiauKqAAAA
X-Change-ID: 20260304-fix_selftests-c3f0ae46b3c7
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773107537; l=1204;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=DzKG948gcs5x9YgNVim780sUPGDP+fTXP+UFVdlqzwQ=;
 b=FLwvV3VuWbMYTOsNB8g4GlIeYcaaWljR8gG/AFM7wyZlqNAq5LMBFTbAVvehUzguocGXLf516
 udEBiYriGz1AGyHpt8l8MWcFqCDNTDkQZ98VWgwZXSgMPD6nLqi8ZgE
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are a couple of compilation issues of the riscv selftests.
Coincidentally two of the issues are independent problems with not
including the header that includes the BIT() macro and the other issue
is from checkpatch incorrectly suggesting to remove non-redundant
braces.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
Changes in v2:
- Fix compilation issue reported by kernel test bot and Sergey
- Link to v1: https://lore.kernel.org/r/20260305-fix_selftests-v1-0-61b62d23500b@gmail.com

---
Charlie Jenkins (4):
      selftests: riscv: Add definition of BIT() macro
      selftests: riscv: Add braces around EXPECT_EQ()
      riscv: ptrace: Fix BIT() compilation issues
      selftests: riscv: Add license to cfi selftest

 arch/riscv/include/uapi/asm/ptrace.h                     |  1 +
 tools/testing/selftests/riscv/cfi/Makefile               |  2 ++
 tools/testing/selftests/riscv/vector/Makefile            |  7 +++++--
 tools/testing/selftests/riscv/vector/validate_v_ptrace.c | 16 ++++++++++------
 4 files changed, 18 insertions(+), 8 deletions(-)
---
base-commit: c107785c7e8dbabd1c18301a1c362544b5786282
change-id: ${change-id}

- Charlie

