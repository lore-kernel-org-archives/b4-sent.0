From: Bochao Cao <bochaolucky@gmail.com>
Subject: [PATCH net-next v6 0/5] selftests: Fix and migrate the XDP feature
 test
Date: Sun, 18 Oct 2026 22:05:49 +0800
Message-Id: <20261018-xdp-v5-send-20261008-v6-0-7336e1282ca3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OQQ6CMBBFr0JmbU0LUogr72FY0HaEGimkrQRDu
 LttUVcu//t/XmYFh1ajg3O2gsVZOz2aEPghA9m3pkOiVciQ05wzSmuyqInMJXFoFPnBgjJFkam
 C8RLC6WTxppekvYJBTwwuHpq9cU9xR+mjNW5F65AI2xrZR/TxJ/r1x1mvnR/tKz06l0m814z+/
 ykAShTyupKCV/JEL93Q6sdRjgM027a9AaS+voX7AAAA
X-Change-ID: 20261008-xdp-v5-send-20261008-301d0e1d3165
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, Shuah Khan <shuah@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, netdev@vger.kernel.org, 
 =?utf-8?q?Alexis_Lothor=C3=A9?= <alexis.lothore@bootlin.com>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Tiezhu Yang <tiozhang@didiglobal.com>, Bochao Cao <bochaolucky@gmail.com>, 
 Willem de Bruijn <willemdebruijn.kernel@gmail.com>, 
 Petr Machata <petrm@nvidia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792332371; l=3816;
 i=bochaolucky@gmail.com; s=default; h=from:subject:message-id;
 bh=6zfVRO0wUkIX0trYTHFUHGIOQjYjRYp9mcAVET69qKc=;
 b=VEZVqT1rfhQPPNsBAbSVqpiKSeZrkvkyD1+KxVRRNWTFS1XQO0FbQcuRXdSv9d9pCTjp42CIt
 PI7f8E3W/obD9ZLY5jEh0U5lkf8I0n4JEtsgRglpEvVNSyz1Vu9x2fU
X-Developer-Key: i=bochaolucky@gmail.com; a=ed25519;
 pk=ZYp7O2eXSIrJ9YmKrl0iHDoulPYSG+1lzICsicAvld0=
X-Endpoint-Received: by B4 Relay for bochaolucky@gmail.com/default with auth_id=1042
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes the XDP feature test and moves it to drivers/net/hw.
The tester uses AF_PACKET, so the remote host does not need native XDP.
Existing remote XDP programs and offload settings are left unchanged.

Changes since v5:
- Fix control EOF handling and preserve existing XDP programs on attach
  failure in the initial cleanup patch.
- Bound shell readiness, fix signal cleanup and namespace ownership,
  isolate tracepoint counters, and fail on capability mismatches.
- Support a separate control network, use an atomic signal flag, return
  failure on interruption, and query capabilities after attachment.
- Fix inherited source paths, host-tool selection and installed-header
  priority in the shared BPF build rules.
- Use argv lists for local commands and SSH deployment. Remove the old
  ignore entry and fix the README heading.
- Run veth XDP_TX when peer GRO is enabled without native XDP. Skip only
  when the peer has neither. This covers the case addressed by [1].

Tested on x86_64 Ubuntu with Linux 6.8.0-124-generic:
- Normal and separate-output builds, relative inherited srctree, host
  bootstrap with target CC/LD disabled, and conflicting source headers.
- Earlier baseline across three veth configurations: 17 PASS and
  1 expected XDP_TX SKIP.
- All six features with separate IPv4 and IPv6 control networks: 12 PASS.
- Nine error/cleanup checks, six protocol/isolation checks, and DUT/tester
  attach-failure preservation checks passed.
- Patch 2: two concurrent six-case runs and three repeated-TERM runs
  left no helper processes or namespaces.
- SSH deployment and execution from a path containing spaces and a quote.
- GRO-only XDP_TX: isolated veth modules with and without the one-line
  fix reproduce failure and success for both IPv4 and IPv6. The runner
  also passes the expected skip/failure/success checks with ethtool 5.16.
- GCC -fanalyzer reported no diagnostics. Clang diagnostics were checked;
  the unused assignment was removed and model false positives documented.

Tests used veth devices; physical-NIC testing remains unverified.

[1] https://lists.openwall.net/netdev/2026/10/16/565

Previous version:
https://lore.kernel.org/all/20261010-xdp-v5-send-20261008-v5-0-de687cb67c40@gmail.com/

Signed-off-by: Bochao Cao <bochaolucky@gmail.com>

---
Bochao Cao (5):
      selftests/bpf: Fix XDP feature test setup and teardown
      selftests/bpf: Track XDP test processes and isolate namespaces
      selftests/bpf: Send XDP feature probes with AF_PACKET
      selftests/net: Add a shared BPF skeleton rule
      selftests/net: Move the XDP feature test to drivers/net/hw

 tools/testing/selftests/bpf/.gitignore             |    1 -
 tools/testing/selftests/bpf/Makefile               |   11 +-
 tools/testing/selftests/bpf/test_xdp_features.sh   |  107 --
 tools/testing/selftests/bpf/xdp_features.c         |  719 --------------
 tools/testing/selftests/drivers/net/README.rst     |   19 +
 tools/testing/selftests/drivers/net/hw/.gitignore  |    3 +
 tools/testing/selftests/drivers/net/hw/Makefile    |   15 +-
 tools/testing/selftests/drivers/net/hw/config      |    3 +
 .../net/hw/xdp_features.bpf.c}                     |   60 +-
 .../selftests/drivers/net/hw/xdp_features.c        | 1023 ++++++++++++++++++++
 .../{bpf => drivers/net/hw}/xdp_features.h         |    1 +
 .../selftests/drivers/net/hw/xdp_features.py       |  146 +++
 .../selftests/drivers/net/lib/py/remote_ssh.py     |    2 +-
 tools/testing/selftests/net/bpf.mk                 |   33 +-
 14 files changed, 1266 insertions(+), 877 deletions(-)
---
base-commit: 8df0638138d3e0344fd1fb36cf2d1ca1cf5028f0
change-id: 20261008-xdp-v5-send-20261008-301d0e1d3165

Best regards,
--  
Bochao Cao <bochaolucky@gmail.com>

