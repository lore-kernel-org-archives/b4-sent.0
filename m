From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC 0/9] sysctl: Replace ARRAY kmemdup with overlay
 mechanism for NS registration
Date: Thu, 26 Nov 2026 12:47:40 +0100
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFwcCGsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNj3ZzsnFzd4sri5JIc3eSSCt20nMSSxKKixErdZJMkk9REQwPDFEt
 jJaD+gqLUtMwKsNnRSkFuzkqxtbUAwslstXAAAAA=
X-Change-ID: 20261123-lklm-sysctl-ctx-flatarray-c4b4ea101d93
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4810;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=mlvLsVvr0QRLxxbIuMbsgLJ4Mle2Giu4L61BJM4CqCA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGEmaQha3UXAh2NNj5bfqquUZkpFgUQba
 m83hmkTRWoB4YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxhAAoJELqXzVK3
 lkFPz+QL/2ckQwSLe5QM0rIhD7IFmw6aOc37PQNbPQmez2tzYXRNARNFp9vxXTTNdXIyt8g1WE9
 tG4OhSp950k5JK4twRXeqYAv/MoIaA+y52ERpyAWf6s8m2UlcI6Go2pVfWYEQ35aZ4eubYMubyI
 itYXaN/PipqIS5pAGznYaNt3lOJjm4U52rM32yCgjAUYjkk/YCphjMebs67LfzXUYLipTemPHDL
 t2xKF6WvqrXjadp39tIIdPYr5wyEc1UBZAPjbFVic9nKyfNsaZZd/yvbvtGmVDkT/oTM94q+9b9
 LUc/UU/iA4FA7YD9ZnUvfH8WcmFz3A2Gqn5mk7DVZoWb+hYI5g5SKdZKxvehlkp3U1BavI2Gs5w
 vsJ/h4pZ36kYZaRmXX6GfEmPzwLavSYWoH1eYr3BzKEXfaEButg5LqjBPFlaQftCh6COikKR4M2
 nIb0K5NaHPvhl2rKfjjAl787HjNtEgCMuWvs3wKORuCQDY0ZOgsP1mKcMDZ1q3dWTqCJ4W4HXS5
 /Q=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is meant to replace the sysctl array duplication mechanism used by
callers that register sysctls for individual namespaces.

Instead of duplicating a sysctl array and keeping it in memory for the
life of a namespace, use it (the array) as a template and keep only the
necessary delta in a sysctl_context struct inside ctl_table_header. The
sysctl_context can then be used to overlay the ctl_table just before
calling its proc_handler.

The last 5 commits are just examples of how the conversions at the call
sites would look. The idea is to upstream the core first and then merge
each individual calling site through its own subsystem tree.

Motivation
==========

* Reducing memory footprint for namespace registrations
  On a 64 bit ARCH, memory consumption is reduced by at least 53% (this
  is a back-of-envelope approximation): from (56 * ARRAY_SIZE *
  count(namespaces)) bytes to (26 * ARRAY_SIZE * count(namespaces))
  bytes [2]; we save more, if a subset of the context is used.

* ctl_table const qualification
  Namespace ctl_table arrays that are currently modified during
  registration can be const qualified (moved to .rodata) as they no
  longer require pre-registration changes.

What was done
=============

* struct sysctl_context:
  Embedded in struct ctl_table_header, holds flat arrays indexed by
  entry position: void **data, **extra1, **extra2; umode_t
  *mode. They point to what should be overlaid.

* overlay flags:
  struct ctl_table gets a u8 flags member in an existing hole (no size
  change) with SYSCTL_OVERLAY_{DATA,EXTRA1,EXTRA2,MODE}. They control
  what gets overlaid

* sysctl template overlay:
  Add a template registration function to initialize the sysctl
  context. Overlay data from context before calling any proc_handler.
  Template registration can only be done with a ctl_table_tmpl type.

Comment on void*
================
The sysctl_context uses 3 void** because it reflects struct ctl_table.
Yes, we should get rid of these untyped pointers. No, this is not the
series that will remove them. Yes, there are already proposals out there
that are working towards this [1]. Yes, the plan is for sysctl_context's
void pointers to change once struct ctl_table's do. I thought that
resolving the pointers had to go first, but I think these two efforts
can coexist if handled separately.

Recent approaches
=================
* Alexey Gladkov's "sysctl_field" descriptors:
  cover.1787770053.git.legion@kernel.org, cover.1790439358.git.legion@kernel.org
  Which build a temp ctl_table from typed accessors before calling the
  proc_handler

* My own header-context RFC:
  20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org
  computed .data as base + delta in the core.

This series takes the idea of building a temp ctl_table entry before
calling proc_handler, which is a commonality in these two, and drops
everything else: no network types in sysctl core, no namespace specific
enum in sysctl core, no delta arithmetic.

To and Cc
=========
I always find it challenging to know who wants to receive these e-mails.
I added you here because you have recently commented on the issue or
are in the maintainer path. Let me know if you don't want to be included
in the future.

Any comments are greatly appreciated

Best

Based on v7.4-rc2

[1] https://lore.kernel.org/all/cover.1794844686.git.wen.yang@linux.dev
    https://lore.kernel.org/all/cover.1793204511.git.wen.yang@linux.dev
[2] sizeof(struct ctl_table) -> 56 bytes
    3*sizeof(void*) + sizeof(umode_t) -> 26 bytes

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (9):
      sysctl: Add struct ctl_table_tmpl as a distinct template type
      sysctl: Add flags to struct ctl_table
      sysctl: Add overlay mechanism for flagged ctl_table members
      sysctl: Add sysctl template registration
      net: sysctl: Add sysctl registration to networking
      ipv4: Register ipv4_net_table as a template
      ipc: Register ipc_sysctls as a template
      ipc: Register mq_sysctls as a template
      ucount: Register user_table as a template

 fs/proc/proc_sysctl.c       | 362 ++++++++++++++++++++++++++++++++++++++------
 include/linux/sysctl.h      |  66 ++++++++
 include/net/net_namespace.h |  14 ++
 ipc/ipc_sysctl.c            |  24 ++-
 ipc/mq_sysctl.c             |  20 +--
 kernel/ucount.c             |  14 +-
 net/ipv4/sysctl_net_ipv4.c  | 163 +++++++++++++++++---
 net/sysctl_net.c            |  25 +++
 8 files changed, 594 insertions(+), 94 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261123-lklm-sysctl-ctx-flatarray-c4b4ea101d93

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

