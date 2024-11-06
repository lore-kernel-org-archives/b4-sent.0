From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net 0/6] Make TCP-MD5-diag slightly less broken
Date: Wed, 06 Nov 2024 18:10:13 +0000
Message-Id: <20241106-tcp-md5-diag-prep-v1-0-d62debf3dded@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAWxK2cC/x2MSQrDMAwAvxJ0rsB2N9qvlB4cS050iGssUwohf
 4/S4wzMrKDchBWewwqNv6LyKQb+NECaY5kYhYwhuHDx3t2wp4oLXZEkTlgbVwzZUcrnu6eHA+t
 MZvn9ny8o3OFtcozKOLZY0nzslqidG2zbDgv5IMqBAAAA
X-Change-ID: 20241106-tcp-md5-diag-prep-2f0dcf371d90
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ivan Delalande <colona@arista.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Boris Pismenny <borisp@nvidia.com>, 
 John Fastabend <john.fastabend@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mptcp@lists.linux.dev, Dmitry Safonov <0x7f454c46@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730918993; l=4298;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=DVwDJD/KkZRG9Ci5yJY5o05rou58w9qxq4QZ3Hjqx9g=;
 b=Q5kvMZzu/5iCWGWYFoCykO42N7Cilo4ui53yOEQLYEJv7xu6ULHvMTUwZFbYnd+grqxebBatf
 xgQC6i5XrsnCZN2KLe4KTqooOmKeaCoknsIy/eDclwlURdI3tb6kx4K
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

My original intent was to replace the last non-upstream Arista's TCP-AO
piece. That is per-netns procfs seqfile which lists AO keys. In my view
an acceptable upstream alternative would be TCP-AO-diag uAPI.

So, I started by looking and reviewing TCP-MD5-diag code. And straight
away I saw a bunch of issues:

1. Similarly to TCP_MD5SIG_EXT, which doesn't check tcpm_flags for
   unknown flags and so being non-extendable setsockopt(), the same
   way tcp_diag_put_md5sig() dumps md5 keys in an array of
   tcp_diag_md5sig, which makes it ABI non-extendable structure
   as userspace can't tolerate any new members in it.

2. Inet-diag allocates netlink message for sockets in
   inet_diag_dump_one_icsk(), which uses a TCP-diag callback
   .idiag_get_aux_size(), that pre-calculates the needed space for
   TCP-diag related information. But as neither socket lock nor
   rcu_readlock() are held between allocation and the actual TCP
   info filling, the TCP-related space requirement may change before
   reaching tcp_diag_put_md5sig(). I.e., the number of TCP-MD5 keys on
   a socket. Thankfully, TCP-MD5-diag won't overwrite the skb, but will
   return EMSGSIZE, triggering WARN_ON() in inet_diag_dump_one_icsk().

3. Inet-diag "do" request* can create skb of any message required size.
   But "dump" request* the skb size, since d35c99ff77ec ("netlink: do
   not enter direct reclaim from netlink_dump()") is limited by
   32 KB. Having in mind that sizeof(struct tcp_diag_md5sig) = 100 bytes, 
   dumps for sockets that have more than 327 keys are going to fail
   (not counting other diag infos, which lower this limit futher).
   That is much lower than the number of TCP-MD5 keys that can be
   allocated on a socket with the current default
   optmem_max limit (128Kb).

So, then I went and written selftests for TCP-MD5-diag and besides
confirming that (2) and (3) are not theoretical issues, I also
discovered another issues, that I didn't notice on code inspection:

4. nlattr::nla_len is __u16, which limits the largest netlink attibute
   by 64Kb or by 655 tcp_diag_md5sig keys in the diag array. What
   happens de-facto is that the netlink attribute gets u16 overflow,
   breaking the userspace parsing - RTA_NEXT(), that should point
   to the next attribute, points into the middle of md5 keys array.

In this patch set issues (2) and (4) are addressed.
(2) by not returning EMSGSIZE when the dump raced with modifying
TCP-MD5 keys on a socket, but mark the dump inconsistent by setting
NLM_F_DUMP_INTR nlmsg flag. Which changes uAPI in situations where
previously kernel did WARN() and errored the dump.
(4) by artificially limiting the maximum attribute size by U16_MAX - 1.

In order to remove the new limit from (4) solution, my plan is to
convert the dump of TCP-MD5 keys from an array to
NL_ATTR_TYPE_NESTED_ARRAY (or alike), which should also address (1).
And for (3), it's needed to teach tcp-diag how-to remember not only
socket on which previous recvmsg() stopped, but potentially TCP-MD5
key as well.

I plan in the next part of patch set address (3), (1) and the new limit
for (4), together with adding new TCP-AO-diag.

* Terminology from Documentation/userspace-api/netlink/intro.rst

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Dmitry Safonov (6):
      net/diag: Do not race on dumping MD5 keys with adding new MD5 keys
      net/diag: Warn only once on EMSGSIZE
      net/diag: Pre-allocate optional info only if requested
      net/diag: Always pre-allocate tcp_ulp info
      net/diag: Limit TCP-MD5-diag array by max attribute length
      net/netlink: Correct the comment on netlink message max cap

 include/linux/inet_diag.h |  3 +-
 include/net/tcp.h         |  1 -
 net/ipv4/inet_diag.c      | 87 ++++++++++++++++++++++++++++++++++++++---------
 net/ipv4/tcp_diag.c       | 69 ++++++++++++++++++-------------------
 net/mptcp/diag.c          | 20 -----------
 net/netlink/af_netlink.c  |  4 +--
 net/tls/tls_main.c        | 17 ---------
 7 files changed, 109 insertions(+), 92 deletions(-)
---
base-commit: 2e1b3cc9d7f790145a80cb705b168f05dab65df2
change-id: 20241106-tcp-md5-diag-prep-2f0dcf371d90

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

