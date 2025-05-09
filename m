From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:15 +0200
Subject: [PATCH 11/12] sysctl: Remove (very) old file changelog
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-11-d0ad83f5f4c3@kernel.org>
References: <20250509-jag-mv_ctltables_iter2-v1-0-d0ad83f5f4c3@kernel.org>
In-Reply-To: <20250509-jag-mv_ctltables_iter2-v1-0-d0ad83f5f4c3@kernel.org>
To: Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Sami Tolvanen <samitolvanen@google.com>, 
 Daniel Gomez <da.gomez@samsung.com>, Kees Cook <kees@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Waiman Long <longman@redhat.com>, "Paul E. McKenney" <paulmck@kernel.org>, 
 Frederic Weisbecker <frederic@kernel.org>, 
 Neeraj Upadhyay <neeraj.upadhyay@kernel.org>, 
 Joel Fernandes <joel@joelfernandes.org>, 
 Josh Triplett <josh@joshtriplett.org>, Uladzislau Rezki <urezki@gmail.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Zqiang <qiang.zhang1211@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Helge Deller <deller@gmx.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, rcu@vger.kernel.org, linux-mm@kvack.org, 
 linux-parisc@vger.kernel.org, linux-serial@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1555;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=l7y3Jbe+VuDhW87xA14zc8M32/viN+V++/E2JThvO9k=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yYzKzJgtt4ntTpokN6y9XDIsXdhgoqX5
 F7WhF8VlYCeSokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfsmAAoJELqXzVK3
 lkFPjG0L/j8GaLr9ywOQsgvVv5Xw8VoMDZucw17xsIkwa74dooJuP9ZQVCakXlhPXB01I+E+zf3
 aIMBrvOgTKo6Dznr0CNidgX9rcGPeCqQBm1WNeCzPzuu9OPwSblcK0EQW8d9pyF/wLryQK6Wkbc
 bo4TxGSyK/8Lwd1hn5SX/2Yd93Z2kSvP0lQluV52q/pRUnSgG0qtOaJYx0qb9HBOfZu/2vTWNsj
 UfCTtfKFJKGdCFF7oQcdtsjFEiicRoKDPxr+k9x4VqGfZvNaIv696bu4gAxC/LerRqjeZXPjbcA
 8qM7Sp7gkRABoxRqT/BSQdTCkGqtagv64NcHDdMunCXa+XrVm7rWspSwzwZQpTcqKyDZT6ndewr
 58cU4skHP3FxIGDvB499kFVSiZmYHjvngFgvBYrDepXsWdrZqlpnfwE2LERTqNIT+KB5WMkWudT
 txlECQUXV5CRvQmWSPFxr1Vc5bvZrHm4hsOvJn3EPCdOCSNEV7maDS/tVypyYKkJE2TQQKIh907
 EE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These comments are older than 2003 and therefore do not bare any
relevance on the current state of the sysctl.c file. Remove them as they
confuse more than clarify.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 16 ----------------
 1 file changed, 16 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 446d77ec44f57a4929389b64fc23d3b180f550b4..dee9a818a9bbc8b1ecd17b8ac1ae533ce15c2029 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1,22 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
  * sysctl.c: General linux system control interface
- *
- * Begun 24 March 1995, Stephen Tweedie
- * Added /proc support, Dec 1995
- * Added bdflush entry and intvec min/max checking, 2/23/96, Tom Dyas.
- * Added hooks for /proc/sys/net (minor, minor patch), 96/4/1, Mike Shaver.
- * Added kernel/java-{interpreter,appletviewer}, 96/5/10, Mike Shaver.
- * Dynamic registration fixes, Stephen Tweedie.
- * Added kswapd-interval, ctrl-alt-del, printk stuff, 1/8/97, Chris Horn.
- * Made sysctl support optional via CONFIG_SYSCTL, 1/10/97, Chris
- *  Horn.
- * Added proc_doulongvec_ms_jiffies_minmax, 09/08/99, Carlos H. Bauer.
- * Added proc_doulongvec_minmax, 09/08/99, Carlos H. Bauer.
- * Changed linked lists to use list.h instead of lists.h, 02/24/00, Bill
- *  Wendling.
- * The list_for_each() macro wasn't appropriate for the sysctl loop.
- *  Removed it and replaced it with older style, 03/23/00, Bill Wendling
  */
 
 #include <linux/sysctl.h>

-- 
2.47.2

