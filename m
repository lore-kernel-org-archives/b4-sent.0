From: Eli Skeggs <kernel@eliskeggs.com>
Subject: [PATCH bpf 0/2] bpf, sockmap: Fix dropped data and EPIPE on empty
 skb redirect
Date: Sun, 25 Oct 2026 16:41:56 -0700
Message-Id: <20261025-sockmap-bare-fin-v1-0-bb8feae7c4a7@eliskeggs.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6W8swtJhCr+inhI1o2uYhqyVYTSf
 zfqcQZmFpg0FcNhWNDkpaZT6eA3A/gay0VIz50RXBi9C45s4vsjVkqxCWUtJD7v/eh4y7uEntU
 mWd+/5RGpZpz+0p7pJjx/Z1jXDweIJxJ5AAAA
X-Change-ID: 20261020-sockmap-bare-fin-e1f8160c3c7b
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Cong Wang <cong.wang@bytedance.com>, 
 Daniel Borkmann <daniel@iogearbox.net>, Alexei Starovoitov <ast@kernel.org>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>
Cc: Geliang Tang <geliang@kernel.org>, netdev@vger.kernel.org, 
 bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Eli Skeggs <kernel@eliskeggs.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792971941; l=1845;
 i=kernel@eliskeggs.com; s=20261021; h=from:subject:message-id;
 bh=Wlyiie0CKDzxYgDQSpvxa4sS+tMNMfU2M/Qk54ENhjw=;
 b=tbyYi/j3qg52YiRw/uGwHTvdc1MwNPTaY4YyjbYq3J6a31YmybW5d/zOUFmKzo8P67EOjxD7h
 kZuWm2tJq1YBrVWeIvDgbj0Jp5hebWFSYVm5EGihK9IZk/NKBTSYo5y
X-Developer-Key: i=kernel@eliskeggs.com; a=ed25519;
 pk=38k+FqQ3STTnr2H4HZ7IEseBOHWRDYVhvyMmQlB51gc=
X-Endpoint-Received: by B4 Relay for kernel@eliskeggs.com/20261021 with auth_id=1252
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a socket receives a bare FIN, tcp_read_skb() hands an empty skb to
the attached BPF stream_verdict program. The program may redirect that
skb to another socket. Doing so causes the target socket to report EPIPE
and stop transmitting redirected data. A proxy may see the erroneous
EPIPE and truncate a half-closed connection. Instead of treating a
redirected empty skb as an error, treat a 0 return as an error only when
there is more data to send.

Patch 2 adds a selftest that fails without patch 1.

Tested on x86_64 with virtme-ng, under QEMU without KVM. The new subtest
fails on bpf/master without patch 1, and passes with it. The full
test_progs -t sockmap passes all seven tests and 802 subtests with patch
1.

The bug dates from v6.0 (965b57b469a5), so please consider queueing
patch 1 for stable.

Found while building a sockmap proxy between TCP and MPTCP sockets,
running out-of-tree MPTCP sockmap patches, where the EPIPE caused
half-closed connections to prematurely abort. An LLM helped locate and
reproduce the issue, and proposed an initial fix. I traced the code
path, reviewed and verified the LLM-written test, and simplified its
proposal to a one-line fix.

Signed-off-by: Eli Skeggs <kernel@eliskeggs.com>
---
Eli Skeggs (2):
      bpf, sockmap: Stop reporting EPIPE on zero-length skb redirect
      selftests/bpf: Redirect a bare FIN to another socket's egress

 net/core/skmsg.c                                   |  2 +-
 .../selftests/bpf/prog_tests/sockmap_basic.c       | 74 ++++++++++++++++++++++
 .../selftests/bpf/progs/test_sockmap_pass_prog.c   |  8 +++
 3 files changed, 83 insertions(+), 1 deletion(-)
---
base-commit: f909e534f5e34feb2ea2701d54df63e21aa506fc
change-id: 20261020-sockmap-bare-fin-e1f8160c3c7b

Best regards,
--  
Eli Skeggs <kernel@eliskeggs.com>

