From: YanXin Li <fadouse@pm.me>
Subject: [PATCH bpf v4 0/2] bpf: bound arena allocations to the user VMA
Date: Sun, 22 Nov 2026 20:35:35 +0800
Message-Id: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-0-d542d1233623@pm.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJfhAmsC/yWN0W7CMAxFfwX5edZSx2SBX0E8OIk9MnUtSqDah
 Pj3tePxHl2d84CurWqH4+4BTZfa6zytg992kC8yfSrWsm4gR2EYiDAxOo/paihNJ8HlW8Zxzjj
 PCRfG6A4ul7yPZhGNNB3ULJQUYTVem1r9+a+dYFXA+QX7PX1pvm2d7ZakK6YmU75sqOkov7jB9
 8w8ODYfmIp8kBsCO6ZAXjl6ij6IWilR4fn8AyNqmCDaAAAA
X-Change-ID: 20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-f2eb9eff6db8
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795350970; l=1694;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=e0ZiUtyczM9A0TUsQiCpAJ4gxT0Nz/VbMD25/XSK4E8=;
 b=Jztxt8PhcyvKwjpW2x7GxAqcM0Y5UxoLrt7ySghXScqL8VYGr4htosk7yZLSWZU/61JkjLdj1
 Oz50foA8PhqAutsLos5oDBzuKgar6YQVPy5fg1ecUq3lKrbr/rAyZ6v
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
Changes in v4:
- Check the first allocation in the selftest and remove the incorrect
  offset-zero NULL comment. Patch 1 is unchanged.
- Link to v3: https://lore.kernel.org/r/20261122-b4-03-bpf-arena-vmalloc-oob-v3-da2dc21683c6-v3-0-1f94ae9a884a@pm.me

To: Alexei Starovoitov <ast@kernel.org>
To: Daniel Borkmann <daniel@iogearbox.net>
To: Andrii Nakryiko <andrii@kernel.org>
To: Eduard Zingerman <eddyz87@gmail.com>
To: Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: Martin KaFai Lau <martin.lau@linux.dev>
Cc: Song Liu <song@kernel.org>
Cc: Yonghong Song <yonghong.song@linux.dev>
Cc: Jiri Olsa <jolsa@kernel.org>
Cc: Emil Tsalapatis <emil@etsalapatis.com>
Cc: Ihor Solodrai <ihor.solodrai@linux.dev>
Cc: bpf@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
YanXin Li (2):
      bpf: bound arena allocations to the user VMA
      selftests/bpf: test arena allocation after a short mmap

 kernel/bpf/arena.c                                 | 25 ++++++++++
 .../testing/selftests/bpf/prog_tests/arena_mmap.c  | 53 ++++++++++++++++++++++
 .../testing/selftests/bpf/progs/arena_mmap_alloc.c | 33 ++++++++++++++
 3 files changed, 111 insertions(+)
---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-f2eb9eff6db8

Best regards,
--  
YanXin Li <fadouse@pm.me>

