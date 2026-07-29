From: Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
Subject: [PATCH bpf v4 0/4] bpf: Preserve pointer state for commuted
 arithmetic
Date: Wed, 29 Jul 2026 15:18:26 +0000
Message-Id: <20260729-c3-035-public-bpf-v4-v4-0-8ee297e2346b@mails.tsinghua.edu.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMIZamoC/x2MSQqAMAwAvyI5G4i1rl8RD7amGhAtLYog/t3ic
 WBmHogchCP02QOBL4ly7Al0noFdp31hlDkxKFI1NapDWyKVFfrTbGLReIeXRjKqnTQTF+wgpT6
 wk/vfDpAcGN/3A0Corz5rAAAA
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: John Fastabend <john.fastabend@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Shung-Hsi Yu <shung-hsi.yu@suse.com>, Daniel Wade <danjwade95@gmail.com>, 
 bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785338329; l=3434;
 i=chenyy23@mails.tsinghua.edu.cn; s=kernel; h=from:subject:message-id;
 bh=kvzOz+pD3rr/TmfPHw9vR90Y3iMUBOxN+9qGwOovYBY=;
 b=jFMjmF8sYmrK3IVJNkS9/UMTjigMq1lhiAAkr9vrzQfjS7R8a0A+NQ+uaxo9GtAE4tnJ4ka6s
 8w/BTSllS8nBaO4E2pOmr1RItt9fdlU7wrvIWtKPO+joSs4gcRC7or3
X-Developer-Key: i=chenyy23@mails.tsinghua.edu.cn; a=ed25519;
 pk=+Q11PEDVzoU+87KHlIeNWKwv/GiutzE5094ej7opM+s=
X-Endpoint-Received: by B4 Relay for chenyy23@mails.tsinghua.edu.cn/kernel with auth_id=900
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes pointer-state propagation for commuted scalar += pointer
arithmetic in the verifier.

Patch 1 simplifies sanitize_err() before the pointer-state change. Patch 2
keeps the full pointer register state when the pointer operand is the source
of the add, preserving fields such as the stack frame number and parent id.
Patch 3 moves the untrusted PTR_TO_MEM early return after state propagation,
so scalar += untrusted_pointer remains usable through the probe-read path.
Patch 4 adds verifier selftests for stack frame number preservation,
readonly-untrusted memory access, and dynptr data-slice invalidation.

Changes in v4:
- Target the bpf fixes tree because the affected behavior is present in
  released kernels.
- Add Eduard's sanitize_err() cleanup and revised pointer-state patch, reusing
  the caller's temporary offset register instead of verifier-env scratch
  storage.
- Correct the stack-frame Fixes tag to the BPF-to-BPF call verification
  commit identified by Shung-Hsi.
- Fix the dynptr test comment style and retain the source-register clear so
  the test isolates parent-id propagation.
- Carry Daniel Wade's Tested-by and Eduard's selftest Acked-by from the v3
  thread.
- Rebase to bpf base 0ce37745d4bf.

Changes in v3:
- Preserve the complete pointer register state with verifier-env scratch
  storage, addressing Eduard's comment that copying selected fields is
  fragile and avoiding a temporary bpf_reg_state on the verifier stack.
- Keep the existing RUN(verifier_basic_stack) dispatch unchanged and add the
  stack regression directly to the existing verifier_basic_stack program.
- Keep the original operand direction inside adjust_ptr_min_max_vals() by
  saving the scalar operand in env->fake_reg[0].
- Move untrusted PTR_TO_MEM handling after the unified pointer-state copy so
  the commuted form remains PTR_TO_MEM before the early return.
- Add readonly-untrusted and dynptr selftest coverage, responding to the
  bpf-ci/static review finding that the untrusted pointer case needs a
  regression test.
- Clear the original dynptr data-slice register after deriving the commuted
  alias so the regression test isolates parent-id propagation.
- Make the readonly-untrusted return value endian-neutral by loading an int.
- Rebase to bpf-next base a23a71823352.

v3: https://lore.kernel.org/bpf/cover.1784696371.git.chenyy23@mails.tsinghua.edu.cn/
v2: https://lore.kernel.org/bpf/cover.1784563950.git.chenyy23@mails.tsinghua.edu.cn/
v1: https://lore.kernel.org/bpf/cover.1784563939.git.chenyy23@mails.tsinghua.edu.cn/

---
Eduard Zingerman (1):
      bpf: simplify sanitize_err() signature

Yiyang Chen (3):
      bpf: Preserve pointer state for commuted arithmetic
      bpf: Propagate untrusted pointer state in commuted arithmetic
      selftests/bpf: Cover commuted pointer state propagation

 kernel/bpf/verifier.c                              | 45 +++++++++++-----------
 tools/testing/selftests/bpf/progs/dynptr_fail.c    | 30 +++++++++++++++
 .../selftests/bpf/progs/mem_rdonly_untrusted.c     | 17 ++++++++
 .../selftests/bpf/progs/verifier_basic_stack.c     | 41 ++++++++++++++++++++
 4 files changed, 110 insertions(+), 23 deletions(-)
---
base-commit: 0ce37745d4bfbc493f718169c3974898ffec8ee7
change-id: 20260729-c3-035-public-bpf-v4-0b28a4e0e1ef

Best regards,
-- 
Yiyang Chen <chenyy23@mails.tsinghua.edu.cn>

