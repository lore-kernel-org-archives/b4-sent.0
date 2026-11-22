From: YanXin Li <fadouse@pm.me>
Subject: [PATCH bpf v3 0/2] bpf: bound arena allocations to the user VMA
Date: Sun, 22 Nov 2026 19:28:34 +0800
Message-Id: <20261122-b4-03-bpf-arena-vmalloc-oob-v3-da2dc21683c6-v3-0-1f94ae9a884a@pm.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOLRAmsC/yWN0WrDMAxFf6XouWK2ZLTQXyl9kG159UiTYndhJ
 fTfm2yP93A5Z4VurVqH02GFZkvtdZ62wccDpKtOX4Y1bxvIkXhPhDGgY4z3gtpsUlxuOo5zwnm
 OuDBmpZzIy8BJ0EvUpBK5kIfNeG9W6u9f7QybAi7/sP/Eb0uPvbPfonbD2HRK1x01G/WJO/xII
 XgXCkugrJ/kvAQXSIgtDEwDi1rJeTB4vd7hg/Mn2gAAAA==
X-Change-ID: 20261122-b4-03-bpf-arena-vmalloc-oob-v3-da2dc21683c6-16baca6b3f21
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795346949; l=1499;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=COKNqL4nI/46X68yJCZPIZvXWvI3Jps4kTw9tNbbcx4=;
 b=EUNVg8NGYoj2WTffKgAt+mEAWKVgMBjshnXixmU9nBKOR62IA2jKTlLhlD62jRiONzl969mXP
 GwS5SCeS8w7DywrzgUEUKTX3djnCXlWbv/XxOg1AU7trC7c+JLHy44F
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When map_extra is omitted, a short first mmap() can leave free arena
pages beyond the user VMA. Automatic allocation can select those pages;
near a 4 GiB boundary, the kernel mapping can extend past the arena's
vmalloc reservation. Patch 1 confines the range tree to the VMA, and
patch 2 adds a regression selftest.

---
Changes in v3:
- Correct the 288-page boundary calculation and describe the vmalloc guard.
- Distinguish out-of-VMA allocations from 32-bit wrap and limit claims to
  what the local test establishes.
- Remove the unreachable arena_adjust_tree() bound check.
- Point Fixes at the range-tree conversion and identify the test commit.
- Split the regression selftest into patch 2/2 and skip it when arena
  program loading returns -EOPNOTSUPP with JIT disabled.
- Link to v2: https://lore.kernel.org/r/20261122-b4-03-bpf-arena-vmalloc-oob-v2-5f6209c1a20e-v2-1-b2a9906e9676@pm.me

---
YanXin Li (2):
      bpf: bound arena allocations to the user VMA
      selftests/bpf: test arena allocation after a short mmap

 kernel/bpf/arena.c                                 | 25 ++++++++++
 .../testing/selftests/bpf/prog_tests/arena_mmap.c  | 53 ++++++++++++++++++++++
 .../testing/selftests/bpf/progs/arena_mmap_alloc.c | 32 +++++++++++++
 3 files changed, 110 insertions(+)
---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-03-bpf-arena-vmalloc-oob-v3-da2dc21683c6-16baca6b3f21

Best regards,
--  
YanXin Li <fadouse@pm.me>

