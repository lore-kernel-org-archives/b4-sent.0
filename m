From: Dmitry Safonov <dima@arista.com>
Subject: [PATCH net-next 0/2] tcp: Destroy TCP-AO, TCP-MD5 keys in
 .sk_destruct()
Date: Fri, 22 Aug 2025 05:55:35 +0100
Message-Id: <20250822-b4-tcp-ao-md5-rst-finwait2-v1-0-25825d085dcb@arista.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEf4p2gC/zXMTQrCMBBA4auUWTtYx0aCVxEX+ZnYWXRaklALp
 Xc3Ci4fD74dCmfhAvduh8yrFJm1xeXUQRidvhgltgbqyfSWCP2ANSzoZpyiwVwqJtG3k0rItyv
 5IdpkbIQGLJmTbD/8AcoVlbcKz3a8K4w+Ow3jF/+/8+RE4Tg+x1DtpZYAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755838557; l=1080;
 i=dima@arista.com; s=20250521; h=from:subject:message-id;
 bh=eoIgmp6rOubH/7RKU/oUjCoxUtaCvNYc3/qZX5mbECY=;
 b=LN8PbXzzYXo4S4BAjItS0hsDu4M1iUFgtaq0ivYwRq/KQGMfYxcckMoR/8bQSr5ja/dWExc7j
 LrLWHLh1eBqD1dpwSAMoDnbBo4SBtVO76wXXTOt9AAOPu21rqKIvVrl
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
Dmitry Safonov (2):
      tcp: Destroy TCP-AO, TCP-MD5 keys in .sk_destruct()
      tcp: Free TCP-AO/TCP-MD5 info/keys without RCU

 net/ipv4/tcp.c           | 18 ++++++++++++++++++
 net/ipv4/tcp_ao.c        |  5 ++---
 net/ipv4/tcp_ipv4.c      | 29 ++---------------------------
 net/ipv4/tcp_minisocks.c | 19 +++++--------------
 4 files changed, 27 insertions(+), 44 deletions(-)
---
base-commit: a7bd72158063740212344fad5d99dcef45bc70d6
change-id: 20250822-b4-tcp-ao-md5-rst-finwait2-e632b4d8f58d

Best regards,
-- 
Dmitry Safonov <dima@arista.com>

