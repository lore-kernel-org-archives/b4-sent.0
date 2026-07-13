From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC net-next v3 0/3] net: sysctl: Const Qualify sysctl
 ctl_table arrays
Date: Mon, 13 Jul 2026 13:07:41 +0200
Message-Id: <20260713-jag-net_const_qualify-v3-0-7289fe9eaea6@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP3GVGoC/4XNTQrCMBAF4KuUrI0k6U8aV4LgAdyKlJhO22hJN
 amhpfTuhmzEhbh8vHnfLMiB1eDQLlmQBa+dHkwI6SZBqpOmBazrkBEjrCAFE/gmW2xgrNRg3Fg
 9X7LXzYybDIjguail4ihsHxYaPUX3jE7HQxImYTaN6BLaTrtxsHN86mm8+eN7iikGEOW1bFRGi
 NrfwRrot4NtI+nZh+GE/2JYYHKZq5yRlIKsv5h1Xd+Zy2E/EAEAAA==
X-Change-ID: 20260629-jag-net_const_qualify-f4e09759dac7
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, 
 Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, 
 Steffen Klassert <steffen.klassert@secunet.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>, 
 Stefano Garzarella <sgarzare@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netfilter-devel@vger.kernel.org, coreteam@netfilter.org, 
 linux-sctp@vger.kernel.org, linux-rdma@vger.kernel.org, 
 linux-s390@vger.kernel.org, virtualization@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5605;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=MrkgFPG1ntcH+3vyM2VZISxYsAEsUAoFtiNSkdalbm0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpUxwUBiWb2tjiICva7RN2tpfHxbzpTwM4W4
 UKZB5EucD3XFYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqVMcFAAoJELqXzVK3
 lkFP5JkL/A+MxgPlU8yaJs7ia4XTGTtosOYbPEVXCyU2Ww6Yryzb543+2zIx9es3Lj6g+vwlXGt
 4RW+l+3qgNlP3sKUdTtrMIEP7KPGw7wHYWni1KS950x7yZ51Z6eds3XURdREMBlaCFQ+NBoIPDE
 1fybWLptzExNy/M6hD0liBh670cgcog69+S1j9g7W8XIzSotouZptJN3LORiSj/AFYfmt5NQUcs
 mQlcPO1fh0m2RuKH5gTQdODb03kF7EFBGX7XPsE3rQw9TuZqKa3g5XXbTh0sjiWD6bZEyOfhbH9
 tTGrblWYx9+yXhJ4UcG/7JY25reBxA6QlDa43knUvWjH+R5vH11DM3WgpZf3JAhe13lrgnSakB0
 BIYZCLsMRcYktQMYq4L8dJ+0jpQyknMjtQ+NGCHcKnljrkixGLjc0310sCb0d6qQ0VPRUCk8bqQ
 zhuv7wNfOgjar4Ati0FS+ts24gK2sW/GUllcj+pm1SMp5RXCdoYGwp0W49W9o6pbqIDitcVIZX4
 w4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

What?
=====
We do two things:
1. Reject netns-unsafe: Replace warning and file permission change with
   an error (reject registration) when an "unsafe" net sysctl
   registration is detected.
2. Const qualify: Const qualify network templated ctl_table arrays and
   unconditional kmemdup'ed ctl_table arrays.

Why?
====
The main motivation for this is to continue with the const qualification
of the ctl_table arrays [1]. The permission change inside
ensure_safe_net_sysctl disallows cons qualifiaction as it basically
modifies the entries before running the sysctl registration.

      ent->mode &= ~0222;

On reject netns-unsafe?
=======================
* I believe that there is currently now way that the permission change
  gets executed [2]
* I found one case where the warning message was posted to lore
  (vsock_sysctl_register) [3], but it made its to mainline as part of
  the second case in [2].
* We should error anyway because writing to the global sysctl value
  through a child netns is indicative of a bug [4].

On Const qualification?
=======================
We can separate the places where network registers sysctl tables into
three groups:
1. Static global: The unchanged global static arrays are passed along to
   sysctl register.
2. Always kmemdup: The global static arrays are always kmemdup'ed before
   passing them along to sysctl register.
3. Dynamic global: The global static array is changed in place before
   passing it along to sysctl register.

This series handles case 1 and 2. It leaves 3 for a later point as
const qualifying those global ctl_tables is more involved.

RFC
===
Keeping the RFC tag for now in hope of any preliminary feedback. I would
be very thankful if you point me to anything that I have missed in my
analysis that shows that this cannot/shouldn't be done.

Changes in v3:
- Const qualified 2 of the 3 cases within the net directory ctl_table
  register sites.
- Link to v2: https://lore.kernel.org/r/20260707-jag-net_const_qualify-v2-1-5a5c52031ead@kernel.org

Changes in v2:
- Rebased on top of net-next
- Updated subject to "RFC net-next"
- Link to v1: https://lore.kernel.org/r/20260629-jag-net_const_qualify-v1-1-ee98b8fc400c@kernel.org

Best

[1]
  https://git.kernel.org/pub/scm/linux/kernel/git/sysctl/sysctl.git/commit/?h=constfy-sysctl-6.14-rc1&id=1751f872cc97f992ed5c4c72c55588db1f0021e1

[2]
  I have identified 4 contexts relevant to the ensure_safe_net_sysctl call
  inside the network sysctl registration.

  1. When the (struct net) == &init_net (like in iw_cm_init): In this case
     ensure_safe_net_sysctl is not executed and permission modification
     never happens.

  2. When the ctl_table data (->data) gets "manually" assigned to
     something other init_net (like in vsock_sysctl_register): In this
     case ensure_safe_net_sysctl *is* executed but the data that is passed
     is neither a module address (!is_module_address) nor a kernel core
     address (!is_kernel_core_data); so the permission modification never
     happens.

  3. When the permissions are explicitly changed on a kmemdup'ed ctl_table
     array (like in sysctl_core_net_init): in this case
     ensure_safe_net_sysctl *is* executed but the permission modification
     never happens as the mode is not writable.

  4. When ctl have custom proc_handlers (like in nf_lwtunnel_net_init): In
     this case ->data is NULL so it is not a module address
     (!is_module_address) nor a kernel core address
     (!is_kernel_core_data), so permission modification never happens.

  It seems like there is no way of executing the permission change in
  ensure_safe_net_sysctl. Please correct me if this is inaccurate and help
  me find the case that I missed.

[3]
  https://lore.kernel.org/all/20260302194926.90378-1-graf@amazon.com/

[4]
  The ensure_safe_net_sysctl function was introduced in Commit:
  31c4d2f160eb7b17cbead24dc6efed06505a3fee ("net: Ensure net namespace
  isolation of sysctls") which states that it is trying to prevent a
  leak (indicative of a bug).

---
Signed-off-by: Joel Granados <joel.granados@kernel.org>

---
Joel Granados (3):
      net: enforce net sysctl registration
      net: Const qualify ctl_tables that kmemdup unconditionally
      net: Const qualify network templated ctl_tables Arrays

 include/net/net_namespace.h             |  4 +--
 net/core/sysctl_net_core.c              | 38 +++++++++++++++--------
 net/ipv4/devinet.c                      |  2 +-
 net/ipv4/sysctl_net_ipv4.c              | 54 +++++++++++++++++++--------------
 net/ipv4/xfrm4_policy.c                 | 22 +++++++++++---
 net/ipv6/icmp.c                         |  2 +-
 net/ipv6/route.c                        |  2 +-
 net/ipv6/sysctl_net_ipv6.c              |  2 +-
 net/ipv6/xfrm6_policy.c                 | 22 +++++++++++---
 net/netfilter/nf_conntrack_standalone.c |  2 +-
 net/netfilter/nf_hooks_lwtunnel.c       |  4 +--
 net/sctp/sysctl.c                       |  2 +-
 net/smc/smc_sysctl.c                    | 26 +++++++++++-----
 net/sysctl_net.c                        | 24 +++++++--------
 net/unix/sysctl_net_unix.c              | 21 ++++++++++---
 net/vmw_vsock/af_vsock.c                | 25 ++++++++++-----
 net/xfrm/xfrm_sysctl.c                  |  2 +-
 17 files changed, 167 insertions(+), 87 deletions(-)
---
base-commit: 474cff6868129755cf889edf40d7f491729fc588
change-id: 20260629-jag-net_const_qualify-f4e09759dac7

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

