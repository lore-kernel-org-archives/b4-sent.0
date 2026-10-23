From: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
Subject: [PATCH net 0/2] netlink: fix a dump livelock with a notification
 queued
Date: Fri, 23 Oct 2026 13:26:06 +0200
Message-Id: <20261023-netlink-dump-livelock-v1-0-478214a635d2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE5E22oC/yWMQQqDMBQFryJ/3Q8mgVq9SulC40v7axolUSmId
 ze2yxmY2SghChI1xUYRqyQZQwZ1Kci+2vAES5+ZdKmvqtSGA2YvYeB++UzsZYUf7cC4GeuUcXV
 VtZTbKcLJ9/e9U07o8Zdp6d6w83mkfT8A6i94qX4AAAA=
X-Change-ID: 20261023-netlink-dump-livelock-e83cf13f977a
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Kuniyuki Iwashima <kuniyu@google.com>, 
 Jhonata Poma-Hansen <jhonata.poma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1647;
 i=jhonata.poma@gmail.com; h=from:subject:message-id;
 bh=UT0ToEDk7Z7G4Gj0wKFXaMDLxsm+hOMUG0sgMAFq9eI=;
 b=owGbwMvMwCX21S6Y7aK9oS7jabUkhqzbLv5Gktuebv9ufmJaWvKHSO97p1pyn3etSgnK2jQ1Y
 9WCg4+XdJSyMIhxMciKKbL4nH3cw634ccf/hzsuw8xhZQIZwsDFKQAT2fWH4Z+WKmu2XcWpknWb
 Eq3XvjvEnnXQwMrh9Y4Fvy1NDnEcjzjHyPDr4cYzvueNNZiL78YfMqrbslzMz//xhK7Eqw1fdjL
 OOcsBAA==
X-Developer-Key: i=jhonata.poma@gmail.com; a=openpgp;
 fpr=4CCDE38C0B21F1B8FFE1B8D3F53E5306D13F312D
X-Endpoint-Received: by B4 Relay for jhonata.poma@gmail.com/default with auth_id=1288
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A netlink dump that starts while data is still charged to the reader's
socket fails with ENOBUFS when the reader's receive buffer is small,
even though a minimum size skb would fit. The dump stays marked as
running, every recvmsg() retries it, and a reader that peeks before
reading, as libnl does, spins forever.

I hit this with "iw dev wlan0 scan" on an arm64 board with a 6.6 based
kernel: iw hung at 100% CPU in 5 to 10 scans out of 15. A kprobe trace
showed the scan dump starting with the NEW_SCAN_RESULTS notification
still charged to iw's 16KiB socket, because iw had preempted the sender
before netlink_broadcast() returned.

Patch 1 retries the dump skb with the minimum size before failing.
Patch 2 adds a selftest which starts a link dump with a link
notification queued and reads it like libnl does.

Tested on net 734bef548a96 in a KVM guest: without patch 1 the new test
fails and a standalone reproducer livelocks in 3 runs out of 3; with
it, netlink-dumps passes 5 of 5 and the reproducer completes. The
existing netlink-dumps tests pass with and without the fix.

---
Jhonata Poma-Hansen (2):
      netlink: retry a dump skb that does not fit with the minimum size
      selftests: net: netlink-dumps: start a dump with a notification queued

 net/netlink/af_netlink.c                    | 11 ++++
 tools/testing/selftests/net/netlink-dumps.c | 93 +++++++++++++++++++++++++++++
 2 files changed, 104 insertions(+)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-netlink-dump-livelock-e83cf13f977a

Best regards,
--  
Jhonata Poma-Hansen <jhonata.poma@gmail.com>

