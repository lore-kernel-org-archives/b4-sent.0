From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:41 +0100
Subject: [PATCH RFC 1/9] sysctl: Add struct ctl_table_tmpl as a distinct
 template type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-1-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1440;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=v6PmrMVI1lqvodBG+IMqrzbyXbDvVWx1Hl4IK0D+2nc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGKO/2REFmXrRGqL8fZBwAqa21X/ylmBF
 ZdZBdkv08eRiokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxiAAoJELqXzVK3
 lkFPnEoL+wcw0+nJhpUcbftz6p0mnR8zBhZSfpXQu1SxDQBSaU5bV4mo7EXSfNbWD7HGNyS8WoG
 fHLImOARrNYoDr6zS1fgadhLfKoH5vQlmu0l3TweZLiLU6h1/lrPitRxLLkT1Nz70Oz0vb9P4C1
 Y8yviFC57jOIzbPHzgnHcmHKy4SGzY613y5wcnJCllNNt5eiAZ1bSDTXHxiYgDAcFakOV9ZkMPb
 IzyvzJnQhRiySvmarVtY3eWQqFK71IacIgVdBj8gOba/LurjuEFzlmP9fTC1L3w9FAC7bAZ2zZY
 ipAus0EpjUeVmUN29eyrjSo3jtzrIiNKr5L3ptiaOnORJJXyLPdNId2bCnPu56GCP2Eu2etu0Fe
 Gm1w66cfl5MDLrRYFh1G0fiWqbBhzrMtqg3X5XWCMUjPnTUEjvlvAU0Dw56ANqnLNOFFIDnIuIb
 ZBWPntRxqeNE4HgXaRcwGJ+CxR0/ByuWoVYH2IC/MBEnJa4q1HLVT3Sp45Yv1Vk+2TybiK9Up95
 /A=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a new ctl_table template type identical to ctl_table for when
the table caries several different versions/values of the same path
(think namespaces).

This is a prep commit introducing the struct, no functional change
expected. Sysctl core expects these two to be identical except for the
name; ensure this with a build assert.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index e5d7226ab6f5af34a33829883ad5d1b405e19c86..4faa3bc189e7afbc270f4ba14b04b32a3f2d1413 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -22,6 +22,7 @@
 #ifndef _LINUX_SYSCTL_H
 #define _LINUX_SYSCTL_H
 
+#include <linux/build_bug.h>
 #include <linux/list.h>
 #include <linux/rcupdate.h>
 #include <linux/wait.h>
@@ -230,6 +231,15 @@ struct ctl_table {
 	void *extra2;
 } __randomize_layout;
 
+/* Template version of struct ctl_table. Used for registering ctl_table templates */
+struct ctl_table_tmpl {
+	struct ctl_table t;
+};
+
+static_assert(sizeof(struct ctl_table_tmpl) == sizeof(struct ctl_table));
+static_assert(__alignof__(struct ctl_table_tmpl) == __alignof__(struct ctl_table));
+static_assert(offsetof(struct ctl_table_tmpl, t) == 0);
+
 struct ctl_node {
 	struct rb_node node;
 	struct ctl_table_header *header;

-- 
2.50.1

