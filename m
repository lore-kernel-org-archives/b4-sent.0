From: Felipe Pereira Stival <v0idpwn@gmail.com>
Subject: [PATCH net 0/2] tls: don't hide a queued KeyUpdate from poll()
Date: Wed, 18 Nov 2026 17:35:47 -0300
Message-Id: <20261118-v0idpwn-tls-poll-parked-keyupdate-v1-0-8e25101e7be6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQ7CIBQFr9L8tT8pLGr1KsYFhVf9llACtGqa3
 l3U5cxiZqOMJMh0bjZKWCXLHCqoQ0P2bsINLK4y6VZ3Sqme11ZcfAYuPnOcvedo0gTHE95LdKa
 AtTqe9NDbEZ2j2okJo7x+jwsFFLr+ZV6GB2z51mnfPzRA006KAAAA
X-Change-ID: 20261118-v0idpwn-tls-poll-parked-keyupdate-21792b8cfe6d
To: John Fastabend <john.fastabend@gmail.com>, 
 Jakub Kicinski <kuba@kernel.org>, Sabrina Dubroca <sd@queasysnail.net>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Felipe Pereira Stival <v0idpwn@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795034159; l=1813;
 i=v0idpwn@gmail.com; s=20261118; h=from:subject:message-id;
 bh=DIS1qpGeSGsJAZlzQeuErG2MWJN2BgtKvOVfJIEtLu4=;
 b=oamRd5Y6T31xLNPKrToNJ8oIMDJqzpC85j6F6RcOJIa758qXllk7jhlCBwJ1yjMpdArZTga56
 gd5sFCzdTuVBR3/E6WVpdX6/dE8AH0cj8Qrj6zspgATfD7V/ToXYRQU
X-Developer-Key: i=v0idpwn@gmail.com; a=ed25519;
 pk=dy+Py1JexopmEarZT58aUO9PMt7zs+cB62CS+N7NWTw=
X-Endpoint-Received: by B4 Relay for v0idpwn@gmail.com/20261118 with auth_id=1562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A kTLS reader that waits for a read event before each recv() can stall
after the peer sends a TLS 1.3 KeyUpdate. I ran into this while testing
a kTLS patch for Erlang/OTP.

Erlang does one recv() per read event, with level-triggered epoll.
When application data is followed by a KeyUpdate, one recv() can
decrypt both records, return the data without an error, and leave the
KeyUpdate queued. Because a rekey is now pending, poll() no longer
reports the socket as readable. Without another read event, the reader
never calls recv() again, never sees the -EIO for the KeyUpdate, and
never provides the new key.

Patch 1 keeps the socket readable until the reader has consumed the
KeyUpdate. As before, poll() doesn't report records after the
KeyUpdate until userspace provides the new key. Patch 2 adds a
selftest, which fails without patch 1.

I worked on this with an AI coding assistant (Claude). It wrote the
first drafts of the code and the commit messages, and I reviewed and
reworked them. I directed the whole process, from tracing the missing
read event to tls_sk_poll() to checking how other kinds of readers
are affected and testing in QEMU/KVM.

Signed-off-by: Felipe Pereira Stival <v0idpwn@gmail.com>
---
Felipe Pereira Stival (2):
      tls: don't hide a queued KeyUpdate from poll()
      selftests: tls: add a poll test for a queued KeyUpdate

 Documentation/networking/tls.rst  |  7 ++++---
 net/tls/tls_main.c                |  6 +++---
 tools/testing/selftests/net/tls.c | 40 +++++++++++++++++++++++++++++++++++++++
 3 files changed, 47 insertions(+), 6 deletions(-)
---
base-commit: 2a324a58a084c5cfd7e5a2f55e0786bee170a4a5
change-id: 20261118-v0idpwn-tls-poll-parked-keyupdate-21792b8cfe6d

Best regards,
--  
Felipe Pereira Stival <v0idpwn@gmail.com>

