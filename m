From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Subject: [PATCH 0/4] selftests: riscv: Fix compilation issues for v_ptrace
 and cfi
Date: Thu, 05 Mar 2026 00:11:28 -0800
Message-Id: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALA6qWkC/x2MQQqAIBAAvxJ7TrAUg74SEWZrLUSFGxGIf2/pO
 DAzGRgTIUNfZUj4ENN5CDR1BWHzx4qKFmFodeu00VZFeifGPd7IN6tgovZo3WxCB9JcCUX4f8N
 YygelWIRYXwAAAA==
X-Change-ID: 20260304-fix_selftests-c3f0ae46b3c7
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772698321; l=1099;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=gYM2Zj2ofG3LWdNS0SxvUK4DdqDG+3smhyDoKNXighU=;
 b=PbA6bULCrfF3E9C1MjDTVunh/nq3HMlB3jQAKG6i4ttiSAMfLj/Rauj0VuimmTEQnPJFN3VpG
 97DuiccqnPPBnFsyIt8UxxrkDrSyMa9qDznl0T9GHYkNCkMMkf6Zi3k
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
Charlie Jenkins (4):
      selftests: riscv: Add definition of BIT() macro
      selftests: riscv: Add braces around EXPECT_EQ()
      riscv: ptrace: Fix BIT() compilation issues
      selftests: riscv: Add license to cfi selftest

 arch/riscv/include/uapi/asm/ptrace.h                     |  1 +
 tools/testing/selftests/riscv/cfi/Makefile               |  2 ++
 tools/testing/selftests/riscv/vector/Makefile            |  2 ++
 tools/testing/selftests/riscv/vector/validate_v_ptrace.c | 16 ++++++++++------
 4 files changed, 15 insertions(+), 6 deletions(-)
---
base-commit: c107785c7e8dbabd1c18301a1c362544b5786282
change-id: 20260304-fix_selftests-c3f0ae46b3c7

Best regards,
-- 
Charlie Jenkins <thecharlesjenkins@gmail.com>

