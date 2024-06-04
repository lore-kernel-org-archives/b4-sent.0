From: Joel Granados <j.granados@samsung.com>
Date: Tue, 04 Jun 2024 08:29:20 +0200
Subject: [PATCH 2/8] mm profiling: Remove superfluous sentinel element from
 ctl_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240604-jag-sysctl_remset-v1-2-2df7ecdba0bd@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=862; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=grXyma2z6K/wRopvypgEfIMP+PFHWBDb7VqNp82ood4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGZetGLtay8GHHZfoulwDT7Cp/+NFmjaUVFeN
 K1kk9wfksxNuIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmXrRiAAoJELqXzVK3
 lkFPLVQL/RZBp0EyIV+vm0gXQg6+z7wQ3w++rqI1ydJNjnUfIkWxiBXMoWjegWKgorptI5L0LL5
 QiBGzg09KK78sYzgGlTjTudseX5pEj0wPgl5NA41VUKS3+eKByodee1SAT7w/5KgDAtjOwJiCmx
 hsXoF/SogQ0PJnNF+lZgwNnSukeE3eotjMuL0fhv7BGE9TwpcF7pOGrqB8AmLn91nFXyVOWjtBj
 Y/BhWU1/R5n57AbIDkaR04pcY907qAipnMbKVrminTdDhcjrYBuoX2O3K/WsV5UGPLWxg7Pwr2+
 DKSCcd3f7cgKGvrqvuO0E1bsr+dsJj2zRAGJsSJtpfUhQ5A/KnmBUxbFb6W6IGbQVIfeAia9jys
 u3mALmKeyGRvnUkSMmH+z8yrhDmtI4Hn4lQUh9MofiwVN8fBR64dUuoxfVJhH2vHrg9PEnToAUN
 6djR12wRe1b3eoxy8lGrrPi6EMi8z7R+qmxIqSo83Up6qfK7p2AMUDkiSJY6aoyusP77KXPACI5
 0I=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit is part of a greater effort to remove all empty elements at
the end of the ctl_table arrays (sentinels) which will reduce the
overall build time size of the kernel and run time memory bloat by ~64
bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Removed sentinel from memory_allocation_profiling_sysctls

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 lib/alloc_tag.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/lib/alloc_tag.c b/lib/alloc_tag.c
index 11ed973ac359..7293cd54d1b1 100644
--- a/lib/alloc_tag.c
+++ b/lib/alloc_tag.c
@@ -238,7 +238,6 @@ static struct ctl_table memory_allocation_profiling_sysctls[] = {
 #endif
 		.proc_handler	= proc_do_static_key,
 	},
-	{ }
 };
 
 static int __init alloc_tag_init(void)

-- 
2.43.0

