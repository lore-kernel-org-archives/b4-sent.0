From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net-next v3 0/6] net/tcp: TCP-AO and TCP-MD5 tracepoints
Date: Thu, 06 Jun 2024 01:58:17 +0100
Message-Id: <20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKoJYWYC/22OwWrDMBBEfyXo3G21aztpesp/lFDW8ioWNJKRh
 EgI/vfKKqVQehyGeW8eKkl0ktTb7qGiFJdc8DV0TztlZvYXATfVrEhTr4cOIZvlgwPkyEaW4Hx
 OYJkEe0Grp0nV4RLFuluDvisvGbzcsjrXZuQkMEb2Zt6gP93LlZ3flrNLOcR7e1Ow7ZuYqN/E8
 EdcEDTgYDscD7bTfDhxrAR+NuHafIV+GXs9/He+UGXIEQX3SK8k9nSpbz6/Eeu6fgFqpbuNIgE
 AAA==
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, David Ahern <dsahern@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: Mohammad Nassiri <mnassiri@ciena.com>, Simon Horman <horms@kernel.org>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717635508; l=1866;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=bcGRgEvEo62X/MLxlgNLFRIy+S5DmEwSGkybq/yerHo=;
 b=sz9JlhZh10+BL8KGtQIEgSt9PbtbS3WiNVSbOjSb0K4eFnKvKIDkNpd74mFdySFe3vyCOqcsQE6w
 9htUSe5dCXdRKDh7tAmTS5t9vdh0K0mOARs2FqUy7YdGMr0bF8Mp
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Changes in v3:
- Unexported tcp_inbound_ao_hash() and made static (Eric Dumazet)
- Link to v2: https://lore.kernel.org/r/20240605-tcp_ao-tracepoints-v2-0-e91e161282ef@gmail.com

Changes in v2:
- Fix the build with CONFIG_IPV6=m (Eric Dumazet)
- Move unused keyid/rnext/maclen later in the series to the patch
  that uses them (Simon Horman)
- Reworked tcp_ao selftest lib to allow async tracing non-tcp events
  (was working on a stress-test that needs trace_kfree_skb() event,
   not in this series).
- Separated selftest changes from kernel, as they now have a couple
  of unrelated to tracepoints changes
- Wrote a few lines of Documentation/
- Link to v1: https://lore.kernel.org/r/20240224-tcp-ao-tracepoints-v1-0-15f31b7f30a7@arista.com

---
Dmitry Safonov (6):
      net/tcp: Use static_branch_tcp_{md5,ao} to drop ifdefs
      net/tcp: Add a helper tcp_ao_hdr_maclen()
      net/tcp: Move tcp_inbound_hash() from headers
      net/tcp: Add tcp-md5 and tcp-ao tracepoints
      net/tcp: Remove tcp_hash_fail()
      Documentation/tcp-ao: Add a few lines on tracepoints

 Documentation/networking/tcp_ao.rst |   9 +
 include/net/tcp.h                   |  92 +----------
 include/net/tcp_ao.h                |  42 +----
 include/trace/events/tcp.h          | 317 ++++++++++++++++++++++++++++++++++++
 net/ipv4/tcp.c                      |  90 ++++++++--
 net/ipv4/tcp_ao.c                   |  24 +--
 net/ipv4/tcp_input.c                |   8 +-
 net/ipv4/tcp_ipv4.c                 |   8 +-
 net/ipv4/tcp_output.c               |   2 +
 9 files changed, 435 insertions(+), 157 deletions(-)
---
base-commit: d223d1947dadec37d2bb5efbda9fc34c03b9a784
change-id: 20240531-tcp_ao-tracepoints-fa2e14e1f0dd

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

