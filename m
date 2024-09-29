From: Eric Long <i@hack3r.moe>
Subject: [PATCH bpf-next v2 0/2] BPF static linker: fix failure when
 encountering duplicate extern functions
Date: Sun, 29 Sep 2024 17:31:13 +0800
Message-Id: <20240929-libbpf-dup-extern-funcs-v2-0-0cc81de3f79f@hack3r.moe>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGEe+WYC/4WNQQ6CMBBFr0Jm7Rg6ggor72FYUDqVidqSFgiGc
 HcrF3D58v9/f4XIQThCna0QeJYo3iWgQwZd37oHo5jEQDkVeUUVvkTrwaKZBuRl5ODQTq6LeL0
 oW+jWkCKCtB4CW1l28x1+C5fq0KSklzj68NkvZ7Xnf+2zwhyNVaXV5lxSqW992z1P4fj2DM22b
 V9G6MjTyQAAAA==
X-Change-ID: 20240929-libbpf-dup-extern-funcs-871f4bad2122
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1485; i=i@hack3r.moe;
 h=from:subject:message-id; bh=1QtNEJ0qw4oxe75cbYLASOSc6BQCu8RhthtnE0JuaMY=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGk/5VK0KvnlzI51P/H58F1/7ZFpV/9n54i6XN3ofbtCM
 OHs8e47HaUsDGJcDLJiiixbDv9RS9Dv3rSEe045zBxWJpAhDFycAjCRrl8M/zTP3o4yvbR+8ac3
 /CtOn3/lVNWcudR2E2vNwXPs/z0YBaMYGRZZzzLV3bX+ljeTmJB6XoGE5AqdxMfsCXlC+QrVvCq
 v2QA=
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
Changes in v2:
- Fix compile errors. Oops!
- Link to v1: https://lore.kernel.org/r/20240929-libbpf-dup-extern-funcs-v1-0-df15fbd6525b@hack3r.moe

---
Eric Long (2):
      libbpf: do not resolve size on duplicate FUNCs
      selftests/bpf: make sure linking objects with duplicate extern functions doesn't fail

 tools/lib/bpf/linker.c                             | 23 ++++++++++++----------
 tools/testing/selftests/bpf/Makefile               |  3 ++-
 .../selftests/bpf/prog_tests/dup_extern_funcs.c    |  9 +++++++++
 .../selftests/bpf/progs/dup_extern_funcs1.c        | 20 +++++++++++++++++++
 .../selftests/bpf/progs/dup_extern_funcs2.c        | 18 +++++++++++++++++
 5 files changed, 62 insertions(+), 11 deletions(-)
---
base-commit: 93eeaab4563cc7fc0309bc1c4d301139762bbd60
change-id: 20240929-libbpf-dup-extern-funcs-871f4bad2122

Best regards,
-- 
Eric Long <i@hack3r.moe>

