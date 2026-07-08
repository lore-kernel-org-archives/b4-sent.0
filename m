From: Mattia Meleleo <mattia.meleleo@coralogix.com>
Subject: [PATCH bpf v3 0/2] bpf, sockmap: Fix FIONREAD for sockets without
 a verdict program
Date: Wed, 08 Jul 2026 18:54:59 +0200
Message-Id: <20260708-fionread-no-verdict-v3-0-b4ee31b3af53@coralogix.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0K6dgwUpNSV9zAuynQKNUpJiw2Gc
 HcBN8YYl3/y5r2JBfKWAjsmE/MUbbCuW0a+Sxi2qmsIrF424ykvU5EKMAvgSWnoHETy2uIAqjB
 VKYVCaSRbPntPxo6b9czq3rDL+xge9ZVwWH0r1towOP/c2jHb4L+ZmEEGSLJQgucHQXhC59XNN
 Xbco7tvlcg/PdVvD4cUuNSay7zkGYpvzzzPLyVrRqkZAQAA
X-Change-ID: 20260707-fionread-no-verdict-a4f8697ac9f9
To: bpf@vger.kernel.org
Cc: netdev@vger.kernel.org, John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Mattia Meleleo <mattia.meleleo@coralogix.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783529717; l=1347;
 i=mattia.meleleo@coralogix.com; s=20260707; h=from:subject:message-id;
 bh=E597jrkyamse8scXKS+eJA6HFU7y85qrwCtLMoF2A+E=;
 b=0iyEGHE6MMl1uTga9/nSgQVDD2IvFs7va7vLyFLAhTkzB1duqMtZhZW6OGN5Axe7MNJiR1OnJ
 zsBC2BRmcNSDURwUIft6fxR3Jo0AhDyQ40dZ4TIJLHIXbVtfLgppgAF
X-Developer-Key: i=mattia.meleleo@coralogix.com; a=ed25519;
 pk=cs1zLoe3YDm4bJ7bfbPaZH0lHnd871JyJLiSh2eEzLs=
X-Endpoint-Received: by B4 Relay for mattia.meleleo@coralogix.com/20260707 with auth_id=857
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sockets added to a sockmap/sockhash with no stream/skb verdict program
attached answer FIONREAD with 0 even when unread data is pending in
sk_receive_queue. Fix tcp_bpf_ioctl() to account for the receive queue
in that case, and add a selftest.

Changes in v3:
- Remove unused sk_psock_msg_inq()
- Link to v2: https://patch.msgid.link/20260708-fionread-no-verdict-v2-0-29dd293621c7@coralogix.com

Changes in v2:
- Split the fix and the selftest into separate patches
- Use READ_ONCE() to read the verdict program pointers
- Link to v1: https://patch.msgid.link/20260707-fionread-no-verdict-v1-1-ce94a72357ec@coralogix.com

Signed-off-by: Mattia Meleleo <mattia.meleleo@coralogix.com>
---
Mattia Meleleo (2):
      bpf, sockmap: Account for receive queue in FIONREAD without a verdict program
      selftests/bpf: Test FIONREAD on a sockmap socket without a verdict program

 include/linux/skmsg.h                              | 14 --------
 net/ipv4/tcp_bpf.c                                 | 17 +++++++++-
 .../selftests/bpf/prog_tests/sockmap_basic.c       | 39 ++++++++++++++++++++++
 3 files changed, 55 insertions(+), 15 deletions(-)
---
base-commit: d2c9a99135da931377240942d44f3dea104cedb8
change-id: 20260707-fionread-no-verdict-a4f8697ac9f9

Best regards,
--  
Mattia Meleleo <mattia.meleleo@coralogix.com>

