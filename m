From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net-next v4 0/6] net/tcp: TCP-AO and TCP-MD5 tracepoints
Date: Fri, 07 Jun 2024 00:25:54 +0100
Message-Id: <20240607-tcp_ao-tracepoints-v4-0-88dc245c1f39@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAINFYmYC/23OQWrDMBAF0KsEratWM7Idu6vco5QylkexoJGMJ
 ERK8N0rG0rakuUw/Pf/TSSOjpN4PdxE5OKSC74ezdNBmJn8maWb6i1QYaNaDTKb5YOCzJEML8H
 5nKQlZGgYrJomUYNLZOuuO/omPGfp+ZrFe/2MlFiOkbyZN/Tn93Ih57fk7FIO8WtfU2DP78WIz
 VYs/xUXkEpCazWMR6sVHU8Uq0DPJlz2voJ3o1Pto/EFq8EDMHSAPbI9neuazzuhfxPdQ0JvM3S
 HMPS9UcMfYl3Xb1NMPTRlAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717716372; l=2059;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=llottDhQKaURlXE/wW1YxOb8Cyb6//i4SbVQqw7++1g=;
 b=+Z3xNAjQb4voEBX4c6KwxL7PqDNBav+hy3mtePPR/DpLG4FW629l6x10sW8ZwP7VLFGCDpVoHUpE
 Kc4YOLubCW5wcsAOYEzrV3PFrNP5Z/DrYNeGMAOd0G+PeBIpnPJV
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Changes in v4:
- Fix the build for CONFIG_TCP_MD5SIG=n (Matthieu Baerts, netdev dashboard)
- Link to v3: https://lore.kernel.org/r/20240606-tcp_ao-tracepoints-v3-0-13621988c09f@gmail.com

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
 net/ipv4/tcp.c                      |  98 +++++++++--
 net/ipv4/tcp_ao.c                   |  24 +--
 net/ipv4/tcp_input.c                |   8 +-
 net/ipv4/tcp_ipv4.c                 |   8 +-
 net/ipv4/tcp_output.c               |   2 +
 9 files changed, 443 insertions(+), 157 deletions(-)
---
base-commit: 62b5bf58b928f0f4fcc8bb633b63795517825d31
change-id: 20240531-tcp_ao-tracepoints-fa2e14e1f0dd

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

