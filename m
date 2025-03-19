From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net-next v2 0/7] selftests/net: Mixed select()+polling mode
 for TCP-AO tests
Date: Wed, 19 Mar 2025 03:13:33 +0000
Message-Id: <20250319-tcp-ao-selftests-polling-v2-0-da48040153d1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF422mcC/4WOwQqDMBBEf6XsuduatNHSU/+jeEjiqgFNJBvEI
 v57o9Bzj8Pw3swKTNERw/O0QqTZsQs+B3k+ge217whdkzPIQqriJiQmO6EOyDS0iTgxTmEYnO9
 QClMa07RVZUrI+BSpdcuhfoOnhJ6WBHVujGZCE7W3/a7+dddRO7+TveMU4uf4NIuD/z8/Cyywk
 rq8S/NQqlGvLvuGiw0j1Nu2fQHilFlT6gAAAA==
X-Change-ID: 20250312-tcp-ao-selftests-polling-21b6bbdf77b6
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>, Dmitry Safonov <0x7f454c46@gmail.com>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742354050; l=2211;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=etgJBoDA0+o3M60VBpSmAHMAVpuV7zSfirQ+bKuKABs=;
 b=1I9QpOTeJb1TkomhompoA8/N2Kaaw0gS1HWvq/lyucF63bZKRXvykgBMV9jCQd8aKS3oHZ38P
 toxxWCRZjYFAuJeLISBiXQjnqtzQ7QJ2dXVJrCMpAOnNX2QeqvnxTSm
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Should fix flaky tcp-ao/connect-deny-ipv6 test.
Begging pardon for the delay since the report and for sending it this
late in the release cycle.

To: David S. Miller <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Simon Horman <horms@kernel.org>
To: Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org
Cc: linux-kselftest@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>

Changes in v2:
- Base on net-next (Paolo)
- Add a missing Fixes tag (Paolo)
- Link to v1: https://lore.kernel.org/r/20250312-tcp-ao-selftests-polling-v1-0-72a642b855d5@gmail.com

---
Dmitry Safonov (7):
      selftests/net: Print TCP flags in more common format
      selftests/net: Provide tcp-ao counters comparison helper
      selftests/net: Fetch and check TCP-MD5 counters
      selftests/net: Add mixed select()+polling mode to TCP-AO tests
      selftests/net: Print the testing side in unsigned-md5
      selftests/net: Delete timeout from test_connect_socket()
      selftests/net: Drop timeout argument from test_client_verify()

 tools/testing/selftests/net/tcp_ao/connect-deny.c  |  58 ++--
 tools/testing/selftests/net/tcp_ao/connect.c       |  22 +-
 tools/testing/selftests/net/tcp_ao/icmps-discard.c |  17 +-
 .../testing/selftests/net/tcp_ao/key-management.c  |  76 ++---
 tools/testing/selftests/net/tcp_ao/lib/aolib.h     | 114 ++++++--
 .../testing/selftests/net/tcp_ao/lib/ftrace-tcp.c  |   7 +-
 tools/testing/selftests/net/tcp_ao/lib/sock.c      | 315 +++++++++++++++------
 tools/testing/selftests/net/tcp_ao/restore.c       |  75 +++--
 tools/testing/selftests/net/tcp_ao/rst.c           |  47 ++-
 tools/testing/selftests/net/tcp_ao/self-connect.c  |  18 +-
 tools/testing/selftests/net/tcp_ao/seq-ext.c       |  30 +-
 tools/testing/selftests/net/tcp_ao/unsigned-md5.c  | 118 ++++----
 12 files changed, 552 insertions(+), 345 deletions(-)
---
base-commit: 23c9ff659140f97d44bf6fb59f89526a168f2b86
change-id: 20250312-tcp-ao-selftests-polling-21b6bbdf77b6

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

