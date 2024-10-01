From: Eric Long <i@hack3r.moe>
Subject: [PATCH bpf-next v3 0/2] BPF static linker: fix linking duplicate
 extern functions
Date: Tue, 01 Oct 2024 11:55:20 +0800
Message-Id: <20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKhy+2YC/43NQQ6CMBAF0KuYrh3TDiDgynsYF7SdSqMW0kKDI
 dzd2p0rXf78+W9WFshbCuy0W5mnaIMdXArFfsdU37kbgdUpM+RY8hZbeFgpRwN6HoGWibwDMzs
 VoKmFKWWnUSCytB49Gbtk+cI+C5fO2TU1vQ3T4F/5ZRS5/6lHARy0EZWR+lhhJc99p+6FPzwHy
 mjEPyFMEFeqEZoKU7fmC9q27Q26m0ttEgEAAA==
X-Change-ID: 20240929-libbpf-dup-extern-funcs-871f4bad2122
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1680; i=i@hack3r.moe;
 h=from:subject:message-id; bh=uchJyHZwSePmopkBZvOxuyt0es7TztoFkb8qVxM5/M0=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGm/i9b46y1w2bPjsYmno7l69LzH6VeEOM1uRISFOx0LM
 dinJ9fdUcrCIMbFICumyLLl8B+1BP3uTUu455TDzGFlAhnCwMUpABOpC2VkmJj6P/OzyI13RUXb
 H5qrMPzkMP9eKjxVJkG5Tn7e6hWtUxgZLuubNeifkZofaBm+LWjrJHGOK4LzZh38sejMhMbXB0U
 2MAAA
X-Developer-Key: i=i@hack3r.moe; a=openpgp;
 fpr=3A7A1F5A7257780C45A9A147E1487564916D3DF5
X-Endpoint-Received: by B4 Relay for i@hack3r.moe/default with auth_id=225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, if `bpftool gen object` tries to link two objects that
contains the same extern function prototype, libbpf will try to get
their (non-existent) size by calling bpf__resolve_size like extern
variables and fail with:

	libbpf: global 'whatever': failed to resolve size of underlying type: -22

This should not be the case, and this series adds conditions to update
size only when the BTF kind is not function.

Fixes: a46349227cd8 ("libbpf: Add linker extern resolution support for functions and global variables")
Signed-off-by: Eric Long <i@hack3r.moe>
---
Changes in v3:
- Simplifiy changes and shorten subjects, according to reviews.
- Remove unused includes in selftests.
- Link to v2: https://lore.kernel.org/r/20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe

Changes in v2:
- Fix compile errors. Oops!
- Link to v1: https://lore.kernel.org/r/20240929-libbpf-dup-extern-funcs-v1-0-df15fbd6525b@hack3r.moe

---
Eric Long (2):
      libbpf: do not resolve size on duplicate FUNCs
      selftests/bpf: test linking with duplicate extern functions

 tools/lib/bpf/linker.c                                |  4 ++++
 tools/testing/selftests/bpf/Makefile                  |  3 ++-
 .../selftests/bpf/prog_tests/dup_extern_funcs.c       |  9 +++++++++
 tools/testing/selftests/bpf/progs/dup_extern_funcs1.c | 19 +++++++++++++++++++
 tools/testing/selftests/bpf/progs/dup_extern_funcs2.c | 17 +++++++++++++++++
 5 files changed, 51 insertions(+), 1 deletion(-)
---
base-commit: 93eeaab4563cc7fc0309bc1c4d301139762bbd60
change-id: 20240929-libbpf-dup-extern-funcs-871f4bad2122

Best regards,
-- 
Eric Long <i@hack3r.moe>

