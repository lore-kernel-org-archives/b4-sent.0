From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH net 0/2] nfc: llcp: clone LSM attributes; st21nfca: fix skb
 leak
Date: Thu, 12 Nov 2026 10:04:47 +0000
Message-Id: <20261112-nfc-v1-0-ab0ef166f382@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD+P9WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Mj3by0ZF0TAyMTY5PkNNM0c0sloMqCotS0zAqwKdFKeaklSrEQweL
 SpKzU5BKQfqXaWgCGgPcdbAAAAA==
X-Change-ID: 20261112-nfc-402434cf5f79
To: netdev@vger.kernel.org, david@ixit.cz
Cc: edumazet@kernel.org, kuba@kernel.org, horms@kernel.org, 
 oe-linux-nfc@lists.linux.dev, linux-kernel@vger.kernel.org, 
 pabeni@redhat.com, davem@davemloft.net
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794477891; l=1045;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=B38C6ONQmhZ5MxbMTghSPgEXPV1HxFO4pL6qucWz2bg=;
 b=g5PE+Tt1to59OrPXU0EY0UM620cssI/6vUBUL6uWiUgm6jHzBvfJZhO7JsqNS+vpp3fLXE11t
 wnt7fL8T3E/ANAZMy4wnSNuSe6su9GbtCG5arKSjOtM+s7pDaIJRhbp
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Two unrelated NFC fixes. Both came out of a static analysis run, and I
checked them by hand on next-20261109.

The first one makes LLCP accepted sockets inherit the listener's LSM
attributes. nfc_llcp_recv_connect() never calls security_sk_clone(),
which bluetooth, iucv and vsock all had to add for the same reason.

The second one plugs an skb leak in st21nfca: the ATR_REQ skb is never
freed after the HCI layer has copied it.

Both are compile tested only. I don't have ST21NFCA hardware, and I
haven't set up SELinux with an LLCP peer to test the first one.

Thanks,
Suyuan

---
Suyuan Wang (2):
      nfc: llcp: Clone LSM attributes to newly created child sockets
      nfc: st21nfca: Free the ATR_REQ skb after sending it

 drivers/nfc/st21nfca/dep.c | 9 ++++++---
 net/nfc/llcp_core.c        | 3 +++
 2 files changed, 9 insertions(+), 3 deletions(-)
---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261112-nfc-402434cf5f79

Best regards,
--  
Suyuan Wang <shyckless@gmail.com>

