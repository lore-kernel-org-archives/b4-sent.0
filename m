From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH mptcp-net 0/2] mptcp: fix leftover fallback after failed
 connect
Date: Thu, 10 Sep 2026 20:23:32 +0800
Message-Id: <20260910-mptcp-connect-undo-net-v1-0-446e4a4ae3e7@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kASpNRepXQR41in0ElIogji3
 R3r8vH/exsUykwFns0GmRYuHEXB3hoIk5cPIQ/K4Iy7m84a/KUaEoYoQqHiLENEoYr9w5BtPdn
 RO1A5ZRp5/YdfcDl6g/c1lbn/qn6GYd8PpsnRxYUAAAA=
X-Change-ID: 20260910-mptcp-connect-undo-net-b80e14ae1fa2
To: mptcp@lists.linux.dev
Cc: 
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789043021; l=1137;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=hyqw+vpPYqG3dvXwyA2jHKTeyV8RlLXzxWlPosmWqrA=;
 b=0UKogYq/G5bI0jp0JFBukiF0izbXipJ/qAixj+oy7bRdMbqbYWKND3lUwRe/hq5NtGBfMCsNG
 mXFZx48mwsoATBBM+x91xd5s7DxpUQHcr2IxbZkkzYGe72W6PZwRzvu
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
Quanye Yang (2):
      mptcp: reset msk state on early connect failure
      selftests: mptcp: join: retry connect after early fallback

 net/mptcp/protocol.c                               |  22 ++-
 tools/testing/selftests/net/mptcp/.gitignore       |   1 +
 tools/testing/selftests/net/mptcp/Makefile         |   1 +
 .../selftests/net/mptcp/mptcp_connect_retry.c      | 216 +++++++++++++++++++++
 tools/testing/selftests/net/mptcp/mptcp_join.sh    | 108 +++++++++++
 5 files changed, 345 insertions(+), 3 deletions(-)
---
base-commit: 38b6be101006d3e7af972999f45d4f1e8250587a
change-id: 20260910-mptcp-connect-undo-net-b80e14ae1fa2

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

