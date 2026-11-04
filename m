From: Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
Subject: [PATCH bpf-next 0/2] Limit local storage value size to max
 kmalloc_nolock() allocation
Date: Wed, 04 Nov 2026 18:37:56 +0700
Message-Id: <20261104-local-storage-max-v1-0-c836731bd184@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7bkErivpKdLBtrYXS0Agh+nvSc
 RhmHogchCMMxQOBb4niXQZdFkCbcSujLJmhUlWrtWpw92R2jJcPJsvDJKS6U72lpbUzQe7OwFb
 S/xxhPi06ThdM7/sB9RsjSm0AAAA=
X-Change-ID: 20261104-local-storage-max-c3709fcd6fbc
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 John Fastabend <john.fastabend@gmail.com>, Amery Hung <ameryhung@gmail.com>, 
 Shuah Khan <shuah@kernel.org>, Christian Brauner <brauner@kernel.org>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Amery Hung <ameryhung@gmail.com>, 
 Slava Imameev <slava.imameev@crowdstrike.com>, 
 Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793792278; l=1220;
 i=thamrinjonathan@gmail.com; s=20261102; h=from:subject:message-id;
 bh=7tD517TNGR3Xl9ZhLbA/MFMMtT5aaAkfnZnVLX73hmk=;
 b=BTjv2wvo5BWzwx918zqZt/0lRYf+OY3GGArIhxuadr66khkgWOYChCNRIt5GSWBeo9az5Vlkq
 IzS0MoJgwM/C1N4drlaatguxem7qKp38vJMK7tgaLY+YI/6rDQzFvAJ
X-Developer-Key: i=thamrinjonathan@gmail.com; a=ed25519;
 pk=mr0q5PZVaUIrv8WvTxIfK7QVcAiRSYI8hOByBQL1ZRo=
X-Endpoint-Received: by B4 Relay for thamrinjonathan@gmail.com/20261102 with auth_id=1383
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BPF local storage elements are allocated using kmalloc_nolock()
but map creation is still allowed with values up to kmalloc()'s
larger limit. BPF_LOCAL_STORAGE_MAX_VALUE_SIZE is changed to be
based on KMALLOC_MAX_CACHE_SIZE instead and maps with larger
values fail on creation with E2BIG. Cgroup storage
(BPF_MAP_TYPE_CGROUP_STORAGE) uses the previous limit since it
allocates with kmalloc().

A selftest is also added to both find the largest task storage
size and test that this value can be stored. It also checks
that the size is at least 4096 to check that the limit isn't too
low.

---
Jonathan Bastari Thamrin (2):
      bpf: Limit local storage value size to max kmalloc_nolock() allocation
      selftests/bpf: Test local storage max value size

 include/linux/bpf_local_storage.h                  | 10 +--
 kernel/bpf/local_storage.c                         | 13 +++-
 .../selftests/bpf/prog_tests/task_local_storage.c  | 87 ++++++++++++++++++++++
 3 files changed, 103 insertions(+), 7 deletions(-)
---
base-commit: d346f59069676eda84b3313cbd2c2ab21045d3ee
change-id: 20261104-local-storage-max-c3709fcd6fbc

Best regards,
-- 
Jonathan Bastari Thamrin <thamrinjonathan@gmail.com>

