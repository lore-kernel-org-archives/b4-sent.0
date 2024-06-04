From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:26 +0200
Subject: [PATCH 8/8] sysctl: Warn on an empty procname element
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-8-2df7ecdba0bd@samsung.com>
References: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
In-Reply-To: <20240604-jag-sysctl_remset-v1-0-2df7ecdba0bd@samsung.com>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Waiman Long <longman@redhat.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Suren Baghdasaryan <surenb@google.com>, 
 Kent Overstreet <kent.overstreet@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Joel Granados <j.granados@samsung.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-fsdevel@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=837; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=kiBCYRLAjKste0XuHE2np63NWadPBoIGUUndp1NrN98=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGXOjyV9+/Ko/a1TAa0g3yQtd6zwj6D29
 kW6R7OTXh/JPokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRlAAoJELqXzVK3
 lkFPABkL/0chps6Tybj/Jceo6dk5TxaNFxxf/9U5ng/iiwgx4Aud25nQYC/AmsWbL/his/ClEv4
 8BuIUh8G4fFijVL56/El1GEAVxd9J8z8s6c3d83lZ+7po/aWsz9lvgO6nh3tTe8U6TKKV+Rh0jL
 EKXjAJ+S4/CNLT4NBhCuIY4P4LyQIjgAxHx3p/ryNWc08tJJAK0bG+L3cllECbQ7X+usHu9Q9dq
 mg5tVGmxkunsrP/nLQNrlC+xpppGWp+fc5g9y/QeTAXHVHQMCZkeV5pJfgBWVGMUv9F7juRGJAB
 B5ySh3sHHaIo8scZIIYsRqWs1/4dR8vxgpa8iXykL41Px3oJuinO01eFG2gdAht/skleaLIIW5y
 k36ZfB4mYUmXBtSq/YEGDd4IerIixbbq7Hc5F+g+l7Eby59/gbzU06uOy3mGyuXFVzB0WHcZFiz
 +zN9loEzcIEe/WaIq9hQLiHtkj3fwCmwXLuAOl6RzQgKnNf/jXmyJJL30Dsd9/INhxAp1Tc7SA6
 74=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a pr_err warning in case a ctl_table is registered with a sentinel
element containing a NULL procname.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 fs/proc/proc_sysctl.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 806700b70dea..f65098de5fcb 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1119,6 +1119,8 @@ static int sysctl_check_table(const char *path, struct ctl_table_header *header)
 	struct ctl_table *entry;
 	int err = 0;
 	list_for_each_table_entry(entry, header) {
+		if (!entry->procname)
+			err |= sysctl_err(path, entry, "procname is null");
 		if ((entry->proc_handler == proc_dostring) ||
 		    (entry->proc_handler == proc_dobool) ||
 		    (entry->proc_handler == proc_dointvec) ||

-- 
2.43.0

