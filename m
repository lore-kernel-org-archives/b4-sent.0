From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH mptcp-net v2 0/2] mptcp: fix leftover fallback after failed
 connect
Date: Fri, 11 Sep 2026 23:42:06 +0800
Message-Id: <20260911-mptcp-connect-undo-net-v2-0-54224cea2238@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOzQ6CMBCEX4Xs2TVtbfDn5HsYDqUsUhO2TVuIx
 vDuFngAj5OZb2a+kCg6SnCrvhBpdsl5LkIdKrCD4Seh64oGJVQtrlLgGLINaD0z2YwTdx6ZMrY
 XQVIbkr1RUOAQqXfvrfgBO1Ni0OxWmtpXwdfiNTy4lH38bCdmuSH/9maJArWuSZuyeqLzPUSfP
 R9HgmZZlh8CtEmx2QAAAA==
X-Change-ID: 20260910-mptcp-connect-undo-net-b80e14ae1fa2
To: mptcp@lists.linux.dev
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789141332; l=1398;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=UaSkOzfR/aYP/kzb/C1pqEvi8lsHEKH84b3uUs8YwZA=;
 b=jaGVp2UDWKpbsFq7CSDshgi3GD3Dy4R6pJ6nwaiZZ4UNFdQG3/onduUSpYDwvr8VX1emRg9Ti
 SsE8/febCA8B0q6Bm1gBH9ORzjB/hHUHIEQlTLUEZYAK4xIg81r9Cxk
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When mptcp_connect() fails before the socket reaches SS_CONNECTING,
->disconnect() is not called. Early fallback may already have set
MPTCP_FALLBACK_DONE and cleared request_mptcp, so a later connect()
on the same fd stays TCP-only.

Patch 1 undoes that state on the connect error path.
Patch 2 adds a mptcp_join.sh coverage for the same-fd retry.

Closes: https://github.com/multipath-tcp/mptcp_net-next/issues/633
---
Changes in v2:
- remove the helper function and open code the function
- also drop the NULL check on the ssk; __mptcp_nmpc_sk() already
  guarantees it
- Link to v1: https://patch.msgid.link/20260910-mptcp-connect-undo-net-v1-0-446e4a4ae3e7@proton.me

---
Quanye Yang (2):
      mptcp: reset msk state on early connect failure
      selftests: mptcp: join: retry connect after early fallback

 net/mptcp/protocol.c                               |   9 +-
 tools/testing/selftests/net/mptcp/.gitignore       |   1 +
 tools/testing/selftests/net/mptcp/Makefile         |   1 +
 .../selftests/net/mptcp/mptcp_connect_retry.c      | 216 +++++++++++++++++++++
 tools/testing/selftests/net/mptcp/mptcp_join.sh    | 108 +++++++++++
 5 files changed, 334 insertions(+), 1 deletion(-)
---
base-commit: 38b6be101006d3e7af972999f45d4f1e8250587a
change-id: 20260910-mptcp-connect-undo-net-b80e14ae1fa2

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

