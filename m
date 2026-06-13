From: Laika Price <laikabcprice@gmail.com>
Subject: [PATCH net v2 0/2] ip_tunnel: fix PMTU ICMP reply routing
Date: Sat, 13 Jun 2026 16:12:16 +0100
Message-Id: <20260613-master-v2-0-061b70fd45dd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNwQ7CIBAFf6XZsxhAQ8WT/2F6oLBt19jSABJN0
 3+X1qPHSebNWyBiIIxwrRYImCmSnwrIQwV2MFOPjFxhkFwqrsSJjSYmDMxIrYVSreZKQ5HngB2
 999C9+XF8tQ+0aVtvxkAx+fDZn7LYvL9oFkww19Va4QWlq8+3fjT0PFo/QrOu6xcFn+wNrgAAA
 A==
X-Change-ID: 20260613-master-a299166b9069
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Laika Price <laikabcprice@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781363541; l=1026;
 i=laikabcprice@gmail.com; s=20260613; h=from:subject:message-id;
 bh=LedJ39BQchjQxS/5EHaqWA5pNnfquMEPobE2MJNmYB8=;
 b=LVcIebVR00z6R4p8iujA6Ffn7Eyt9ylqp9uAu6KtwdUZavaUnhQxaCVR4kJGoDUKbhmLrnTv+
 43OXDxvCGDAASkchl1qKY6PDPxosYWIA5BCkh6ry/qhLr/9k6Qom3Qj
X-Developer-Key: i=laikabcprice@gmail.com; a=ed25519;
 pk=mFSMw2odvyxt1H4QHAdwZVuwHduNzUMDKbWFOcwhDCg=
X-Endpoint-Received: by B4 Relay for laikabcprice@gmail.com/20260613 with auth_id=819
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>



---
Changes in v2:
- Fix incorrect PMTU exceptions test
- Link to v1: https://patch.msgid.link/20260613-master-v1-1-df796e8e2d74@gmail.com

To: David Ahern <dsahern@kernel.org>
To: Ido Schimmel <idosch@nvidia.com>
To: "David S. Miller" <davem@davemloft.net>
To: Eric Dumazet <edumazet@google.com>
To: Jakub Kicinski <kuba@kernel.org>
To: Paolo Abeni <pabeni@redhat.com>
To: Simon Horman <horms@kernel.org>
To: Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-kselftest@vger.kernel.org

---
Laika Price (2):
      [net] ip_tunnel: drop stale dst from generated PMTU ICMP replies
      [net] selftests: pmtu: fix incorrect PMTU exception generation

 net/ipv4/ip_tunnel_core.c           | 2 ++
 tools/testing/selftests/net/pmtu.sh | 4 ++--
 2 files changed, 4 insertions(+), 2 deletions(-)
---
base-commit: 2a2974b5145cdf2f4db134be1a2157e9ca4a1cf0
change-id: 20260613-master-a299166b9069

Best regards,
--  
Laika Price <laikabcprice@gmail.com>

