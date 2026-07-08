From: Mattia Meleleo <mattia.meleleo@coralogix.com>
Subject: [PATCH bpf v2 0/2] bpf, sockmap: Fix FIONREAD for sockets without
 a verdict program
Date: Wed, 08 Jul 2026 15:40:55 +0200
Message-Id: <20260708-fionread-no-verdict-v2-0-29dd293621c7@coralogix.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NwQ6CMBBEf4Xs2RqoSK0n/8NwKMsW1iglLTYYw
 r9b8O7xTd7MLBDIMwW4Zgt4ihzYDQnkIQPszdCR4DYxyFxWucqVsEnwZFoxOBHJt4yTMKW9VFo
 Z1FZDao6eLM/76h2a0UL9C8O7eRBO296m9Rwm5z/7dyx2+e9NLEQhkHRplDydFeENnTdP1/F8R
 PeCel3XL83dMgDRAAAA
X-Change-ID: 20260707-fionread-no-verdict-a4f8697ac9f9
To: bpf@vger.kernel.org
Cc: netdev@vger.kernel.org, John Fastabend <john.fastabend@gmail.com>, 
 Jakub Sitnicki <jakub@cloudflare.com>, 
 Jiayuan Chen <jiayuan.chen@linux.dev>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Mattia Meleleo <mattia.meleleo@coralogix.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783518119; l=1123;
 i=mattia.meleleo@coralogix.com; s=20260707; h=from:subject:message-id;
 bh=766ztwFBIetWgxKoZZgeUKJCGrbo58G2Y/FPIvlaf+s=;
 b=c3Ik8Gu7yKFePrD+Vyi7Z+EJBxqPu6omkq95Cp/7RvNogFSQ5dAN95OUuetKY0TVtRVbewzYh
 qcaj/FQApKVBQBD31jI0Ze8WXaG8ER1TBCDAuXmN/Ivqg1GD5E8WSHf
X-Developer-Key: i=mattia.meleleo@coralogix.com; a=ed25519;
 pk=cs1zLoe3YDm4bJ7bfbPaZH0lHnd871JyJLiSh2eEzLs=
X-Endpoint-Received: by B4 Relay for mattia.meleleo@coralogix.com/20260707 with auth_id=857
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sockets added to a sockmap/sockhash with no stream/skb verdict program
attached answer FIONREAD with 0 even when unread data is pending in
sk_receive_queue. Fix tcp_bpf_ioctl() to account for the receive queue
in that case, and add a selftest.

Changes in v2:
- Split the fix and the selftest into separate patches
- Use READ_ONCE() to read the verdict program pointers
- Link to v1: https://patch.msgid.link/20260707-fionread-no-verdict-v1-1-ce94a72357ec@coralogix.com

Signed-off-by: Mattia Meleleo <mattia.meleleo@coralogix.com>
---
Mattia Meleleo (2):
      bpf, sockmap: Account for receive queue in FIONREAD without a verdict program
      selftests/bpf: Test FIONREAD on a sockmap socket without a verdict program

 net/ipv4/tcp_bpf.c                                 | 17 +++++++++-
 .../selftests/bpf/prog_tests/sockmap_basic.c       | 39 ++++++++++++++++++++++
 2 files changed, 55 insertions(+), 1 deletion(-)
---
base-commit: d2c9a99135da931377240942d44f3dea104cedb8
change-id: 20260707-fionread-no-verdict-a4f8697ac9f9

Best regards,
--  
Mattia Meleleo <mattia.meleleo@coralogix.com>

