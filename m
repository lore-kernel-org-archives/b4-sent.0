From: Dmitry Safonov <dima@arista.com>
Subject: [PATCH net-next v2 0/2] tcp: Destroy TCP-AO, TCP-MD5 keys in
 .sk_destruct()
Date: Thu, 28 Aug 2025 09:14:54 +0100
Message-Id: <20250828-b4-tcp-ao-md5-rst-finwait2-v2-0-653099bea5c1@arista.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP4PsGgC/42OywrCMBBFf0Vm7Wg7NhJc+R/SRR5TO4smkoSqS
 P/dtODe5eVwDvcDmZNwhsvuA4lnyRJDHbTfgRtNuDOKrxuoIdVoIrQdFvdAE3HyClMuOEh4Gim
 EfD6R7bwelPZQA4/Eg7y2+A0CFwz8KtBXYk1mtMkEN67xHztORsJqjpJLTO/t1dxu/j8H5hYbJ
 KVJ+UYr7+zVpFoyBxcn6Jdl+QIgS8R77wAAAA==
X-Change-ID: 20250822-b4-tcp-ao-md5-rst-finwait2-e632b4d8f58d
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: Bob Gilligan <gilligan@arista.com>, 
 Salam Noureddine <noureddine@arista.com>, 
 Dmitry Safonov <0x7f454c46@gmail.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <dima@arista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756368907; l=1439;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=g2lTC5uR3MixSy5OjRk19PLAva0CsX5zTwQHzepZbuo=;
 b=VHzkVgPWkQAsGqXS0y+DD9MzNSRlIzE0DydTew6QZyFJtvhFDmrHzXWjU1CR6rNpvo2QwEIS7
 q21CXRCAIf+BxwWt7tX5OrnjvOuwLoG6XwygthuEvAywQQUoKKhdVWN
X-Developer-Key: i=dima@arista.com; a=ed25519;
 pk=/z94x2T59rICwjRqYvDsBe0MkpbkkdYrSW2J1G2gIcU=
X-Endpoint-Received: by B4 Relay for dima@arista.com/20250521 with auth_id=405
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On one side a minor/cosmetic issue, especially nowadays when
TCP-AO/TCP-MD5 signature verification failures aren't logged to dmesg.

Yet, I think worth addressing for two reasons:
- unsigned RST gets ignored by the peer and the connection is alive for
  longer (keep-alive interval)
- netstat counters increase and trace events report that trusted BGP peer
  is sending unsigned/incorrectly signed segments, which can ring alarm
  on monitoring.

Signed-off-by: Dmitry Safonov <dima@arista.com>
---
Changes in v2:
- Fixed TCP-MD5 ifdeffery (Reported-by: Victor Nogueira)
- Call proper destructor for inet_ipv6 (Reported-by: syzbot@syzkaller.appspotmail.com)
- Link to v1: https://lore.kernel.org/r/20250822-b4-tcp-ao-md5-rst-finwait2-v1-0-25825d085dcb@arista.com

---
Dmitry Safonov (2):
      tcp: Destroy TCP-AO, TCP-MD5 keys in .sk_destruct()
      tcp: Free TCP-AO/TCP-MD5 info/keys without RCU

 include/net/tcp.h        |  4 ++++
 net/ipv4/tcp.c           | 16 ++++++++++++++++
 net/ipv4/tcp_ao.c        |  5 ++---
 net/ipv4/tcp_ipv4.c      | 37 ++++++++++---------------------------
 net/ipv4/tcp_minisocks.c | 19 +++++--------------
 net/ipv6/tcp_ipv6.c      |  8 ++++++++
 6 files changed, 45 insertions(+), 44 deletions(-)
---
base-commit: d4854be4ec21dad23907c0fbc3389c3a394ebf67
change-id: 20250822-b4-tcp-ao-md5-rst-finwait2-e632b4d8f58d

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

