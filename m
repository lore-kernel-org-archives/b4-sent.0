From: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
Subject: [PATCH net v2 0/2] netlink: fix a dump livelock with a
 notification queued
Date: Tue, 27 Oct 2026 15:04:00 +0100
Message-Id: <20261027-netlink-dump-livelock-v2-0-c4bb05352a33@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFCv4GoC/4WNQQ6CMBREr0L+2hraIqAr72FY1PKBL6UlFBoN4
 e4WPIDLmbx5s4LHidDDLVlhwkCenI1BnBLQnbItMqpjBpGKnKdCMouzIduzehlGZiigcbpnWEr
 dcNlci0JB3I4TNvQ+vA+IE6h+pV+eL9Tzbtyxjvzsps/xHvgB/zkKnKUsK0rBM5XLSy3u7aDIn
 LUboNq27QtWzWty0QAAAA==
X-Change-ID: 20261023-netlink-dump-livelock-e83cf13f977a
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Kuniyuki Iwashima <kuniyu@google.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Jhonata Poma-Hansen <jhonata.poma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2041;
 i=jhonata.poma@gmail.com; h=from:subject:message-id;
 bh=dyqos+YZiGmpIof18fo47Wd6gwZ5wp6SPtEj3CzE5a0=;
 b=owGbwMvMwCX21S6Y7aK9oS7jabUkhqwH64PYTj4Le+I0Kzus1qYz6/xRntUi/1eUnck3+yGeq
 pBYYlzUUcrCIMbFICumyOJz9nEPt+LHHf8f7rgMM4eVCWQIAxenAEzk/BpGhklR7/M+J/vouVrp
 1YQUd2zg///CziE568YvZ8mkuZ7Vdgz/1EIv7hCNzhM7semvuN+rf4t2hCcuULxU9MbJvWJ2Za4
 eLwA=
X-Developer-Key: i=jhonata.poma@gmail.com; a=openpgp;
 fpr=4CCDE38C0B21F1B8FFE1B8D3F53E5306D13F312D
X-Endpoint-Received: by B4 Relay for jhonata.poma@gmail.com/default with auth_id=1288
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A netlink dump that starts while a notification is still charged to a
socket with a small receive buffer fails with ENOBUFS, and every retry
from recvmsg() fails the same way. A reader that peeks before reading,
as libnl does, never consumes the message at the head of the queue and
spins forever. I hit this with "iw dev wlan0 scan" on an arm64 board.

Patch 1 goes back to checking sk_rcvbuf before charging the dump skb,
as before commit ae8f160e7eb2. Patch 2 adds a selftest; it fails
without patch 1 and is skipped without the privileges to create a
netns.

---
Changes in v2:
- Patch 1: check sk_rcvbuf before charging instead of retrying with
  the minimum skb size, which could still be rejected (Sashiko), and
  refuse a skb that would take sk_rmem_alloc past INT_MAX.
- Patch 1: say how the bug was found and how the fix was tested.
- Patch 2: use SO_RCVBUF 2048, which also fails with v1, check the
  NLMSG_DONE status and that a link was dumped, and skip without
  privileges (Sashiko).
- Link to v1: https://patch.msgid.link/20261023-netlink-dump-livelock-v1-0-478214a635d2@gmail.com

To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@kernel.org>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Simon Horman <horms@kernel.org>
To: Kuniyuki Iwashima <kuniyu@google.com>
To: Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-kselftest@vger.kernel.org

---
Jhonata Poma-Hansen (2):
      netlink: check sk_rcvbuf before charging the dump skb
      selftests: net: netlink-dumps: start a dump with a notification queued

 net/netlink/af_netlink.c                    |   6 +-
 tools/testing/selftests/net/netlink-dumps.c | 102 ++++++++++++++++++++++++++++
 2 files changed, 107 insertions(+), 1 deletion(-)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-netlink-dump-livelock-e83cf13f977a

Best regards,
--  
Jhonata Poma-Hansen <jhonata.poma@gmail.com>

