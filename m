From: Eric Long <i@hack3r.moe>
Subject: [PATCH bpf-next v4 0/2] BPF static linker: fix linking duplicate
 extern functions
Date: Wed, 02 Oct 2024 14:25:05 +0800
Message-Id: <20241002-libbpf-dup-extern-funcs-v4-0-560eb460ff90@hack3r.moe>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEHn/GYC/43NQQ7CIBAF0KsY1mJgoGJdeQ/josCMJSptQBuN6
 d3FLkyMMbr8+fPf3FnGFDCz9ezOEg4hhy6WoOcz5tom7pEHXzIDAVrUUPNjsLYn7i89x+sZU+R
 0iS7zlZGkbeNBArCy7hNSuE7ylj0XsZyzXWnakM9duk0vBzn1P/VBcsE9yYqsX1ZQ2U3buINKi
 1OHEzrAnxAUSDi3kh4VmZo+IPWCpBDyO6QKpIGMMRrJknqDxnF8ADW1V1RbAQAA
X-Change-ID: 20240929-libbpf-dup-extern-funcs-871f4bad2122
To: bpf@vger.kernel.org
Cc: Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, netdev@vger.kernel.org, 
 Eric Long <i@hack3r.moe>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1687; i=i@hack3r.moe;
 h=from:subject:message-id; bh=lfSqdrDVW8IPHNi3F/V0jAnpEIiI+8S0zzzKbOuVd+Y=;
 b=owGbwMvMwCUWYb/agfVY0D7G02pJDGl/nrsE2N553W9zIStZe/L8KbO1w2rOWy5sWbFw5pmX/
 EkGDk9OdJSyMIhxMciKKbJsOfxHLUG/e9MS7jnlMHNYmUCGMHBxCsBEpvgxMrx8v1Z6n10he+fc
 RRP+i7LIH/xxc9q3L3MiI0tYixrqud8zMvwTj/4tE/+w6lu99ffPGalHrl58c1jov4mUa7brN03
 Jdn4A
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
Changes in v4:
- Remove redundant FUNC_PROTO check.
- Merge tests into linked_funcs.
- Link to v3: https://lore.kernel.org/r/20241001-libbpf-dup-extern-funcs-v3-0-42f7774efbf3@hack3r.moe

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

 tools/lib/bpf/linker.c                            | 4 ++++
 tools/testing/selftests/bpf/progs/linked_funcs1.c | 8 ++++++++
 tools/testing/selftests/bpf/progs/linked_funcs2.c | 8 ++++++++
 3 files changed, 20 insertions(+)
---
base-commit: 93eeaab4563cc7fc0309bc1c4d301139762bbd60
change-id: 20240929-libbpf-dup-extern-funcs-871f4bad2122

Best regards,
-- 
Eric Long <i@hack3r.moe>

